require 'active_model'

module LightForm
  class Form
    include ActiveModel::Model
    include ActiveModel::Serializers::JSON
    include PropertyMethods

    def initialize(params = {})
      super(_prepare_params(params))
    end

    def to_h(*args)
      as_json(*args)
    end
  end
end
