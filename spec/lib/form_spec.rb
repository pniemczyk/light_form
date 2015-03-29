describe LightForm::Form do
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

    context 'options' do
      context 'add with :from option' do
        it 'assign property value from key provided by :from option' do
          test_obj = object_factory(attributes: { aB: 'ab' }) do
            property :ab, from: :aB
          end

          expect(test_obj.ab).to eq('ab')
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
    end
  end
end
