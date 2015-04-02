# LightForm

Build form from specific params and custom validation

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'light_form'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install light_form

## How it works
Build form from specific params and custom validation:

```ruby
class Address
  include ActiveModel::Model
  attr_accessor :street, :post_code
end

class Child
  include ActiveModel::Model
  attr_accessor :name, :age
end

class PersonForm < LightForm::Form
  properties :title, :first_name, :last_name
  property :email, validates: { presence: true }
  property :age, with: -> (v) { v.to_i }

  property :address, model: Address do
    properties :street, :post_code
  end

  property :children, collection: Child, uniq: true do
    property :name, validates: { presence: true }
    property :age, with: -> (v) { v.to_i }
  end

  property :interests, collection: true, uniq: true
end

person = PersonForm.new(
  {
    title: 'Mr', first_name: 'Pawel', last_name: 'Awesome', email: nil,
    age: '31', address: { street: 'Best', post_code: '33333' },
    children: [ {name: 'Emi', age: '2'}, {name: 'Emi', age: '2'}, {age: '2'} ],
    interests: [ 'football', 'football', 'basketball', 'football' ]
  }
)

person.valid? == false

person.errors.as_json == {
  children: [{1=>{name: ["can't be blank"]}}],
  email: ["can't be blank"]
}

person.to_h == {
  title: 'Mr',
  first_name: 'Pawel',
  last_name: 'Awesome',
  email: nil,
  age: 31,
  address: <AddressModel:0x007faf0ba22238 @street='Best', @post_code='33333'>,
  children: [<ChildModel:0x007faf0ba21ec8 @name='Emi', @age=2>, <ChildModel:0x007faf0ba21c70 @name='', @age=2>],
  interests: ['football', 'basketball']
}
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/light_form/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
