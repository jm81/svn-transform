class SvnTransform
  module Transform
    # Convert file extensions
    class Extension
      # Initialize Extension Transform.
      #
      # ==== Parameters
      # file<SvnTransform::File>:: File at a given revision
      # extensions<~each_pair>:: A Hash of old => new extension
      # 
      # ==== Example
      #
      #    SvnTransform::Transform::Extension.new(@file,
      #      {:txt => :markdown, :ruby => :rb}
      #    )
      # 
      def initialize(file, extensions)
        @file = file
        @extensions = {}
        (extensions || {}).each_pair do |existing, change_to|
          @extensions[".#{existing}"] = ".#{change_to}"
        end
      end
      
      # Check if this @file has one of the extensions (matches a key). If so,
      # change its extension.
      #
      # ==== Returns
      # True, False:: indicating whether a change was made.
      def run
        @extensions.each_pair do |existing, change_to|
          if @file.path.extname == existing
            @file.basename = @file.basename.gsub(/#{existing}\Z/, change_to)
            return true
          end
        end
        return false
      end
    end
  end
end
