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
  end
end
