require 'set'
require 'active_support'

module LightForm
  TransformationError    = Class.new(StandardError)
  MissingCollectionError = Class.new(StandardError)
  MissingParamError      = Class.new(StandardError)

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
        klass.class_eval("def self.name; \"#{ActiveSupport::Inflector.classify(prop_name)}\"; end")
        klass.class_eval(&block)
        _properties_sources[prop_name] = { class: klass }
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
        transformations = options.slice(:from, :transform_with, :with, :default, :model, :collection, :uniq, :required)
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
      return (_check_validation && super) unless errors_overriden?
      @_errors = @errors
      @errors  = ActiveModel::Errors.new(self)
      stored_method = method(:errors)
      errors_method = -> { @errors }
      define_singleton_method(:errors) { errors_method.call }
      result, store, @_errors, @errors = (_check_validation && super), @_errors, @errors, store
      define_singleton_method(:errors) { stored_method.call }
      result
    end

    private

    def _validation_errors(obj)
      obj.errors if obj.respond_to?(:valid?) && !obj.valid?
    end

    def _check_validation
      @errors = ActiveModel::Errors.new(self)
      properties = _properties.delete(_properties_sources.keys)
      properties.each do |prop|
        public_send(prop).tap do |subject|
          items = subject.is_a?(Array) ? subject.map(&method(:_validation_errors)).compact : _validation_errors(subject)
          @errors.add(prop, items) if items && !items.empty?
        end
      end
      _properties_sources.each do |prop, v|
        next unless v[:params]
        subject = v[:params].clone
        items = subject.is_a?(Array) ? subject.map(&method(:_validation_errors)) : _validation_errors(v[:params])
        @errors.add(prop, items) if items && !items.empty?
      end
      @errors.empty?
    end

    def _properties_sources
      @_properties_sources ||= self.class.config[:properties_sources] || {}
    end

    def _properties
      @_properties ||= self.class.config[:properties] || []
    end

    def _prepare_params(value)
      return if value.nil?
      params = value.clone
      return params if _properties.empty?
      _prepare_sources(params)
      _prepare_params_keys_and_values!(params)
      params.extract!(*_properties)
    end

    def _prepare_params_keys_and_values!(params)
      properties_from = self.class.config[:properties_transform] || {}
      properties_from.clone.each do |key_to, hash|
        _update_key!(params, key_to, hash)
        fail(MissingParamError, key_to.to_s) if hash[:required] && !params.key?(key_to)
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
    rescue => e
      raise TransformationError, "key #{key}: #{e.message}"
    end

    def _modelable_value!(params, key, hash)
      return unless hash[:model]
      _save_source_params(key, params[key])
      params[key] = hash[:model].new(params[key])
    end

    def _save_source_params(key, params)
      _properties_sources[key][:params] = params.clone if _properties_sources[key]
    end

    def _collectionaize_value!(params, key, hash)
      return unless hash[:collection]
      array = params[key]
      fail(MissingCollectionError, "on key: #{key}") unless array.is_a? Array
      array.uniq! if hash[:uniq]
      return params[key] = array if hash[:collection] == true
      _save_source_params(key, array.compact)
      params[key] = array.compact.map { |source| hash[:collection].new(source) }
    end

    def _prepare_sources(params)
      _properties_sources.each do |k, v|
        next unless params[k]
        params[k] = params[k].is_a?(Array) ? params[k].map { |s| v[:class].new(s) } : v[:class].new(params[k])
      end
    end
  end
end
