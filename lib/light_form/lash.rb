require 'active_model'

module LightForm
  class Lash < Hash
    include ActiveModel::Model
    include PropertyMethods

    def initialize(params = {})
      _prepare_params(params).each_pair { |k, v| self[k.to_sym] = v }
    end

    def self._add_property(prop_name)
      config[:errors_overriden] = true if prop_name == :errors
      return unless _properties.add?(prop_name)
      define_method(prop_name) { |&block| self.[](prop_name, &block) }
      property_assignment = "#{prop_name}=".to_sym
      define_method(property_assignment) { |value| self.[]=(prop_name, value) }
    end
  end
end
