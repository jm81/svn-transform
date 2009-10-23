require 'pathname'
# $LOAD_PATH.unshift('/u/dev/svn-fixture/lib') # TODO Remove
require 'svn-fixture'
p SvnFixture::VERSION # TODO Remove

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
            @ctx.cp(File.join(out_wc_path, change.copyfrom_path), File.join(out_wc_path, full_path.to_s))
          end
          
          if change.action == 'D'
            # Hold till the end of this revision
            deletes << full_path.to_s
          elsif in_repo.stat(full_path.to_s, rev_num).file?
            # TODO file renaming
            # TODO properties stuff
            # TODO delete properties
            # TODO newline replace
            data = in_repo.file(full_path.to_s, rev_num)
            parent_dir.file(full_path.basename.to_s) do
              body(data[0])
              data[1].each_pair do |prop_k, prop_v|
                prop(prop_k, prop_v) unless prop_k =~ /\Asvn:entry/
              end
            end
          else # directory
            parent_dir.dir(full_path.basename.to_s) do
              data = in_repo.dir(full_path.to_s, rev_num)
              # TODO properties to yaml
              data[1].each_pair do |prop_k, prop_v|
                prop(prop_k, prop_v) unless prop_k =~ /\Asvn:entry/
              end
            end
          end
        end
        
        # Now, do deletes
        deletes.each do |del_path|
          @ctx.delete(File.join(out_wc_path, del_path))
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
end
