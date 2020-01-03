module Fixtury
  module Errors
    class UnrecognizableLocatorError < ::StandardError

      def initialize(action, thing)
        super("Locator did not reognize #{thing} during #{action}")
      end

    end
  end
end
