describe LightForm::Form do
  class ChildModel
    include ActiveModel::Model
    attr_accessor :name, :age
    def equality_state
      [:name, :age].map { |attr| public_send("#{attr}") }
    end

    def ==(other)
      eql?(other)
    end

    def eql?(other)
      other.class == self.class && other.equality_state == equality_state
    end
  end


  class AddressModel
    include ActiveModel::Model
    attr_accessor :street, :post_code

    def equality_state
      [:street, :post_code].map { |attr| public_send("#{attr}") }
    end

    def ==(other)
      eql?(other)
    end

    def eql?(other)
      other.class == self.class && other.equality_state == equality_state
    end
  end

  context '.properties' do
    subject do
      class_factory do
        properties :ab, :cd
        properties :cd, :ef
      end
    end

    it 'add attributes' do
      instance = subject.new(ab: 'ab', cd: 'cd', ef: 'ef', skip: 'this')
      expect(instance.ab).to eq('ab')
      expect(instance.cd).to eq('cd')
      expect(instance.ef).to eq('ef')
      expect { instance.skip }.to raise_error(NoMethodError)
    end
  end

  context 'property' do
    context 'add' do
      it 'new property' do
        test_obj = object_factory(attributes: { ab: 'ab', cd: 'cd', skip: 'this' }) do
          property :ab
          property :cd
        end

        expect(test_obj.ab).to eq('ab')
        expect(test_obj.cd).to eq('cd')
        expect { test_obj.skip }.to raise_error(NoMethodError)
      end
    end

    context 'with options' do
      context 'add with :from option' do
        subject do
          object_factory(attributes: { aB: 'ab' }) do
            property :ab, from: :aB
          end
        end

        it 'assign property value from key provided by :from option' do
          expect(subject.ab).to eq('ab')
        end
      end

      context 'add with :default option' do
        subject do
          object_factory(attributes: { ab: '' }) do
            property :ab, default: 'Default'
          end
        end

        it 'assign property value from key provided by :default option when value is empty' do
          expect(subject.ab).to eq('Default')
        end
      end

      context 'add with :default and :transform_with option' do
        let(:time) { Time.parse('2015-03-29 14:41:28 +0200') }
        subject do
          object_factory(attributes: { time: '' }) do
            property :time, default: Time.parse('2015-03-29 14:41:28 +0200'), transform_with: -> (v) { Time.parse(v) }
          end
        end

        it 'assign property value from key :default when value is empty and skip :transform_with' do
          expect(subject.time).to eq(time)
        end
      end

      context 'add with :default and :with option' do
        let(:time) { Time.parse('2015-03-29 14:41:28 +0200') }
        subject do
          object_factory(attributes: { time: '' }) do
            property :time, default: Time.parse('2015-03-29 14:41:28 +0200'), with: -> (v) { Time.parse(v) }
          end
        end

        it 'assign property value from key :default when value is empty and skip :transform_with' do
          expect(subject.time).to eq(time)
        end
      end

      context 'add with :transform_with option assign property value after transformation' do
        it 'by proc' do
          test_obj = object_factory(attributes: { number: '12' }) do
            property :number, transform_with: -> (v) { v.to_i }
          end

          expect(test_obj.number).to eq(12)
        end

        it 'by method' do
          test_obj = object_factory(attributes: { number: '12' }) do
            property :number, transform_with: :convert_to_number

            def convert_to_number(value)
              value.to_i
            end
          end

          expect(test_obj.number).to eq(12)
        end
      end

      context 'add with :with option assign property value after transformation' do
        it 'by proc' do
          test_obj = object_factory(attributes: { number: '12' }) do
            property :number, with: -> (v) { v.to_i }
          end

          expect(test_obj.number).to eq(12)
        end

        it 'by method' do
          test_obj = object_factory(attributes: { number: '12' }) do
            property :number, with: :convert_to_number

            def convert_to_number(value)
              value.to_i
            end
          end

          expect(test_obj.number).to eq(12)
        end
      end

      context 'add with :validates option' do
        subject do
          object_factory(real_class_name: 'FakeForm', attributes: { name: '' }) do
            property :name, validates: { presence: true }
          end
        end

        it 'attribute has validation' do
          expect(subject.valid?).to eq(false)
          expect(subject.errors.as_json).to eq(name: ["can't be blank"])
        end
      end

      context 'add with :model option' do
        subject do
          object_factory(attributes: { child: { name: 'Tom', age: 2 } }) do
            property :child, model: ChildModel
          end
        end

        it 'create model for attribute' do
          expect(subject.child).to be_a(ChildModel)
          expect(subject.child.name).to eq('Tom')
          expect(subject.child.age).to eq(2)
        end
      end

      context 'add with :collection option' do
        it 'raise error when is not a Array' do
          expect {
            object_factory(attributes: { children: { name: 'Tom', age: 2 } }) do
              property :children, collection: true
            end
          }.to raise_error
        end

        context 'with :model' do
          subject do
            attributes = {
              children: [
                { name: 'Tom', age: 2 },
                { name: 'Emi', age: 4 }
              ]
            }

            object_factory(attributes: attributes) do
              property :children, collection: ChildModel
            end
          end

          it 'returns array of models' do
            expect(subject.children.map(&:class)).to eq([ChildModel, ChildModel])
            expect(subject.children.count).to eq(2)
            expect(subject.children.first.name).to eq('Tom')
            expect(subject.children.last.name).to eq('Emi')
          end
        end

        context 'with :model and :uniq' do
          subject do
            attributes = {
              children: [
                { name: 'Tom', age: 2 },
                { name: 'Tom', age: 2 }
              ]
            }

            object_factory(attributes: attributes) do
              property :children, collection: ChildModel, uniq: true
            end
          end

          it 'returns array of models' do
            expect(subject.children.map(&:class)).to eq([ChildModel])
            expect(subject.children.count).to eq(1)
            expect(subject.children.first.name).to eq('Tom')
          end
        end
      end

      context 'add with :required option' do
        it 'raise MissingParamError when required param missing' do
          expect {
            object_factory { property :abc, required: true }
          }.to raise_error(LightForm::MissingParamError, 'abc')
        end
      end
    end

    context 'add nested' do
      let(:attributes) do
        {
          ab: {
            cd: {
              child: { age: '1', name: 'pawel', skip: 'av' }
            },
            ef: [
              { age: '31', name: 'Pawel', skip: 'wrong' },
              { age: '32', name: 'Sylwia', skip: 'bad' }
            ],
            gh: [
              { age: '31', name: 'Pawel', skip: 'wrong' },
              { age: '32', name: 'Sylwia', skip: 'bad' },
              { age: '32', name: 'Sylwia', skip: 'bad' }
            ]
          }
        }
      end

      it 'hold proper structure' do
        test_obj = object_factory(attributes: attributes) do
          property :ab do
            property :cd do
              property :child, model: ChildModel do
                properties :name, :age
              end
            end

            property :ef, collection: true do
              property :name
              property :age, with: -> (v) { v.to_i }
            end

            property :gh, collection: ChildModel, uniq: true do
              properties :name, :age
            end

            property :ij, collection: true, with: -> (v) { (v.nil? || v.empty?) ? [] : v }
          end
        end

        expect(test_obj.ab).not_to eq(nil)
        expect(test_obj.ab.cd.child).to be_a(ChildModel)
        expect(test_obj.ab.cd.child.age).to eq('1')
        expect(test_obj.ab.cd.child.name).to eq('pawel')
        expect { test_obj.ab.cd.child.skip }.to raise_error
        expect(test_obj.ab.ef[0].name).to eq('Pawel')
        expect(test_obj.ab.ef[0].age).to eq(31)
        expect(test_obj.ab.gh[0]).to be_a(ChildModel)
        expect(test_obj.ab.gh.count).to eq(2)
        expect(test_obj.ab.ij).to eq([])
      end

      it 'validation works' do
        test_obj = object_factory(
          attributes: {
            test: {
              child: { age: '1', name: '', skip: 'av' },
              children_hash: [
                { age: '31', name: '', skip: 'wrong' },
                { age: '32', name: 'Sylwia', skip: 'bad' }
              ],
              children: [
                { age: '31', name: 'Pawel', skip: 'wrong' },
                { age: '32', name: '', skip: 'bad' },
                { age: '32', name: '', skip: 'bad' }
              ]
            }
          }
        ) do
          property :test do
            property :child, model: ChildModel do
              property :name, validates: { presence: true }
              property :age, validates: { numericality: true }
            end

            property :children_hash, collection: true do
              property :name, validates: { presence: true }
              property :age, with: -> (v) { v.to_i }
            end

            property :children, collection: ChildModel, uniq: true do
              property :name, validates: { presence: true }
              property :age, validates: { numericality: true }
            end
          end
        end

        expect(test_obj.valid?).to eq(false)
      end

      it 'to_h' do
        attrs = {
          title: 'Mr',
          first_name: 'Pawel',
          last_name: 'Awesome',
          email: nil,
          age: '31',
          address: { street: 'Best', post_code: '33333' },
          children: [{ name: 'Emi', age: '2' }, { name: 'Emi', age: '2' }, { name: '', age: '2' }],
          interests: %w(football football basketball football)
        }

        test_obj = object_factory(real_class_name: 'PersonForm', attributes: attrs) do
          properties :title, :first_name, :last_name
          property :email, validates: { presence: true }
          property :age, with: -> (v) { v.to_i }

          property :address, model: AddressModel do
            properties :street, :post_code
          end

          property :children, collection: ChildModel, uniq: true do
            property :name, validates: { presence: true }
            property :age, with: -> (v) { v.to_i }
          end

          property :interests, collection: true, uniq: true
        end

        expect(test_obj.to_h).to eq(
          address: AddressModel.new(attrs[:address]),
          age: 31,
          children: [ChildModel.new(name: 'Emi', age: 2), ChildModel.new(name: '', age: 2)],
          email: nil,
          first_name: attrs[:first_name],
          interests: %w(football basketball),
          last_name: attrs[:last_name],
          title: attrs[:title]
        )

        expect(test_obj.valid?).to eq(false)
        expect(test_obj.errors.as_json).to eq(
          children: [{1=>{name: ["can't be blank"]}}],
          email: ["can't be blank"]
        )

      end
    end
  end
end
