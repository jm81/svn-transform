class SvnTransform
  # A directory in original Subversion Repository, at a given changeset. 
  # Instances are initialized by SvnTransform#changesets.
  #
  # An instance for each file in the original repo at each revision will be
  # passed to any directory transform blocks (TODO more info)
  #
  # Although more could theoretically be done (see #initialize fixture_dir
  # param), the main thing intended to be alterable are the properties.
  class Dir
    # Initialize Dir instance using data passed by SvnTransform#changesets.
    # This is data that will be available to Transformation blocks. It's
    # relevant to remember that all this happens within a block given to an
    # SvnFixture::Revision.
    #
    # ==== Parameters
    # path<Pathname>::
    #   Full path within original Repository
    # node_data<Array[String, Hash]>::
    #   Array returned by SWIG::TYPE_p_svn_ra_session_t#dir. First element is
    #   a Hash of directory entries, second is Hash of properties.
    # rev_num<Integer>::
    #   Number of current revision
    # rev_props<Hash>::
    #   Properties for current revision
    # repos<Svn::Ra::Session>::
    #   Repo session (made available for PropsToYaml)
    # fixture_dir<SvnFixture::Directory>::
    #   The SvnFixture::Directory representing this directory. This could be
    #   used to add, delete files, subdirs, etc, but doing much of that is
    #   likely to lead to weird results. I certainly don't intend to test this
    #   outside of one use case (PropsToYaml)
    def initialize(path, node_data, rev_num, rev_props, repos, fixture_dir)
      @path = path.kind_of?(Pathname) ? path : Pathname.new(path)
      @entries = node_data[0]
      @properties = node_data[1]
      @rev_num = rev_num
      @rev_props = rev_props
      @repos = repos
      @fixture_dir = fixture_dir
    end
    
    attr_reader :path, :entries, :properties, :rev_num, :rev_props, :repos, :fixture_dir
    
    # Assign a new properties Hash to the node
    #
    # ==== Parameters
    # hsh<~each_pair>::
    #   A Hash (or other object) responding to #each_pair, where keys are 
    #   svn property keys, and values are the corresponding property values.
    #   This method does not verify that keys are "human-readable"
    #   (See http://svnbook.red-bean.com/en/1.0/ch07s02.html)
    def properties=(hsh)
      unless hsh.respond_to?(:each_pair)
        raise ArgumentError, "Argument must respond to #each_pair, such as a Hash"
      end
      @properties = hsh
    end
    
    # Get the base of the File
    def basename
      @path.basename.to_s
    end
  end
end
