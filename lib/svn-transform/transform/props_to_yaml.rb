require 'yaml'

class SvnTransform
  module Transform
    # Move svn properties to YAML Front matter (or, for directories, to a YAML
    # file). This is particularly intended to assist when converting a 
    # Subversion repository to another SCM that doesn't have arbitrary 
    # per-node properties (or whose conversion tools ignore them).
    #
    # See +new+ (+initialize+) for options
    class PropsToYaml
      # Default filename for yaml file holding directory properties
      DEFAULT_YAML_FILE = 'meta.yml'
      
      # Initialize with node, instructions and options
      #
      # ==== Parameters
      # node<SvnTransform::File, SvnTransform::Directory>:
      #   The file or directory to be transformed
      # instructions<Array of Array, Symbol>:
      #   - :all (default) will move all svn properties to YAML Front Matter
      #     (except svn:entry props)
      #   - An Array of Arrays. The first element of the inner Array is a Regex
      #     or String to be matched against. The second element is an action
      #     to take for those properties that match (using === operator).
      #     Actions can be:
      #     - :move : Just move the property to YAML
      #     - :delete : Remove from svn properties, don't add to YAML
      #     - String : gsub replacement string
      # 
      # ==== Options
      # :yaml_file<String>::
      #   Filename for directory YAML properties (defaults to DEFAULT_YAML_FILE)
      def initialize(node, instructions = :all, options = {})
        @node = node
        @instructions = instructions
        @instructions = [[/\A(?!svn:entry)/]] if @instructions == :all
        @yaml_file = options[:yaml_file] || DEFAULT_YAML_FILE
        @dirty = false
      end
      
      def run
        if file?
          body_less_yaml = has_yaml_props? ? yaml_split[1] : @node.body
        end
        @yaml_props = yaml_properties
        @svn_props = @node.properties
        
        @node.properties.each do |prop_key, prop_val|
          process_property(prop_key, prop_val)
        end
        
        if @dirty
          if file?
            @node.body = @yaml_props.empty? ? body_less_yaml :
              (@yaml_props.to_yaml + "---\n\n" + body_less_yaml)
          else
            @node.fixture_dir.file(@yaml_file).body(@yaml_props.to_yaml)
          end
          @node.properties = @svn_props
          return true
        else
          return false
        end
      end
      
      def process_property(prop_key, prop_val)
        @instructions.each do |matcher, action|
          action ||= :move
          if matcher === prop_key
            @svn_props.delete(prop_key)
            @dirty = true
            case action
            when :delete
              return true # Do nothing
            when :move
              new_key = prop_key
            else # A string, hopefully
              new_key = prop_key.gsub(matcher, action)
            end
            @yaml_props[new_key] = prop_val
            return true
          end
        end
        return false
      end
      
      private
      
      # Is the node a File?
      def file?
        @node.kind_of?(SvnTransform::File)
      end
      
      # Is the node a Directory?
      def directory?
        !file?
      end
      
      # Get YAML properties. For a directory, these are stored in 
      # @options[:yaml_file], for a file, they are stored at the beginning of 
      # the file: the first line will bec and the YAML will end before a 
      # line containing "..." or "---".
      def yaml_properties
        if directory?
          yaml_path = ::File.join(@node.path, @yaml_file)
          @node.repos.stat(yaml_path, @node.rev_num) ?
            YAML.load(@node.repos.file(yaml_path, @node.rev_num)[0]) :
            {}
        else
          has_yaml_props? ?
            YAML.load(yaml_split[0]) :
            {}
        end
      end
      
      # Determine if file has yaml properties, by checking if the file starts
      # with three leading dashes
      def has_yaml_props?
        file? && @node.body[0..2] == "---"
      end
      
      # Split a file between properties and body at a line with three dots.
      # Left trim the body and there may have been blank lines added for
      # clarity.
      def yaml_split
        body = @node.body.gsub("\r", "")
        ary = body.split(/\n\.\.\.\n|\n---\n/,2)
        ary[1] = ary[1].lstrip
        ary
      end
    end
  end
end
