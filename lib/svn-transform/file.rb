class SvnTransform
  # A file in original Subversion Repository, at a given changeset. Instances
  # are initialized by SvnTransform#changesets.
  #
  # An instance for each file in the original repo at each revision will be
  # passed to any file transform blocks (TODO more info)
  class File
    # Initialize File instance using data passed by SvnTransform#changesets.
    # This is data that will be available to Transformation blocks. It's
    # relevant to remember that all this happens within a block given to an
    # SvnFixture::Revision
    #
    # ==== Parameters
    # path<Pathname>::
    #   Full path within original Repository
    # node_data<Array[String, Hash]>::
    #   Array returned by SWIG::TYPE_p_svn_ra_session_t#file. First element is
    #   node body, second is hash of properties.
    # rev_num<Integer>::
    #   Number of current revision
    # rev_props<Hash>::
    #   Properties for current revision
    def initialize(path, node_data, rev_num, rev_props)
      @path = path.kind_of?(Pathname) ? path : Pathname.new(path)
      @body = node_data[0]
      @properties = node_data[1]
      @rev_num = rev_num
      @rev_props = rev_props
    end
    
    attr_reader :path, :body, :properties, :rev_num, :rev_props
    
    # Change the body of the node. The new body will be placed in the new
    # repository.
    #
    # ==== Parameters
    # value<String>:: New body
    attr_writer :body
    
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
    
    # Change the basename of the File. Alters the #path
    #
    # ==== Parameters
    # val<String>:: New basename
    def basename=(val)
      @path = @path.dirname + val
    end
    
    # Skip this file at this revision (that is, don't commit it to new repo).
    def skip!
      @skip = true
    end
    
    # Whether this file should be skipped (not committed to new repo at this
    # revision)
    def skip?
      @skip == true
    end
  end
end
