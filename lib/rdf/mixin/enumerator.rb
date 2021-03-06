module RDF
  ##
  # Enumerators for different mixins. These are defined in a separate module, so that they are bound when used, allowing other mixins inheriting behavior to be included.
  module Enumerable
    # Extends Enumerator with {Queryable} and {Enumerable}, which is used by {Enumerable#each_statement} and {Queryable#enum_for}
    class Enumerator < ::Enumerator
      include Queryable
      include Enumerable

      # Make sure returned arrays are also queryable
      def to_a
        return super.to_a.extend(RDF::Queryable, RDF::Enumerable)
      end
      alias_method :to_ary, :to_a
    end
  end

  module Countable
    # Extends Enumerator with {Countable}, which is used by {Countable#enum_for}
    class Enumerator < ::Enumerator
      include Countable
    end
  end

  module Queryable
    # Extends Enumerator with {Queryable} and {Enumerable}, which is used by {Enumerable#each_statement} and {Queryable#enum_for}
    class Enumerator < ::Enumerator
      include Queryable
      include Enumerable

      # Make sure returned arrays are also queryable
      def to_a
        return super.to_a.extend(RDF::Queryable, RDF::Enumerable)
      end
      alias_method :to_ary, :to_a
    end
  end
end
