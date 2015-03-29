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
        prop_names.each(&method(:_add_property))
      end

      def property(prop_name, _options = {}, &_block)
        _add_property(prop_name)
      end

      def _add_property(prop_name)
        send(:attr_accessor, prop_name) if config[:properties].add?(prop_name)
      rescue NoMethodError
        raise if config[:properties]
        config[:properties] = Set.new
        config[:properties].add(prop_name)
        send(:attr_accessor, prop_name)
      end
    end

    private

    def _prepare_params(params)
      properties = self.class.config[:properties] || []
      params.clone.extract!(*properties)
    end
  end
end
