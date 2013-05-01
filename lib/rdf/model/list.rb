module RDF
  ##
  # An RDF list.
  #
  # @example Constructing a new list
  #   RDF::List[1, 2, 3]
  #
  # @since 0.2.3
  class RDF::List
    include RDF::Enumerable
    include RDF::Value
    include Comparable

    ##
    # Constructs a new list from the given `values`.
    #
    # The list will be identified by a new autogenerated blank node, and
    # backed by an initially empty in-memory graph.
    #
    # @example
    #   RDF::List[]
    #   RDF::List[*(1..10)]
    #   RDF::List[1, 2, 3]
    #   RDF::List["foo", "bar"]
    #   RDF::List["a", 1, "b", 2, "c", 3]
    #
    # @param  [Array<RDF::Term>] values
    # @return [RDF::List]
    def self.[](*values)
      self.new(nil, nil, values)
    end

    ##
    # Initializes a newly-constructed list.
    #
    # @param  [RDF::Resource]     subject
    # @param  [RDF::Graph]        graph
    # @param  [Array<RDF::Term>] values
    # @yield  [list]
    # @yieldparam [RDF::List] list
    def initialize(subject = nil, graph = nil, values = nil, &block)
      @subject = subject || RDF::Node.new
      @graph   = graph   || RDF::Graph.new

      values.each { |value| self << value } unless values.nil? || values.empty?

      if block_given?
        case block.arity
          when 1 then block.call(self)
          else instance_eval(&block)
        end
      end
    end

    UNSET = Object.new.freeze # @private

    # The canonical empty list.
    NIL = RDF::List.new(RDF.nil).freeze

    ##
    # Validate the list ensuring that
    # * rdf:rest values are all BNodes are nil
    # * each subject has exactly one value for `rdf:first` and
    #   `rdf:rest`.
    # * The value of `rdf:rest` must be either a BNode or `rdf:nil`.
    # * All other properties are ignored.
    # @return [Boolean]
    def valid?
      li = subject
      while li != RDF.nil do
        rest = nil
        firsts = rests = 0
        @graph.query(:subject => li) do |st|
          case st.predicate
          when RDF.first
            firsts += 1
          when RDF.rest
            rest = st.object
            return false unless rest.node? || rest == RDF.nil
            rests += 1
          end
        end
        return false unless firsts == 1 && rests == 1
        li = rest
      end
      true
    end

    # @!attribute [r] subject
    # @return [RDF::Resource] the subject term of this list.
    attr_reader :subject

    # @!attribute [r] graph
    # @return [RDF::Graph] the underlying graph storing the statements that constitute this list
    attr_reader :graph

    ##
    # Returns the set intersection of this list and `other`.
    #
    # The resulting list contains the elements common to both lists, with no
    # duplicates.
    #
    # @example
    #   RDF::List[1, 2] & RDF::List[1, 2]       #=> RDF::List[1, 2]
    #   RDF::List[1, 2] & RDF::List[2, 3]       #=> RDF::List[2]
    #   RDF::List[1, 2] & RDF::List[3, 4]       #=> RDF::List[]
    #
    # @param  [RDF::List] other
    # @return [RDF::List]
    # @see    http://ruby-doc.org/core-1.9/classes/Array.html#M000469
    def &(other)
      RDF::List[*(to_a & other.to_a)]
    end

    ##
    # Returns the set union of this list and `other`.
    #
    # The resulting list contains the elements from both lists, with no
    # duplicates.
    #
    # @example
    #   RDF::List[1, 2] | RDF::List[1, 2]       #=> RDF::List[1, 2]
    #   RDF::List[1, 2] | RDF::List[2, 3]       #=> RDF::List[1, 2, 3]
    #   RDF::List[1, 2] | RDF::List[3, 4]       #=> RDF::List[1, 2, 3, 4]
    #
    # @param  [RDF::List] other
    # @return [RDF::List]
    # @see    http://ruby-doc.org/core-1.9/classes/Array.html#M000470
    def |(other)
      RDF::List[*(to_a | other.to_a)]
    end

    ##
    # Returns the concatenation of this list and `other`.
    #
    # @example
    #   RDF::List[1, 2] + RDF::List[3, 4]       #=> RDF::List[1, 2, 3, 4]
    #
    # @param  [RDF::List] other
    # @return [RDF::List]
    # @see    http://ruby-doc.org/core-1.9/classes/Array.html#M000466
    def +(other)
      RDF::List[*(to_a + other.to_a)]
    end

    ##
    # Returns the difference between this list and `other`, removing any
    # elements that appear in both lists.
    #
    # @example
    #   RDF::List[1, 2, 2, 3] - RDF::List[2]    #=> RDF::List[1, 3]
    #
    # @param  [RDF::List] other
    # @return [RDF::List]
    # @see    http://ruby-doc.org/core-1.9/classes/Array.html#M000468
    def -(other)
      RDF::List[*(to_a - other.to_a)]
    end

    ##
    # Returns either a repeated list or a string concatenation of the
    # elements in this list.
    #
    # @overload *(times)
    #   Returns a new list built of `times` repetitions of this list.
    #
    #   @example
    #     RDF::List[1, 2, 3] * 2                #=> RDF::List[1, 2, 3, 1, 2, 3]
    #
    #   @param  [Integer] times
    #   @return [RDF::List]
    #
    # @overload *(sep)
    #   Returns the string concatenation of the elements in this list
    #   separated by `sep`. Equivalent to `self.join(sep)`.
    #
    #   @example
    #     RDF::List[1, 2, 3] * ","              #=> "1,2,3"
    #
    #   @param  [String, #to_s] sep
    #   @return [RDF::List]
    #
    # @return [RDF::List]
    # @see    http://ruby-doc.org/core-1.9/classes/Array.html#M000467
    def *(int_or_str)
      case int_or_str
        when Integer then RDF::List[*(to_a * int_or_str)]
        else join(int_or_str.to_s)
      end
    end

    ##
    # Returns the element at `index`.
    #
    # @example
    #   RDF::List[1, 2, 3][0]                   #=> RDF::Literal(1)
    #
    # @param  [Integer] index
    # @return [RDF::Term]
    # @see    http://ruby-doc.org/core-1.9/classes/Array.html#M000417
    def [](index)
      at(index)
    end

    ##
    # Appends an element to the tail of this list.
    #
    # @example
    #   RDF::List[] << 1 << 2 << 3              #=> RDF::List[1, 2, 3]
    #
    # @param  [RDF::Term] value
    # @return [RDF::List]
    # @see    http://ruby-doc.org/core-1.9/classes/Array.html#M000424
    def <<(value)
      value = case value
        when nil         then RDF.nil
        when RDF::Value  then value
        when Array       then RDF::List.new(nil, graph, value)
        else value
      end

      if empty?
        new_subject = subject
      else
        old_subject, new_subject = last_subject, RDF::Node.new
        graph.delete([old_subject, RDF.rest, RDF.nil])
        graph.insert([old_subject, RDF.rest, new_subject])
      end

      graph.insert([new_subject, RDF.first, value.is_a?(RDF::List) ? value.subject : value])
      graph.insert([new_subject, RDF.rest, RDF.nil])

      self
    end

    ##
    # Compares this list to `other` for sorting purposes.
    #
    # @example
    #   RDF::List[1] <=> RDF::List[1]           #=> 0
    #   RDF::List[1] <=> RDF::List[2]           #=> -1
    #   RDF::List[2] <=> RDF::List[1]           #=> 1
    #
    # @param  [RDF::List] other
    # @return [Integer]
    # @see    http://ruby-doc.org/core-1.9/classes/Array.html#M000461
    def <=>(other)
      to_a <=> other.to_a # TODO: optimize this
    end

    ##
    # Returns `true` if this list is empty.
    #
    # @example
    #   RDF::List[].empty?                      #=> true
    #   RDF::List[1, 2, 3].empty?               #=> false
    #
    # @return [Boolean]
    # @see    http://ruby-doc.org/core-1.9/classes/Array.html#M000434
    def empty?
      graph.query(:subject => subject, :predicate => RDF.first).empty?
    end

    ##
    # Returns the length of this list.
    #
    # @example
    #   RDF::List[].length                      #=> 0
    #   RDF::List[1, 2, 3].length               #=> 3
    #
    # @return [Integer]
    # @see    http://ruby-doc.org/core-1.9/classes/Array.html#M000433
    def length
      each.count
    end

    alias_method :size, :length

    ##
    # Returns the index of the first element equal to `value`, or `nil` if
    # no match was found.
    #
    # @example
    #   RDF::List['a', 'b', 'c'].index('a')     #=> 0
    #   RDF::List['a', 'b', 'c'].index('d')     #=> nil
    #
    # @param  [RDF::Term] value
    # @return [Integer]
    # @see    http://ruby-doc.org/core-1.9/classes/Array.html#M000436
    def index(value)
      each.with_index do |v, i|
        return i if v == value
      end
      return nil
    end

    ##
    # Returns a slice of a list.
    #
    # @example
    #     RDF::List[1, 2, 3].slice(0)    #=> RDF::Literal(1),
    #     RDF::List[1, 2, 3].slice(0, 2) #=> RDF::List[1, 2],
    #     RDF::List[1, 2, 3].slice(0..2) #=> RDF::List[1, 2, 3]
    #
    # @return [RDF::Term]
    # @see    http://ruby-doc.org/core-1.9/classes/Array.html#M000462
    def slice(*args)
      case argc = args.size
        when 2 then slice_with_start_and_length(*args)
        when 1 then (arg = args.first).is_a?(Range) ? slice_with_range(arg) : at(arg)
        when 0 then raise ArgumentError, "wrong number of arguments (0 for 1)"
        else raise ArgumentError, "wrong number of arguments (#{argc} for 2)"
      end
    end

    ##
    # @private
    def slice_with_start_and_length(start, length)
      RDF::List[*to_a.slice(start, length)]
    end

    ##
    # @private
    def slice_with_range(range)
      RDF::List[*to_a.slice(range)]
    end

    protected :slice_with_start_and_length
    protected :slice_with_range

    ##
    # Returns element at `index` with default.
    #
    # @example
    #   RDF::List[1, 2, 3].fetch(0)             #=> RDF::Literal(1)
    #   RDF::List[1, 2, 3].fetch(4)             #=> IndexError
    #   RDF::List[1, 2, 3].fetch(4, nil)        #=> nil
    #   RDF::List[1, 2, 3].fetch(4) { |n| n*n } #=> 16
    #
    # @return [RDF::Term]
    # @see    http://ruby-doc.org/core-1.9/classes/Array.html#M000420
    def fetch(index, default = UNSET, &block)
      each.with_index do |v, i|
        return v if i == index
      end

      case
        when block_given?         then block.call(index)
        when !default.eql?(UNSET) then default
        else raise IndexError, "index #{index} not in the list #{self.inspect}"
      end
    end

    ##
    # Returns the element at `index`.
    #
    # @example
    #   RDF::List[1, 2, 3].at(0)                #=> 1
    #   RDF::List[1, 2, 3].at(4)                #=> nil
    #
    # @return [RDF::Term]
    # @see    http://ruby-doc.org/core-1.9/classes/Array.html#M000419
    def at(index)
      each.with_index do |v, i|
        return v if i == index
      end
      return nil
    end

    alias_method :nth, :at

    ##
    # Returns the first element in this list.
    #
    # @example
    #   RDF::List[*(1..10)].first               #=> RDF::Literal(1)
    #
    # @return [RDF::Term]
    def first
      graph.first_object(:subject => first_subject, :predicate => RDF.first)
    end

    ##
    # Returns the second element in this list.
    #
    # @example
    #   RDF::List[*(1..10)].second              #=> RDF::Literal(2)
    #
    # @return [RDF::Term]
    def second
      at(1)
    end

    ##
    # Returns the third element in this list.
    #
    # @example
    #   RDF::List[*(1..10)].third               #=> RDF::Literal(4)
    #
    # @return [RDF::Term]
    def third
      at(2)
    end

    ##
    # Returns the fourth element in this list.
    #
    # @example
    #   RDF::List[*(1..10)].fourth              #=> RDF::Literal(4)
    #
    # @return [RDF::Term]
    def fourth
      at(3)
    end

    ##
    # Returns the fifth element in this list.
    #
    # @example
    #   RDF::List[*(1..10)].fifth               #=> RDF::Literal(5)
    #
    # @return [RDF::Term]
    def fifth
      at(4)
    end

    ##
    # Returns the sixth element in this list.
    #
    # @example
    #   RDF::List[*(1..10)].sixth               #=> RDF::Literal(6)
    #
    # @return [RDF::Term]
    def sixth
      at(5)
    end

    ##
    # Returns the seventh element in this list.
    #
    # @example
    #   RDF::List[*(1..10)].seventh             #=> RDF::Literal(7)
    #
    # @return [RDF::Term]
    def seventh
      at(6)
    end

    ##
    # Returns the eighth element in this list.
    #
    # @example
    #   RDF::List[*(1..10)].eighth              #=> RDF::Literal(8)
    #
    # @return [RDF::Term]
    def eighth
      at(7)
    end

    ##
    # Returns the ninth element in this list.
    #
    # @example
    #   RDF::List[*(1..10)].ninth               #=> RDF::Literal(9)
    #
    # @return [RDF::Term]
    def ninth
      at(8)
    end

    ##
    # Returns the tenth element in this list.
    #
    # @example
    #   RDF::List[*(1..10)].tenth               #=> RDF::Literal(10)
    #
    # @return [RDF::Term]
    def tenth
      at(9)
    end

    ##
    # Returns the last element in this list.
    #
    # @example
    #   RDF::List[*(1..10)].last                 #=> RDF::Literal(10)
    #
    # @return [RDF::Term]
    # @see    http://ruby-doc.org/core-1.9/classes/Array.html#M000422
    def last
      graph.first_object(:subject => last_subject, :predicate => RDF.first)
    end

    ##
    # Returns a list containing all but the first element of this list.
    #
    # @example
    #   RDF::List[1, 2, 3].rest                 #=> RDF::List[2, 3]
    #
    # @return [RDF::List]
    def rest
      (subject = rest_subject).eql?(RDF.nil) ? nil : self.class.new(subject, graph)
    end

    ##
    # Returns a list containing the last element of this list.
    #
    # @example
    #   RDF::List[1, 2, 3].tail                 #=> RDF::List[3]
    #
    # @return [RDF::List]
    def tail
      (subject = last_subject).eql?(RDF.nil) ? nil : self.class.new(subject, graph)
    end

    ##
    # Returns the first subject term constituting this list.
    #
    # This is equivalent to `subject`.
    #
    # @example
    #   RDF::List[1, 2, 3].first_subject        #=> RDF::Node(...)
    #
    # @return [RDF::Resource]
    def first_subject
      subject
    end

    ##
    # @example
    #   RDF::List[1, 2, 3].rest_subject         #=> RDF::Node(...)
    #
    # @return [RDF::Resource]
    def rest_subject
      graph.first_object(:subject => subject, :predicate => RDF.rest)
    end

    ##
    # Returns the last subject term constituting this list.
    #
    # @example
    #   RDF::List[1, 2, 3].last_subject         #=> RDF::Node(...)
    #
    # @return [RDF::Resource]
    def last_subject
      each_subject.to_a.last # TODO: optimize this
    end

    ##
    # Yields each subject term constituting this list.
    #
    # @example
    #   RDF::List[1, 2, 3].each_subject do |subject|
    #     puts subject.inspect
    #   end
    #
    # @return [Enumerator]
    # @see    RDF::Enumerable#each
    def each_subject(&block)
      return enum_subject unless block_given?

      subject = self.subject
      block.call(subject)

      loop do
        rest = graph.first_object(:subject => subject, :predicate => RDF.rest)
        break if rest.nil? || rest.eql?(RDF.nil)
        block.call(subject = rest)
      end
    end

    ##
    # Yields each element in this list.
    #
    # @example
    #   RDF::List[1, 2, 3].each do |value|
    #     puts value.inspect
    #   end
    #
    # @return [Enumerator]
    # @see    http://ruby-doc.org/core-1.9/classes/Enumerable.html
    def each(&block)
      return to_enum unless block_given?

      each_subject do |subject|
        if value = graph.first_object(:subject => subject, :predicate => RDF.first)
          block.call(value) # FIXME
        end
      end
    end

    ##
    # Yields each statement constituting this list.
    #
    # @example
    #   RDF::List[1, 2, 3].each_statement do |statement|
    #     puts statement.inspect
    #   end
    #
    # @return [Enumerator]
    # @see    RDF::Enumerable#each_statement
    def each_statement(&block)
      return enum_statement unless block_given?

      each_subject do |subject|
        graph.query(:subject => subject, &block)
      end
    end

    ##
    # Returns a string created by converting each element of this list into
    # a string, separated by `sep`.
    #
    # @example
    #   RDF::List[1, 2, 3].join                 #=> "123"
    #   RDF::List[1, 2, 3].join(", ")           #=> "1, 2, 3"
    #
    # @param  [String] sep
    # @return [String]
    # @see    http://ruby-doc.org/core-1.9/classes/Array.html#M000438
    def join(sep = $,)
      map(&:to_s).join(sep)
    end

    ##
    # Returns the elements in this list in reversed order.
    #
    # @example
    #   RDF::List[1, 2, 3].reverse              #=> RDF::List[3, 2, 1]
    #
    # @return [RDF::List]
    # @see    http://ruby-doc.org/core-1.9/classes/Array.html#M000439
    def reverse
      RDF::List[*to_a.reverse]
    end

    ##
    # Returns the elements in this list in sorted order.
    #
    # @example
    #   RDF::List[2, 3, 1].sort                 #=> RDF::List[1, 2, 3]
    #
    # @return [RDF::List]
    # @see    http://ruby-doc.org/core-1.9/classes/Enumerable.html#M003038
    def sort(&block)
      RDF::List[*super]
    end

    ##
    # Returns the elements in this list in sorted order.
    #
    # @example
    #   RDF::List[2, 3, 1].sort_by(&:to_i)      #=> RDF::List[1, 2, 3]
    #
    # @return [RDF::List]
    # @see    http://ruby-doc.org/core-1.9/classes/Enumerable.html#M003039
    def sort_by(&block)
      RDF::List[*super]
    end

    ##
    # Returns a new list with the duplicates in this list removed.
    #
    # @example
    #   RDF::List[1, 2, 2, 3].uniq              #=> RDF::List[1, 2, 3]
    #
    # @return [RDF::List]
    # @see    http://ruby-doc.org/core-1.9/classes/Array.html#M000471
    def uniq
      RDF::List[*to_a.uniq]
    end

    ##
    # Returns the elements in this list as an array.
    #
    # @example
    #   RDF::List[].to_a                        #=> []
    #   RDF::List[1, 2, 3].to_a                 #=> [RDF::Literal(1), RDF::Literal(2), RDF::Literal(3)]
    #
    # @return [Array]
    def to_a
      each.to_a
    end

    ##
    # Returns the elements in this list as a set.
    #
    # @example
    #   RDF::List[1, 2, 3].to_set               #=> Set[RDF::Literal(1), RDF::Literal(2), RDF::Literal(3)]
    #
    # @return [Set]
    def to_set
      require 'set' unless defined?(::Set)
      each.to_set
    end

    ##
    # Returns a string representation of this list.
    #
    # @example
    #   RDF::List[].to_s                        #=> "RDF::List[]"
    #   RDF::List[1, 2, 3].to_s                 #=> "RDF::List[1, 2, 3]"
    #
    # @return [String]
    def to_s
      'RDF::List[' + join(', ') + ']'
    end

    ##
    # Returns a developer-friendly representation of this list.
    #
    # @example
    #   RDF::List[].inspect                     #=> "#<RDF::List(_:g2163790380)>"
    #
    # @return [String]
    def inspect
      if self.equal?(NIL)
        'RDF::List::NIL'
      else
        #sprintf("#<%s:%#0x(%s)>", self.class.name, __id__, subject.to_s)
        sprintf("#<%s:%#0x(%s)>", self.class.name, __id__, to_s) # FIXME
      end
    end
  end
end
