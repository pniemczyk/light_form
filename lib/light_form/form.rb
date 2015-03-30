require 'active_model'

module LightForm
  class Form
    include ActiveModel::Model
    include PropertyMethods

    def initialize(params = {})
      super(_prepare_params(params))
    end
  end
end
