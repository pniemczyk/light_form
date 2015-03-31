require 'set'

module LightForm
  module PropertyMethods
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def config
        @config ||= {}
      end

      def properties(*prop_names)
        add_property = method(:_add_property)
        prop_names.each(&add_property)
      end

      def property(prop_name, options = {}, &block)
        _add_property(prop_name)
        _add_property_transform(prop_name, options)
        _add_property_validation(prop_name, options[:validates]) if options[:validates]
        _add_property_source(prop_name, &block) if block
      end

      private

      def _add_property_source(prop_name, &block)
        klass = Class.new(Lash)
        klass.class_eval(&block)
        _properties_sources[prop_name] = klass
      end

      def _properties_sources
        config[:properties_sources] ||= {}
      end

      def _properties_transform
        config[:properties_transform] ||= {}
      end

      def _properties
        config[:properties] ||= Set.new
      end

      def _add_property_transform(prop_name, options = {})
        transformations = options.slice(:from, :transform_with, :with, :default, :model, :collection, :uniq)
        return if transformations.empty?
        _properties_transform[prop_name] = transformations
      end

      def _add_property(prop_name)
        config[:errors_overriden] = true if prop_name == :errors
        send(:attr_accessor, prop_name)  if _properties.add?(prop_name)
      end

      def _add_property_validation(prop_name, validation)
        validates(prop_name, validation)
      end
    end

    def _errors
      @_errors
    end

    def errors_overriden?
      self.class.config[:errors_overriden] == true
    end

    def valid?
      return super unless errors_overriden?
      @_errors = @errors
      @errors  = ActiveModel::Errors.new(self)
      stored_method = method(:errors)
      errors_method = -> { @errors }
      define_singleton_method(:errors) { errors_method.call }
      result, store, @_errors, @errors = super, @_errors, @errors, store
      define_singleton_method(:errors) { stored_method.call }
      result
    end

    private

    def _prepare_params(value)
      params = value.clone
      properties = self.class.config[:properties] || []
      return params if properties.empty?
      _prepare_params_keys_and_values!(params)
      _prepare_sources(params)
      params.extract!(*properties)
    end

    def _prepare_params_keys_and_values!(params)
      properties_from = self.class.config[:properties_transform] || {}
      properties_from.clone.each do |key_to, hash|
        _update_key!(params, key_to, hash)
        set_default = (params[key_to].nil? || params[key_to].empty?) && hash[:default]
        _update_value_as_default!(params, key_to, hash) if set_default
        _transform_value!(params, key_to, hash) unless set_default
        _modelable_value!(params, key_to, hash)
        _collectionaize_value!(params, key_to, hash)
      end
    end

    def _update_key!(params, key, hash)
      params[key] = params.delete(hash[:from]) if hash[:from]
    end

    def _update_value_as_default!(params, key, hash)
      params[key] = hash[:default]
    end

    def _transform_value!(params, key, hash)
      transformation = hash[:with] || hash[:transform_with]
      return unless transformation
      trans_proc  = transformation.is_a?(Symbol) ? method(transformation) : transformation
      params[key] = trans_proc.call(params[key])
    end

    def _modelable_value!(params, key, hash)
      return unless hash[:model]
      params[key] = hash[:model].new(params[key])
    end

    def _collectionaize_value!(params, key, hash)
      return unless hash[:collection]
      array = params[key]
      fail("#{self.class}: #{key} is not collection") unless array.is_a? Array
      array.uniq! if hash[:uniq]
      return params[key] = array if hash[:collection] == true
      params[key] = array.compact.map { |source| hash[:collection].new(source) }
    end

    def _prepare_sources(params)
      (self.class.config[:properties_sources] || {}).each do |k, v|
        params[k] = v.new(params[k])
      end
    end
  end
end
