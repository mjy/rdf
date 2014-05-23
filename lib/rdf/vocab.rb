module RDF
  ##
  # A {Vocabulary} represents an RDFS or OWL vocabulary.
  #
  # A {Vocabulary} can also serve as a Domain Specific Language (DSL) for generating an RDF Graph definition for the vocabulary (see {RDF::Vocabulary#to_graph}).
  #
  # ### Defining a vocabulary using the DSL
  # Vocabularies can be defined based on {RDF::Vocabulary} or {RDF::StrictVocabulary} using a simple Domain Specific Language (DSL). Terms of the vocabulary are specified using either `property` or `term` (alias), with the attributes of the term listed in a hash. See {property} for description of the hash.
  #
  # ### Vocabularies:
  #
  # The following vocabularies are pre-defined for your convenience:
  #
  # * {RDF}         - Resource Description Framework (RDF)
  # * {RDF::CC}     - Creative Commons (CC)
  # * {RDF::CERT}   - W3 Authentication Certificate (CERT)
  # * {RDF::DC}     - Dublin Core (DC)
  # * {RDF::DC11}   - Dublin Core 1.1 (DC11) _deprecated_
  # * {RDF::DOAP}   - Description of a Project (DOAP)
  # * {RDF::EXIF}   - Exchangeable Image File Format (EXIF)
  # * {RDF::FOAF}   - Friend of a Friend (FOAF)
  # * {RDF::GEO}    - WGS84 Geo Positioning (GEO)
  # * {RDF::GR}     - Good Relations
  # * {RDF::HT}   - Hypertext Transfer Protocol (HTTP)
  # * {RDF::ICAL}   - iCal
  # * {RDF::MA}     - W3C Meda Annotations
  # * {RDF::OG}     - FaceBook OpenGraph
  # * {RDF::OWL}    - Web Ontology Language (OWL)
  # * {RDF::PROV}   - W3C Provenance Ontology
  # * {RDF::RDFS}   - RDF Schema (RDFS)
  # * {RDF::RSA}    - W3 RSA Keys (RSA)
  # * {RDF::RSS}    - RDF Site Summary (RSS)
  # * {RDF::SCHEMA} - Schema.org
  # * {RDF::SIOC}   - Semantically-Interlinked Online Communities (SIOC)
  # * {RDF::SKOS}   - Simple Knowledge Organization System (SKOS)
  # * {RDF::SKOSXL} - SKOS Simple Knowledge Organization System eXtension for Labels (SKOS-XL)
  # * {RDF::V}      - Data Vocabulary
  # * {RDF::VCARD}  - vCard vocabulary
  # * {RDF::VOID}   - Vocabulary of Interlinked Datasets (VoID)
  # * {RDF::WDRS}   - Protocol for Web Description Resources (POWDER)
  # * {RDF::WOT}    - Web of Trust (WOT)
  # * {RDF::XHTML}  - Extensible HyperText Markup Language (XHTML)
  # * {RDF::XHV}    - W3C XHTML Vocabulary
  # * {RDF::XSD}    - XML Schema (XSD)
  #
  # @example Using pre-defined RDF vocabularies
  #   include RDF
  #
  #   DC.title      #=> RDF::URI("http://purl.org/dc/terms/title")
  #   FOAF.knows    #=> RDF::URI("http://xmlns.com/foaf/0.1/knows")
  #   RDF.type      #=> RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#type")
  #   RDFS.seeAlso  #=> RDF::URI("http://www.w3.org/2000/01/rdf-schema#seeAlso")
  #   RSS.title     #=> RDF::URI("http://purl.org/rss/1.0/title")
  #   OWL.sameAs    #=> RDF::URI("http://www.w3.org/2002/07/owl#sameAs")
  #   XSD.dateTime  #=> RDF::URI("http://www.w3.org/2001/XMLSchema#dateTime")
  #
  # @example Using ad-hoc RDF vocabularies
  #   foaf = RDF::Vocabulary.new("http://xmlns.com/foaf/0.1/")
  #   foaf.knows    #=> RDF::URI("http://xmlns.com/foaf/0.1/knows")
  #   foaf[:name]   #=> RDF::URI("http://xmlns.com/foaf/0.1/name")
  #   foaf['mbox']  #=> RDF::URI("http://xmlns.com/foaf/0.1/mbox")
  #
  # @example Generating RDF from a vocabulary definition
  #   graph = RDF::RDFS.to_graph
  #   graph.dump(:ntriples)
  #
  # @example Defining a simple vocabulary
  #   class EX < RDF::StrictVocabulay("http://example/ns#")
  #     term :Class,
  #       label: "My Class",
  #       comment: "Good to use as an example",
  #       "rdf:type" => "rdfs:Class",
  #       "rdfs:subClassOf" => "http://example/SuperClass"
  #   end
  #
  # @see http://www.w3.org/TR/curie/
  # @see http://en.wikipedia.org/wiki/QName
  class Vocabulary
    extend ::Enumerable

    class << self
      ##
      # Enumerates known RDF vocabulary classes.
      #
      # @yield  [klass]
      # @yieldparam [Class] klass
      # @return [Enumerator]
      def each(&block)
        if self.equal?(Vocabulary)
          # This is needed since all vocabulary classes are defined using
          # Ruby's autoloading facility, meaning that `@@subclasses` will be
          # empty until each subclass has been touched or require'd.
          RDF::VOCABS.each { |v| require "rdf/vocab/#{v}" unless v == :rdf }
          @@subclasses.select(&:name).each(&block)
        else
          __properties__.each(&block)
        end
      end

      ##
      # Is this a strict vocabulary, or a liberal vocabulary allowing arbitrary properties?
      def strict?; false; end

      ##
      # @overload property
      #   Returns `property` in the current vocabulary
      #   @return [RDF::URI]
      #
      # @overload property(name, options)
      #   Defines a new property or class in the vocabulary.
      #
      #   @param [String, #to_s] name
      #   @param [Hash{Symbol => Object}] options
      #     Any other values are expected to be String which expands to a {URI} using built-in vocabulary prefixes. The value is a `String` or `Array<String>` which is interpreted according to the `range` of the associated property.
      #   @option options [String, Array<String>] :label
      #     Shortcut for `rdfs:label`, values are String interpreted as a {Literal}.
      #   @option options [String, Array<String>] :comment
      #     Shortcut for `rdfs:comment`, values are String interpreted as a {Literal}.
      #   @option options [String, Array<String>] :subClassOf
      #     Shortcut for `rdfs:subClassOf`, values are String interpreted as a {URI}.
      #   @option options [String, Array<String>] :subPropertyOf
      #     Shortcut for `rdfs:subPropertyOf`, values are String interpreted as a {URI}.
      #   @option options [String, Array<String>] :domain
      #     Shortcut for `rdfs:domain`, values are String interpreted as a {URI}.
      #   @option options [String, Array<String>] :range
      #     Shortcut for `rdfs:range`, values are String interpreted as a {URI}.
      #   @option options [String, Array<String>] :type
      #     Shortcut for `rdf:type`, values are String interpreted as a {URI}.
      def property(*args)
        case args.length
        when 0
          Term.intern("#{self}property", attributes: {label: "property", vocab: self})
        else
          name, options = args
          options = {:label => name.to_s, vocab: self}.merge(options || {})
          prop = Term.intern([to_s, name.to_s].join(''), attributes: options)
          props[prop] = options
          (class << self; self; end).send(:define_method, name) { prop } unless name.to_s == "property"
        end
      end

      # Alternate use for vocabulary terms, functionally equivalent to {#property}.
      alias_method :term, :property
      alias_method :__property__, :property

      ##
      #  @return [Array<RDF::URI>] a list of properties in the current vocabulary
      def properties
        props.keys
      end
      alias_method :__properties__, :properties

      ##
      # Attempt to expand a Compact IRI/PName/QName using loaded vocabularies
      #
      # @param [String, #to_s] pname
      # @return [RDF::URI]
      def expand_pname(pname)
        prefix, suffix = pname.to_s.split(":", 2)
        if prefix == "rdf"
          RDF[suffix]
        elsif vocab = RDF::Vocabulary.each.detect {|v| v.__name__ && v.__prefix__ == prefix.to_sym}
          suffix.to_s.empty? ? vocab.to_uri : vocab[suffix]
        end
      end

      ##
      # Return the Vocabulary associated with a URI
      #
      # @param [RDF::URI] uri
      # @return [Vocabulary]
      def find(uri)
        RDF::Vocabulary.detect {|v| RDF::URI(uri).start_with?(v)}
      end

      ##
      # Return the Vocabulary term associated with a  URI
      #
      # @param [RDF::URI] uri
      # @return [Vocabulary::Term]
      def find_term(uri)
        uri = RDF::URI(uri)
        return uri if uri.is_a?(Vocabulary::Term)
        vocab = RDF::Vocabulary.detect {|v| uri.start_with?(v)}
        term = vocab[uri.to_s[vocab.to_s.length..-1]] if vocab
      end

      ##
      # Returns the URI for the term `property` in this vocabulary.
      #
      # @param  [#to_s] property
      # @return [RDF::URI]
      def [](property)
        if self.respond_to?(property.to_sym)
          self.send(property.to_sym)
        else
          Term.intern([to_s, property.to_s].join(''), attributes: {vocab: self})
        end
      end

      # @return [String] The label for the named property
      def label_for(name)
        props.fetch(self[name], {}).fetch(:label, "")
      end

      # @return [String] The comment for the named property
      def comment_for(name)
        props.fetch(self[name], {}).fetch(:comment, "")
      end

      ##
      # Returns the base URI for this vocabulary class.
      #
      # @return [RDF::URI]
      def to_uri
        RDF::URI.intern(to_s)
      end

      # For IRI compatibility
      alias_method :to_iri, :to_uri

      ##
      # Return an enumerator over {RDF::Statement} defined for this vocabulary.
      # @return [RDF::Enumerable::Enumerator]
      # @see    Object#enum_for
      def enum_for(method = :each_statement, *args)
        # Ensure that enumerators are, themselves, queryable
        this = self
        Enumerable::Enumerator.new do |yielder|
          this.send(method, *args) {|*y| yielder << (y.length > 1 ? y : y.first)}
        end
      end
      alias_method :to_enum, :enum_for

      ##
      # Enumerate each statement constructed from the defined vocabulary terms
      #
      # If a property value is known to be a {URI}, or expands to a {URI}, the `object` is a URI, otherwise, it will be a {Literal}.
      #
      # @yield statement
      # @yieldparam [RDF::Statement]
      def each_statement(&block)
        props.each do |subject, attributes|
          attributes.each do |prop, values|
            prop = RDF::Vocabulary.expand_pname(prop) unless prop.is_a?(Symbol)
            next unless prop
            Array(values).each do |value|
              case prop
              when :type
                prop = RDF.type
                value = expand_pname(value) || RDF::URI(value)
              when :subClassOf
                prop = RDFS.subClassOf
                value = expand_pname(value) || RDF::URI(value)
              when :subPropertyOf
                prop = RDFS.subPropertyOf
                value = expand_pname(value) || RDF::URI(value)
              when :domain
                prop = RDFS.domain
                value = expand_pname(value) || RDF::URI(value)
              when :range
                prop = RDFS.range
                value = expand_pname(value) || RDF::URI(value)
              when :label
                prop = RDFS.label
              when :comment
                prop = RDFS.comment
              else
                value = RDF::Vocabulary.expand_pname(value) || value
              end

              block.call RDF::Statement(subject, prop, value)
            end
          end
        end
      end

      ##
      # Returns a string representation of this vocabulary class.
      #
      # @return [String]
      def to_s
        @@uris.has_key?(self) ? @@uris[self].to_s : super
      end

      ##
      # Load a vocabulary, optionally from a separate location.
      #
      # @param [URI, #to_s] uri
      # @param [Hash{Symbol => Object}] options
      # @option options [String] class_name
      #   The class_name associated with the vocabulary, used for creating the class name of the vocabulary. This will create a new class named with a top-level constant based on `class_name`.
      # @option options [URI, #to_s] :location
      #   Location from which to load the vocabulary, if not from `uri`.
      # @option options [Array<Symbol>, Hash{Symbol => Hash}] :extra
      #   Extra terms to add to the vocabulary. In the first form, it is an array of symbols, for which terms are created. In the second, it is a Hash mapping symbols to property attributes, as described in {#property}.
      # @return [RDF::Vocabulary] the loaded vocabulary
      def load(uri, options = {})
        source = options.fetch(:location, uri)
        class_name = options[:class_name]
        vocab = if class_name
          Object.const_set(class_name, Class.new(self.create(uri)))
        else
          Class.new(self.create(uri))
        end

        graph = RDF::Graph.load(source)
        term_defs = {}
        graph.each do |statement|
          next unless statement.subject.uri? && statement.subject.start_with?(uri)
          name = statement.subject.to_s[uri.to_s.length..-1] 
          term = (term_defs[name.to_sym] ||= {})
          key = case statement.predicate
          when RDF.type                then :type
          when RDF::RDFS.subClassOf    then :subClassOf
          when RDF::RDFS.subPropertyOf then :subPropertyOf
          when RDF::RDFS.range         then :range
          when RDF::RDFS.domain        then :domain
          when RDF::RDFS.comment       then :comment
          when RDF::RDFS.label         then :label
          else                         statement.predicate.pname
          end

          value = if statement.object.uri?
            statement.object.pname
          elsif statement.object.literal? && (statement.object.language || :en) == :en
            statement.object.to_s
          end

          (term[key] ||= []) << value if value
        end

        # Create extra terms
        term_defs = case options[:extra]
        when Array
          options[:extra].inject({}) {|memo, s| memo[s.to_sym] = {label: s.to_s}; memo}.merge(term_defs)
        when Hash
          options[:extra].merge(term_defs)
        else
          term_defs
        end

        # Create each term
        term_defs.each do |term, attributes|
          vocab.term term, attributes
        end

        vocab
      end

      ##
      # Returns a developer-friendly representation of this vocabulary class.
      #
      # @return [String]
      def inspect
        if self == Vocabulary
          self.to_s
        else
          sprintf("%s(%s)", superclass.to_s, to_s)
        end
      end

      # Preserve the class name so that it can be obtained even for
      # vocabularies that define a `name` property:
      alias_method :__name__, :name

      ##
      # Returns a suggested CURIE/PName prefix for this vocabulary class.
      #
      # @return [Symbol]
      # @since  0.3.0
      def __prefix__
        __name__.split('::').last.downcase.to_sym
      end

    protected
      def inherited(subclass) # @private
        unless @@uri.nil?
          @@subclasses << subclass #unless subclass == ::RDF::RDF
          subclass.send(:private_class_method, :new)
          @@uris[subclass] = @@uri
          @@uri = nil
        end
        super
      end

      def method_missing(property, *args, &block)
        if %w(to_ary).include?(property.to_s)
          super
        elsif args.empty? && !to_s.empty?
          Term.intern([to_s, property.to_s].join(''), attributes: {vocab: self})
        else
          super
        end
      end

    private
      def props; @properties ||= {}; end
    end

    # Undefine all superfluous instance methods:
    undef_method(*instance_methods.
                  map(&:to_s).
                  select {|m| m =~ /^\w+$/}.
                  reject {|m| %w(object_id dup instance_eval inspect to_s class).include?(m) || m[0,2] == '__'}.
                  map(&:to_sym))

    ##
    # @param  [RDF::URI, String, #to_s] uri
    def initialize(uri)
      @uri = case uri
        when RDF::URI then uri.to_s
        else RDF::URI.parse(uri.to_s) ? uri.to_s : nil
      end
    end

    ##
    # Returns the URI for the term `property` in this vocabulary.
    #
    # @param  [#to_s] property
    # @return [URI]
    def [](property)
      Term.intern([to_s, property.to_s].join(''), attributes: {vocab: self.class})
    end

    ##
    # Returns the base URI for this vocabulary.
    #
    # @return [URI]
    def to_uri
      RDF::URI.intern(to_s)
    end

    # For IRI compatibility
    alias_method :to_iri, :to_uri

    ##
    # Returns a string representation of this vocabulary.
    #
    # @return [String]
    def to_s
      @uri.to_s
    end

    ##
    # Returns a developer-friendly representation of this vocabulary.
    #
    # @return [String]
    def inspect
      sprintf("#<%s:%#0x(%s)>", self.class.name, __id__, to_s)
    end

  protected

    def self.create(uri) # @private
      @@uri = uri
      self
    end

    def method_missing(property, *args, &block)
      if %w(to_ary).include?(property.to_s)
        super
      elsif args.empty?
        self[property]
      else
        super
      end
    end

  private

    @@subclasses = [::RDF] # @private
    @@uris       = {}      # @private
    @@uri        = nil     # @private

    # A Vocabulary Term is a URI that can also act as an {Enumerable} to generate the RDF definition of vocabulary terms as defined within the vocabulary definition.
    class Term < RDF::URI
      # Attributes of this vocabulary term, used for finding `label` and `comment` and to serialize the term back to RDF.
      # @return [Hash{Symbol,Resource => Term, #to_s}]
      attr_accessor :attributes

      ##
      # @overload URI(uri, options = {})
      #   @param  [URI, String, #to_s]    uri
      #   @param  [Hash{Symbol => Object}] options
      #   @option options [Boolean] :validate (false)
      #   @option options [Boolean] :canonicalize (false)
      #   @option options [Hash{Symbol,Resource => Term, #to_s}] :attributes
      #     Attributes of this vocabulary term, used for finding `label` and `comment` and to serialize the term back to RDF
      #
      # @overload URI(options = {})
      #   @param  [Hash{Symbol => Object}] options
      #   @option options [Boolean] :validate (false)
      #   @option options [Boolean] :canonicalize (false)
      #   @option [Vocabulary] :vocab The {Vocabulary} associated with this term.
      #   @option [String, #to_s] :scheme The scheme component.
      #   @option [String, #to_s] :user The user component.
      #   @option [String, #to_s] :password The password component.
      #   @option [String, #to_s] :userinfo
      #     The userinfo component. If this is supplied, the user and password
      #     components must be omitted.
      #   @option [String, #to_s] :host The host component.
      #   @option [String, #to_s] :port The port component.
      #   @option [String, #to_s] :authority
      #     The authority component. If this is supplied, the user, password,
      #     userinfo, host, and port components must be omitted.
      #   @option [String, #to_s] :path The path component.
      #   @option [String, #to_s] :query The query component.
      #   @option [String, #to_s] :fragment The fragment component.
      #   @option options [Hash{Symbol,Resource => Term, #to_s}] :attributes
      #     Attributes of this vocabulary term, used for finding `label` and `comment` and to serialize the term back to RDF
      def initialize(*args)
        options = args.last.is_a?(Hash) ? args.last : {}
        @attributes = options.fetch(:attributes)
        super
      end

      ##
      # Vocabulary of this term.
      #
      # @return [RDF::Vocabulary]
      def vocab; @attributes.fetch(:vocab); end

      ##
      # Returns a duplicate copy of `self`.
      #
      # @return [RDF::URI]
      def dup
        self.class.new((@value || @object).dup, attributes: @attributes)
      end

      ##
      # Determine if the URI is a valid according to RFC3987
      #
      # @return [Boolean] `true` or `false`
      # @since 0.3.9
      def valid?
        # Validate relative to RFC3987
        to_s.match(RDF::URI::IRI) || false
      end

      ##
      # Is this a class term?
      # @return [Boolean]
      def class?
        !!(self.type.to_s =~ /Class/)
      end

      ##
      # Is this a class term?
      # @return [Boolean]
      def property?
        !!(self.type.to_s =~ /Property/)
      end

      ##
      # Is this a class term?
      # @return [Boolean]
      def datatype?
        !!(self.type.to_s =~ /Datatype/)
      end

      ##
      # Is this neither a class, property or datatype term?
      # @return [Boolean]
      def other?
        !!(self.type.to_s !~ /(Class|Property|Datatype)/)
      end

      ##
      # Returns a <code>String</code> representation of the URI object's state.
      #
      # @return [String] The URI object's state, as a <code>String</code>.
      def inspect
        sprintf("#<%s:%#0x URI:%s>", Term.to_s, self.object_id, self.to_s)
      end

      # Implement accessor to symbol attributes
      def respond_to?(method)
        @attributes.has_key?(method) || super
      end

    protected
      # Implement accessor to symbol attributes
      def method_missing(method, *args, &block)
        case method
        when :comment
          @attributes.fetch(method, "")
        when :label
          @attributes.fetch(method, to_s.split(/[\/\#]/).last)
        when :type, :subClassOf, :subPropertyOf, :domain, :range
          case @attributes[method]
          when Array
            @attributes[method].each {|v| RDF::Vocabulary.expand_pname(v)}
          when nil
            nil
          else
            RDF::Vocabulary.expand_pname(@attributes[method])
          end
        else
          super
        end
      end
    end
  end # Vocabulary

  # Represents an RDF Vocabulary. The difference from {RDF::Vocabulary} is that
  # that every concept in the vocabulary is required to be declared. To assist
  # in this, an existing RDF representation of the vocabulary can be loaded as
  # the basis for concepts being available
  class StrictVocabulary < Vocabulary
    class << self
      # Redefines method_missing to the original definition
      # By remaining a subclass of Vocabulary, we remain available to
      # Vocabulary::each etc.
      define_method(:method_missing, BasicObject.instance_method(:method_missing))

      ##
      # Is this a strict vocabulary, or a liberal vocabulary allowing arbitrary properties?
      def strict?; true; end

      def [](name)
        prop = super
        props.fetch(prop) #raises KeyError on missing value
        return prop
      end
    end
  end # StrictVocabulary
end # RDF
