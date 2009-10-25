class SvnTransform
  module Transform
    # Transform all newlines to use a given sequence. For example, a repository
    # some files using CRLF and some using LF could be transformed so that all
    # files through all revisions use LF.
    class Newline
      LF = "\n"
      CRLF = "\r\n"
      CR = "\r"
      
      # Initialize Newline Transform.
      #
      # ==== Parameters
      # file<SvnTransform::File>:: File at a given revision
      # newline<String>:: What to replace newlines with (defaults to \n)
      def initialize(file, newline = LF)
        @file = file
        @newline = newline
      end
      
      # Run the transform. It first converts all newlines (LF, CRLF and CR) to
      # LF, then replaces LF if needed.
      #
      # ==== Returns
      # True, False:: indicating whether a change was made.
      def run
        body = @file.body.dup
        # Replace CR and CRLF
        body = all_to_lf(body)
        # Replace LFs with newline if needed
        body.gsub!(LF, @newline) unless LF == @newline
        
        if body != @file.body
          @file.body = body
          return true
        else
          return false
        end
      end
      
      private
      
      # Ensure all newlines are represented by LF
      def all_to_lf(body)
        # Replace CRLF's, then lone CR's
        return body.gsub(CRLF, LF).gsub(CR, LF)
      end
    end # Newline
  end # Transform
end # SvnTransform
