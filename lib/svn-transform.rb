require 'pathname'
# $LOAD_PATH.unshift('/u/dev/svn-fixture/lib') # TODO Remove
require 'svn-fixture'
p SvnFixture::VERSION # TODO Remove

# TODO file renaming
# TODO properties stuff (incl Directories)
# TODO newline replace

class SvnTransform
  VERSION = '0.0.1'
  
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
  end
  
  def initialize(in_repo_uri, out_repo_name = nil, options = {})
    @in_username = options[:username]
    @in_password = options[:password]
    @in_repo_uri = in_repo_uri
    @out_repo_name = out_repo_name
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
  
  def convert
    @in_repo = connect(@in_repo_uri)
    @out_repo = SvnFixture.repo(@out_repo_name) # TODO name
    changesets
  end
  
  def changesets
    args = ['', 1, @in_repo.latest_revnum, 0, true, nil]
    @in_repo.log(*args) do |changes, rev_num, author, date, msg|
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
        deletes = []
        # Now go through all the changes. Setup directorie structure for each
        # node. This is easier to understand, in my opinion.
        changes.each_pair do |full_path, change|
          full_path = Pathname.new(full_path.sub(/\A\//, ''))
          
          # Descend to parent directory
          parent_dir = self
          full_path.dirname.descend do |path|
            unless path.basename == '.'
              parent_dir = parent_dir.dir(path.basename.to_s)
            end
          end
          
          # TODO Replaces
          
          if change.copyfrom_path
            @ctx.cp(::File.join(out_wc_path, change.copyfrom_path), ::File.join(out_wc_path, full_path.to_s))
          end
          
          if change.action == 'D'
            # Hold till the end of this revision
            deletes << full_path.to_s
          elsif in_repo.stat(full_path.to_s, rev_num).file?
            data = in_repo.file(full_path.to_s, rev_num)
            transform_file = ::SvnTransform::File.new(full_path, data, rev_num, rev_props)
            svn_transform.__send__(:process_file_transforms, transform_file)
            unless transform_file.skip?
              parent_dir.file(transform_file.basename) do
                body(transform_file.body)
                transform_file.properties.each_pair do |prop_k, prop_v|
                  prop(prop_k, prop_v) unless prop_k =~ /\Asvn:entry/
                end
              end
            end
          else # directory
            parent_dir.dir(full_path.basename.to_s) do
              data = in_repo.dir(full_path.to_s, rev_num)
              transform_dir = ::SvnTransform::Dir.new(full_path, data, rev_num, rev_props, in_repo, self)
              svn_transform.__send__(:process_dir_transforms, transform_dir)
              transform_dir.properties.each_pair do |prop_k, prop_v|
                prop(prop_k, prop_v) unless prop_k =~ /\Asvn:entry/
              end
            end
          end
        end
        
        # Now, do deletes
        deletes.each do |del_path|
          @ctx.delete(::File.join(out_wc_path, del_path))
        end
      end
    end
    
    @out_repo.commit
    
    # Update rev 0 date
    r0_date = @ctx.revprop_list(@in_repo_uri, 0)[0]['svn:date']
    @out_repo.repos.fs.set_prop('svn:date', SvnFixture.svn_time(r0_date), 0)
  end
  
  private
  
  def connect(uri)
    @ctx = context(uri)
    
    # This will raise some error if connection fails for whatever reason.
    # I don't currently see a reason to handle connection errors here, as I
    # assume the best handling would be to raise another error.
    ::Svn::Ra::Session.open(uri, {}, callbacks(@ctx))
  end
  
  def context(uri)
    # Client::Context, which paticularly holds an auth_baton.
    ctx = ::Svn::Client::Context.new
    if @in_username && @in_password
      # TODO: What if another provider type is needed? Is this plausible?
      ctx.add_simple_prompt_provider(0) do |cred, realm, username, may_save|
        cred.username = @in_username
        cred.password = @in_password
      end
    elsif URI.parse(uri).scheme == "file" 
      ctx.add_username_prompt_provider(0) do |cred, realm, username, may_save|
        cred.username = @in_username || "ANON"
      end
    else
      ctx.auth_baton = ::Svn::Core::AuthBaton.new()
    end
    ctx
  end
  
  # callbacks for Svn::Ra::Session.open. This includes the client +context+.
  def callbacks(ctx)
    ::Svn::Ra::Callbacks.new(ctx.auth_baton)
  end
  
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
end # SvnTransform

require 'svn-transform/file'
require 'svn-transform/dir'
require 'svn-transform/transform/noop'
