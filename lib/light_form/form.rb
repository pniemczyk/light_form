require 'set'
require 'active_model'

module LightForm
  class Form
    include ActiveModel::Model

    def initialize(params = {})
      super(_prepare_params(params))
    end

    class << self
      def config
        @config ||= {}
      end

      def properties(*prop_names)
        add_property = method(:_add_property)
        prop_names.each(&add_property)
      end

      def property(prop_name, options = {}, &_block)
        _add_property(prop_name)
        _add_property_transform(prop_name, options)
        _add_property_validation(prop_name, options[:validates]) if options[:validates]
      end

      private

      def _properties_transform
        config[:properties_transform] ||= {}
      end

      def _properties
        config[:properties] ||= Set.new
      end

      def _add_property_transform(prop_name, options = {})
        transformations = options.slice(:from, :transform_with, :default)
        return if transformations.empty?
        _properties_transform[prop_name] = transformations
      end

      def _add_property(prop_name)
        send(:attr_accessor, prop_name) if _properties.add?(prop_name)
      end

      def _add_property_validation(prop_name, validation)
        validates(prop_name, validation)
      end
    end

    private

    def _prepare_params(value)
      params = value.clone
      _prepare_params_keys_and_values!(params)
      properties = self.class.config[:properties] || []
      params.extract!(*properties)
    end

    def _prepare_params_keys_and_values!(params)
      properties_from = self.class.config[:properties_transform] || {}
      properties_from.each do |key_to, hash|
        params[key_to] = params.delete(hash[:from]) if hash[:from]
        next params[key_to] = hash[:default] if params[key_to].empty? && hash[:default]
        next unless hash[:transform_with]
        transformation = hash[:transform_with]
        trans_proc     = transformation.is_a?(Symbol) ? method(transformation) : transformation
        params[key_to] = trans_proc.call(params[key_to])
      end
    end
  end
end
