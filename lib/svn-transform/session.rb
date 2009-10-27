class SvnTransform
  # A simplistic wrapper for Svn::Ra::Session. This takes care of setting up
  # the context and callbacks as well as making the actual connection.
  class Session
    # Setup repository information
    #
    # ==== Parameters
    # uri<String>:: URI of the repository (e.g. svn://example.com/repo)
    # username<String>:: Username, if needed
    # password<String>:: Password, if needed
    def initialize(uri, username = nil, password = nil)
      @uri = uri
      @username = username
      @password = password
    end
    
    # Open and return the actual Svn::Ra::Session
    #
    # ==== Returns
    # Svn::Ra::Session:: A remote access session to a repository.
    def session
      # This will raise some error if connection fails for whatever reason.
      # I don't currently see a reason to handle connection errors here, as I
      # assume the best handling would be to raise another error.
      @session ||= ::Svn::Ra::Session.open(@uri, {}, self.callbacks)
    end
    
    # Setup, if needed, and return the working context (I don't really 
    # understand all this, but it's required to work with the working copy).
    #
    # ==== Returns
    # Svn::Client::Context:: Context for working with working copy
    def context
      @context || begin
        # Client::Context, which paticularly holds an auth_baton.
        @context = ::Svn::Client::Context.new
        if @username && @password
          # TODO: What if another provider type is needed? Is this plausible?
          @context.add_simple_prompt_provider(0) do |cred, realm, username, may_save|
            cred.username = @username
            cred.password = @password
          end
        elsif URI.parse(@uri).scheme == "file" 
          @context.add_username_prompt_provider(0) do |cred, realm, username, may_save|
            cred.username = @username || "ANON"
          end
        else
          @context.auth_baton = ::Svn::Core::AuthBaton.new()
        end
        @context
      end
    end
    
    # Setup callbacks for Svn::Ra::Session.open.
    #
    # ==== Returns
    # Svn::Ra::Callbacks
    def callbacks
      ::Svn::Ra::Callbacks.new(context.auth_baton)
    end
  end
end
