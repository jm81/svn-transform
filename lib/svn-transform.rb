require 'pathname'
require 'svn-fixture'
require 'fileutils'

STDOUT.sync = true

class SvnTransform
  VERSION = '0.1.0'
  PRINT_INFO = false
  
  class << self
    # Use diff to compare two repositories (on local file system)
    # Where reasonable, this (or something like it) should be run to verify 
    # expected results. I recommend trying a direct copy first to ensure your
    # original repo doesn't have any featurs that SvnPropsToYaml won't
    # understand.
    #
    # http://www.coderetard.com/2009/02/17/compare-directories-and-file-content-in-linux-without-dircmp/
    #
    # ==== Gotchas
    # svn:entry fields aren't directly copied, but seem to match.
    # repo uuid is different, but not relevant, so that file is ignored.
    # other differences may also exist if the in_repo is an older format.
    #
    # ==== Parameters
    # old_dir<String>:: FS Path to original (in) repository.
    # new_dir<String>:: FS Path to generated (out) repository.
    #
    # Note that these are filesystem paths, not Subversion URI's
    #
    # ==== Returns
    # True, False::
    #   Whether the directories are the same (except db/uuid file)
    #   If False, puts the result of running the diff command.
    def compare(old_dir, new_dir)
      ret = `diff --brief --exclude=uuid -r "#{old_dir}" "#{new_dir}"`
      if ret.empty?
        return true
      else
        puts ret
        return false
      end
    end
    
    COMPARE_DIR = '/tmp/svn-transform/compare'
    COMPARE_OLD_DIR = File.join(COMPARE_DIR, 'old')
    COMPARE_NEW_DIR = File.join(COMPARE_DIR, 'new')
    
    # Compare checkouts. This takes much longer than .compare but can give a
    # more accurate picture, because it is not affected by the changes in
    # svn:entry properties (well, it actually just ignores the related files),
    # the chance that entries are just in different order within the db file, or
    # differences between the directory structure of the repo's db folders.
    #
    # It also has the advantage that the repositories can be remote.
    #
    # Note that this method will destroy existing files in the COMPARE_DIR
    #
    # ==== Parameters
    # old_repo<String>:: URI of original (in) repository.
    # new_repo<String>:: URI of generated (out) repository.
    # min_rev<Integer>:: Starting revision for comparison
    # max_rev<Integer>:: Ending revision for comparison
    def co_compare(old_repo, new_repo, min_rev, max_rev)
      FileUtils.rm_rf(COMPARE_OLD_DIR)
      FileUtils.rm_rf(COMPARE_NEW_DIR)

      rev = min_rev
      `svn co -r#{rev} "#{old_repo}" "#{COMPARE_OLD_DIR}"`
      `svn co -r#{rev} "#{new_repo}" "#{COMPARE_NEW_DIR}"`
      
      while rev <= max_rev
        co_compare_rev(rev)
        rev += 1
      end
    end
    
    # Called by .co_compare, this checks out and compares the repositories at
    # a signle revision. It prints out any differences.
    #
    # ==== Parameters
    # rev<Integer>:: The revision to compare.
    #
    # ==== Returns
    # True, False:: Whether the revisions are identical
    def co_compare_rev(rev)
      print "#{rev} " if PRINT_INFO
      `svn update -r#{rev} "#{COMPARE_OLD_DIR}"`
      `svn update -r#{rev} "#{COMPARE_NEW_DIR}"`
      ret = `diff --brief --exclude=entries -r "#{COMPARE_OLD_DIR}" "#{COMPARE_NEW_DIR}"`
      if ret.empty?
        return true
      else
        puts "\nREVISION #{rev}"
        puts ret
        puts ("-" * 70)
        return false
      end
    end
  end
  
  # Setup and SvnTransform with in (existing) repository URI, a name for the
  # out (transformed) repository, and options.
  #
  # ==== Parameters
  # in_repo_uri<String>::
  #   URI of existing repository(e.g. file:///home/jm81/repo,
  #   svn://localhost/repo)
  # out_repo_name<String>::
  #   Name only of out repository (e.g. "out"). See options[:out_repos_path]
  #   for specifying full path (on local filesystem only)
  #
  # ==== Options
  # :username<String>:: Username for in (existing) repository
  # :password<String>:: Password for in (existing) repository
  # :out_repos_path<String>::
  #   Full path for out repository (defaults to 
  #   "#{SvnFixture.config[:base_path]}/repo_#{out_repo_name}")
  # :out_wc_path<String>::
  #   Full path for out working copy (used by SvnFixture; defaults to 
  #   "#{SvnFixture.config[:base_path]}/wc_#{out_repo_name}")
  def initialize(in_repo_uri, out_repo_name = nil, options = {})
    @in_username = options[:username]
    @in_password = options[:password]
    @in_repo_uri = in_repo_uri
    @out_repo_name = out_repo_name
    @out_repos_path = options[:out_repos_path]
    @out_wc_path = options[:out_wc_path]
    @file_transforms = []
    @dir_transforms = []
  end
  
  # Add a transform to be run on files. This can either be a class or a block
  # (see Parameters). Each file at revision is given as an SvnTransform::File
  # to each transform, which can alter the basename, body and/or properties
  # of the file prior to its being committed to the new Repository.
  # 
  # ==== Parameters
  # klass<Class>::
  #   A class whose #initialize method accepts a SvnTransform::File as the first
  #   argument and which responds to #run.
  # args<Array>::
  #   Additional arguments to pass to klass#initialize
  # block<Proc>::
  #   A block that accepts one argument (a SvnTransform::File). If a klass is
  #   also given, the block is ignored
  #
  # ==== Returns
  # Array:: The current @file_transforms Array
  #
  # ==== Raises
  # ArgumentError:: Neither a Class nor a block was given.
  def file_transform(klass = nil, *args, &block)
    if klass
      @file_transforms << [klass, args]
    elsif block_given?
      @file_transforms << block
    else
      raise(ArgumentError, "Class or Block required")
    end
  end
  
  # Add a transform to be run on directories. See +file_transform+
  def dir_transform(klass = nil, *args, &block)
    if klass
      @dir_transforms << [klass, args]
    elsif block_given?
      @dir_transforms << block
    else
      raise(ArgumentError, "Class or Block required")
    end
  end
  
  # Run the conversion. This method sets up the connection to the existing
  # repo and the SvnFixture that will generate the final transformed repo, then
  # calls +changesets+ to do the actual work. Finally, commit the SvnFixture
  # (out repo) and update its rev 0 date to match the in repo
  def convert
    in_repo_session = Session.new(@in_repo_uri, @in_username, @in_password)
    @in_repo = in_repo_session.session
    @ctx = in_repo_session.context
    @out_repo = SvnFixture.repo(@out_repo_name, @out_repos_path, @out_wc_path)
    
    # Process changesets and commit
    puts "\nReading existing log..." if PRINT_INFO
    changesets
    puts "\nCommitting to new..." if PRINT_INFO
    @out_repo.commit
    
    # Update rev 0 date
    r0_date = @ctx.revprop_list(@in_repo_uri, 0)[0]['svn:date']
    @out_repo.repos.fs.set_prop('svn:date', SvnFixture.svn_time(r0_date), 0)
  end
  
  # Process the existing changesets and generate a SvnFixture::Revision for
  # each.
  #
  # TODO This is a massive mess. It works, at least for my purposes. But it is
  # a mess. Ideally, it should be multiple methods. Part of this is due to how
  # I set up the SvnFixture::Revision class, which accepts a block at initialize
  # that is process only when its #commit method is called.
  def changesets
    args = ['', 1, @in_repo.latest_revnum, 0, true, nil]
    path_renames = {}
    
    @in_repo.log(*args) do |changes, rev_num, author, date, msg|
      print "#{rev_num} " if PRINT_INFO
      # Sort so that files are processed first (for benefit of PropsToYaml),
      # and deletes are last
      changes = changes.sort { |a,b| sort_for(a, rev_num) <=> sort_for(b, rev_num) }
      # Get revision properties
      rev_props = @ctx.revprop_list(@in_repo_uri, rev_num)[0]
      # Create Revision, including all revprops. Note that svn:author and 
      # svn:date are revprops. SvnFixture::Revision allows these without the
      # svn: prefix (as Symbol), but revprops are written last, and so this
      # should be completely accurate.
      in_repo = @in_repo
      out_wc_path = @out_repo.wc_path
      svn_transform = self
      @out_repo.revision(rev_num, msg, rev_props) do
        print "#{rev_num} " if SvnTransform::PRINT_INFO
        # Now go through all the changes. Setup directorie structure for each
        # node. This is easier to understand, in my opinion.
        
        changes.each do |full_path, change|
          full_path = Pathname.new(full_path.sub(/\A\//, ''))
          # Descend to parent directory
          parent_dir = self
          full_path.dirname.descend do |path|
            unless path.basename == '.'
              parent_dir = parent_dir.dir(path.basename.to_s)
            end
          end
          
          # TODO Replaces
          
          copy_from_path = nil
          if change.copyfrom_path
            short_from_path = path_renames[change.copyfrom_path] || change.copyfrom_path
            copy_from_path = ::File.join(out_wc_path, short_from_path)
          end
          
          if change.action == 'D'
            del_path = path_renames['/' + full_path.to_s] || full_path.to_s
            @ctx.delete(::File.join(out_wc_path, del_path))
          elsif in_repo.stat(full_path.to_s, rev_num).file?
            data = in_repo.file(full_path.to_s, rev_num)
            transform_file = ::SvnTransform::File.new(full_path, data, rev_num, rev_props)
            original_path = transform_file.path
            svn_transform.__send__(:process_file_transforms, transform_file)
            @ctx.cp(copy_from_path, ::File.join(out_wc_path, transform_file.path.to_s)) if copy_from_path
            unless transform_file.skip?
              parent_dir.file(transform_file.basename) do
                body(transform_file.body)
                props(transform_file.properties)
              end
              # For benefit of copies
              if original_path != transform_file.path
                path_renames['/' + original_path] = '/' + transform_file.path.to_s
              end
            end
          else # directory
            # Paths don't change for directories, but use this for consistency
            @ctx.cp(copy_from_path, ::File.join(out_wc_path, full_path.to_s)) if copy_from_path
            parent_dir.dir(full_path.basename.to_s) do
              data = in_repo.dir(full_path.to_s, rev_num)
              transform_dir = ::SvnTransform::Dir.new(full_path, data, rev_num, rev_props, in_repo, self)
              svn_transform.__send__(:process_dir_transforms, transform_dir)
              props(transform_dir.properties)
            end
          end
        end
      end
    end
  end
  
  private
  
  # Process @file_transforms against the given File
  #
  # ==== Parameters
  # file<SvnTransform::File>:: A file in the original repo at a given revision
  def process_file_transforms(file)
    @file_transforms.each do |transform|
      if transform.is_a?(Proc)
        transform.call(file)
      else
        transform[0].new(file, *transform[1]).run
      end
    end
  end
  
  # Process @dir_transforms against the given Dir
  #
  # ==== Parameters
  # dir<SvnTransform::Dir>:: A directory in the original repo at a given revision
  def process_dir_transforms(dir)
    @dir_transforms.each do |transform|
      if transform.is_a?(Proc)
        transform.call(dir)
      else
        transform[0].new(dir, *transform[1]).run
      end
    end
  end
  
  # Return an Integer such that file changes are first, directories second
  # and deleted nodes last (to minimize the chance of a Transformation being
  # overridden. Copies are done first (so that files within a copied dir don't
  # try to create the dir before the copy.
  def sort_for(change, rev_num)
    return -1 if change[1].copyfrom_path
    return 2 if change[1].action == 'D'
    return 0 if @in_repo.stat(change[0].sub(/\A\//, ''), rev_num).file?
    return 1
  end
end # SvnTransform

require 'svn-transform/session'
require 'svn-transform/file'
require 'svn-transform/dir'

# Require predefined transforms
%w{extension newline noop props_to_yaml}.each do |filename|
  require 'svn-transform/transform/' + filename
end
