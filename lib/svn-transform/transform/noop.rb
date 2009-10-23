class SvnTransform
  module Transform
    # A Transform class that does nothing. Useful for classes to inherit from
    # that don't need any special initialize logic, and as an ultra-simple
    # example.
    class Noop
      # Initialize Noop Transform.
      #
      # ==== Parameters
      # file<SvnTransform::File>:: File at a given revision
      # args<Array>:: Splat of other args, all ignored
      def initialize(file, *args)
        @file = file
        @args = args
      end
      
      # Run the transform. In this case it does nothing. In actual transforms,
      # it would alter the @file (#body, #basename, and/or #properties) in
      # some way, probably only if a condition met.
      #
      # ==== Returns
      # False:: indicating that nothing was done.
      def run
        return false
      end
    end
  end
end
