module Core
  module FlatMap
    # This module allows mappers to return and assign values via method calls
    # which names correspond to names of mappings defined within the mapper.
    #
    # This methods are defined within anonymous module that will extend
    # mapper on first usage of this methods.
    module Mapper::AttributeMethods
      # Lazily define reader and writer methods for all mappings available
      # to the mapper, and extend +self+ with it.
      def method_missing(name, *args, &block)
        return super if @attribute_methods_defined

        mappings = all_mappings
        valid_names = mappings.map{ |m| [m.name, "#{m.name}=".to_sym] }.flatten

        return super unless valid_names.include?(name)

        extend attribute_methods(mappings)
        @attribute_methods_defined = true
        send(name, *args, &block)
      end

      # Define anonymous module with reader and writer methods for
      # all the +mappings+ being passed
      #
      # @param [Array<Core::FlatMap::Mapping>] mappings list of mappings
      # @return [Module] module with method definitions
      def attribute_methods(mappings)
        Module.new do
          mappings.each do |mapping|
            define_method(mapping.name){ mapping.read }

            define_method("#{mapping.name}=") do |value|
              mapping.write(value)
            end
          end
        end
      end
      private :attribute_methods
    end
  end
end