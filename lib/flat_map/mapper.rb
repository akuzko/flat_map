module FlatMap
  # == Mapper
  #
  # FlatMap mappers are designed to provide complex set of data, distributed over
  # associated AR models, in the simple form of a plain hash. They accept a plain
  # hash of the same format and distribute its values over deeply nested AR models.
  #
  # To achieve this goal, Mapper uses three major concepts: Mappings, Mountings and
  # Traits.
  #
  # === Mappings
  #
  # Mappings are defined view Mapper.map method. They represent a simple one-to-one
  # relation between target attribute and a mapper, extended by additional features
  # for convenience. The best way to show how they work is by example:
  #
  #   class CustomerMapper < FlatMap::Mapper
  #     # When there is no need to rename attributes, they can be passed as array:
  #     map :first_name, :last_name
  #
  #     # When hash is used, it will map field name to attribute name:
  #     map :dob => :date_of_birth
  #
  #     # Also, additional options can be used:
  #     map :name_suffix, :format => :enum
  #     map :password, :reader => false, :writer => :assign_password
  #
  #     # Or you can combine all definitions together if they all are common:
  #     map :first_name, :last_name,
  #         :dob    => :date_of_birth,
  #         :suffix => :name_suffix,
  #         :reader => :my_custom_reader
  #   end
  #
  # When mappings are defined, one can read and write values using them:
  #
  #   mapper = CustomerMapper.find(1)
  #   mapper.read          # => {:first_name => 'John', :last_name => 'Smith', :dob => '02/01/1970'}
  #   mapper.write(params) # will assign same-looking hash of arguments
  #
  # Following options may be used when defining mappings:
  # [<tt>:format</tt>] Allows to additionally process output value on reading it. All formats are
  #                    defined within FlatMap::Mapping::Reader::Formatted::Formats and
  #                    specify the actual output of the mapping
  # [<tt>:reader</tt>] Allows you to manually control reader value of a mapping, or a group of
  #                    mappings listed on definition. When String or Symbol is used, will call
  #                    a method, defined by mapper class, and pass mapping object to it. When
  #                    lambda is used, mapper's target (the model) will be passed to it.
  # [<tt>:writer</tt>] Just like with the :reader option, allows to control how value is assigned
  #                    (written). Works the same way as :reader does, but additionally value is
  #                    sent to both mapper method and lambda.
  # [<tt>:multiparam</tt>] If used, multiparam attributes will be extracted from params, when
  #                        those are passed for writing. Class should be passed as a value for
  #                        this option. Object of this class will be initialized with the arguments
  #                        extracted from params hash.
  #
  # === Mountings
  #
  # Mappers may be mounted on top of each other. This ability allows host mapper to gain all the
  # mappings of the mounted mapper, thus providing more information for external usage (both reading
  # and writing). Usually, target for mounted mapper may be obtained from association of target of
  # the host mapper itself, but may be defined manually.
  #
  #   class CustomerMapper < FlatMap::Mapper
  #     map :first_name, :last_name
  #   end
  #
  #   class CustomerAccountMapper < FlatMap::Mapper
  #     map :source, :brand, :format => :enum
  #
  #     mount :customer
  #   end
  #
  #   mapper = CustomerAccountMapper.find(1)
  #   mapper.read # => {:first_name => 'John', :last_name => 'Smith', :source => nil, :brand => 'TLP'}
  #   mapper.write(params) # Will assign params for both CustomerAccount and Customer records
  #
  # The following options may be used when mounting a mapper:
  # [<tt>:mapper_class</tt>] Specifies mapper class if it cannot be determined from mounting itself
  # [<tt>:target</tt>] Allows to manually specify target for the new mapper. May be oject or lambda
  #                    with arity of one that accepts host mapper target as argument. Comes in handy
  #                    when target cannot be obviously detected or requires additional setup:
  #                    <tt>mount :title, :target => lambda{ |customer| customer.title_customers.build.build_title }</tt>
  # [<tt>:mounting_point</tt>] Deprecated option name for :target
  # [<tt>:traits</tt>] Specifies list of traits to be used by mounted mapper
  # [<tt>:suffix</tt>] Specifies the suffix that will be appended to all mappings and mountings of mapper,
  #                    as well as mapper name itself.
  #
  # === Traits
  #
  # Traits allow mappers to encapsulate named sets of additional definitions, and use them optionally
  # on mapper initialization. Everything that can be defined within the mapper may be defined within
  # the trait. In fact, from the implementation perspective traits are mappers themselves that are
  # mounted on the host mapper.
  #
  #   class CustomerAccountMapper < FlatMap::Mapper
  #     map :brand, :format => :enum
  #
  #     trait :with_email do
  #       map :source, :format => :enum
  #
  #       mount :email_address
  #
  #       trait :with_email_phones_residence do
  #         mount :customer, :traits => [:with_phone_numbers, :with_residence]
  #       end
  #     end
  #   end
  #
  #   CustomerAccountMapper.find(1).read # => {:brand => 'TLP'}
  #   CustomerAccountMapper.find(1, :with_email).read # => {:brand => 'TLP', :source => nil, :email_address => 'j.smith@gmail.com'}
  #   CustomerAccountMapper.find(1, :with_email_phone_residence).read # => :brand, :source, :email_address, phone numbers,
  #                                    #:residence attributes - all will be available for reading and writing in plain hash
  #
  # === Extensions
  #
  # When mounting a mapper, one can pass an optional block. This block is used as an extension for a mounted
  # mapper and acts as an anonymous trait. For example:
  #
  #   class CustomerAccountMapper < FlatMap::Mapper
  #     mount :customer do
  #       map :dob => :date_of_birth, :format => :i18n_l
  #       validates_presence_of :dob
  #
  #       mount :unique_identifier
  #       mount :drivers_license, :traits => :person_name_with_callback
  #
  #       validates_acceptance_of :esign_consent, :message => "You must check this box to continue"
  #     end
  #   end
  #
  # === Validation
  #
  # <tt>FlatMap::Mapper</tt> includes <tt>ActiveModel::Validations</tt> module, allowing each model to
  # perform its own validation routines before trying to save its target (which is usually AR model). Mapper
  # validation is very handy when mappers are used with Rails forms, since there no need to lookup for a
  # deeply nested errors hash of the AR models to extract error messages. Mapper validations will attach
  # messages to mapping names.
  #
  # Mapper validations become even more useful when used within traits, providing way of very flexible validation sets.
  #
  # === Callbacks
  #
  # Since mappers include <tt>ActiveModel::Validation</tt>, they already support ActiveSupport's callbacks.
  # Additionally, <tt>:save</tt> callbacks have been defined (i.e. there have been define_callbacks <tt>:save</tt>
  # call for <tt>FlatMap::Mapper</tt>). This allows you to control flow of mapper saving:
  #
  #   set_callback :save, :before, :set_model_validation
  #
  #   def set_model_validation
  #     target.use_validation :some_themis_validation
  #   end
  #
  # === Skipping
  #
  # In some cases, it is required to omit mapper processing after it has been created within mounting chain. If
  # <tt>skip!</tt> method is called on mapper, it will return <tt>true</tt> for <tt>valid?</tt> and <tt>save</tt>
  # method calls without performing any other operations. For example:
  #
  #   class CustomerAccountMapper < FlatMap::Mapper
  #     self.target_class_name = 'CustomerAccount::Active'
  #
  #     # some definitions
  #
  #     trait :with_bank_account_selection do
  #       attr_reader :selected_bank_account_id
  #
  #       mount :bank_account
  #
  #       set_callback :validate, :before, :ignore_new_bank_account
  #       set_callback :save, :after, :update_application
  #
  #       def ignore_new_bank_account
  #         mounting(:bank_account).skip! if bank_account_selected?
  #       end
  #
  #       # some more definitions
  #     end
  #   end
  #
  # === Attribute Methods
  #
  # All mappers have the ability to read and write values via method calls:
  #
  #   mapper.read[:first_name] # => John
  #   mapper.first_name # => 'John'
  #   mapper.last_name = 'Smith'
  class Mapper
    # Raised when mapper is initialized with no target defined
    class NoTargetError < ArgumentError
      # Initializes exception with a describing message for +mapper+
      #
      # @param [FlatMap::Mapper] mapper
      def initialize(mapper)
        super("Target object is required to initialize mapper #{mapper.inspect}")
      end
    end

    extend ActiveSupport::Autoload

    autoload :Mapping
    autoload :Mounting
    autoload :Traits
    autoload :Factory
    autoload :AttributeMethods
    autoload :ModelMethods
    autoload :Skipping

    include Mapping
    include Mounting
    include Traits
    include AttributeMethods
    include ActiveModel::Validations
    include ModelMethods
    include Skipping
    include Skipping::ActiveRecord

    attr_writer :host, :suffix
    attr_reader :target, :traits
    attr_accessor :owner, :name

    delegate :logger, :to => :target

    # Callback to dup mappings and mountings on inheritance.
    # The values are cloned from actual mappers (i.e. something
    # like CustomerAccountMapper, since it is useless to clone
    # empty values of FlatMap::Mapper).
    #
    # Note: those class attributes are defined in {Mapping}
    # and {Mounting} modules.
    def self.inherited(subclass)
      return unless self < FlatMap::Mapper
      subclass.mappings  = mappings.dup
      subclass.mountings = mountings.dup
    end

    # Initializes +mapper+ with +target+ and +traits+, which are
    # used to fetch proper list of mounted mappers. Raises error
    # if target is not specified.
    #
    # @param [Object] target Target of mapping
    # @param [*Symbol] traits List of traits
    # @raise [FlatMap::Mapper::NoTargetError]
    def initialize(target, *traits)
      raise NoTargetError.new(self) unless target.present?

      @target, @traits = target, traits

      if block_given?
        singleton_class.trait :extension, &Proc.new
      end
    end

    # Return a simple string representation of +mapper+. Done so to
    # avoid really long inspection of internal objects (target -
    # usually AR model, mountings and mappings)
    # @return [String]
    def inspect
      to_s
    end

    # Return +true+ if +mapper+ is owned. This means that current
    # mapper is actually a trait. Thus, it is a part of an owner
    # mapper.
    #
    # @return [Boolean]
    def owned?
      owner.present?
    end

    # If mapper was mounted by another mapper, host is the one who
    # mounted +self+.
    #
    # @return [FlatMap::Mapper]
    def host
      owned? ? owner.host : @host
    end

    # Return +true+ if mapper is hosted, i.e. it is mounted by another
    # mapper.
    #
    # @return [Boolean]
    def hosted?
      host.present?
    end

    # +suffix+ reader. Delegated to owner for owned mappers.
    #
    # @return [String, nil]
    def suffix
      owned? ? owner.suffix : @suffix
    end

    # Return +true+ if +suffix+ is present.
    #
    # @return [Boolean]
    def suffixed?
      suffix.present?
    end
  end
end