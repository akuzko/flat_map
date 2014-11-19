require 'spec_helper'

module FlatMap
  module SkippingSpec
    class SpecMapper < Mapper
      trait :with_trait do
        map :attr_a, :attr_b

        set_callback :validate, :before, :set_attr_a, :prepend => true
        set_callback :save, :before, :set_attr_b

        validates_numericality_of :attr_a

        def set_attr_a
          self.attr_a = 'a'
        end

        def set_attr_b
          self.attr_b = 'b'
        end
      end
    end

    class CallbacksSpecMapper < Mapper
      attr_accessor :values

      trait :first_trait do
        set_callback :save, :before, :first_before
        set_callback :save, :after, :first_after

        def first_before
          values.push 'first_before'
        end

        def first_after
          values.push 'first_after'
        end
      end

      trait :second_trait do
        set_callback :save, :before, :second_before
        set_callback :save, :after, :second_after

        def second_before
          values.push 'second_before'
        end

        def second_after
          values.push 'second_after'
        end
      end

      def save_target
        values.push 'value'
        false
      end
    end
  end

  describe 'Skipping' do
    let(:mapper){ SkippingSpec::SpecMapper.new(OpenStruct.new, :with_trait) }

    before{ mapper.trait(:with_trait).skip! }

    it 'should completely ignore skipped mounting' do
      mapper.should be_valid
      mapper.save.should be_true
      mapper.attr_a.should be_nil
      mapper.attr_b.should be_nil
    end

    it '#use! should enable skipped mounting' do
      mapper.trait(:with_trait).use!

      mapper.should_not be_valid
      mapper.attr_a.should == 'a'
      mapper.errors[:attr_a].should be_present

      mapper.attr_a = 5
      mapper.save
      mapper.attr_b.should == 'b'
    end
  end

  describe 'Skipping and callbacks' do
    let(:mapper){ SkippingSpec::CallbacksSpecMapper.new(OpenStruct.new, :first_trait, :second_trait) }

    before do
      mapper.values = []
      mapper.trait(:first_trait).skip!
    end

    it 'should not overwite main result' do
      mapper.save.should be_false
    end

    it 'should handle callbacks chain in right way' do
      mapper.save
      mapper.values.should == ['second_before', 'value', 'second_after']
    end
  end

  describe 'Skipping ActiveRecord' do
    let(:target){ OpenStruct.new }
    let(:mapper){ SkippingSpec::SpecMapper.new(target, :with_trait) }

    before{ target.stub(:is_a?).with(ActiveRecord::Base).and_return(true) }

    context 'for new record' do
      before do
        target.stub(:new_record?).and_return(true)
        mapper.trait(:with_trait).skip!
      end

      specify '#skip! should set ivar @destroyed to true' do
        target.instance_variable_get('@destroyed').should be_true
      end

      specify '#use! should set ivar @destroyed to true' do
        mapper.trait(:with_trait).use!
        target.instance_variable_get('@destroyed').should be_false
      end
    end

    context 'for persisted record' do
      before do
        target.stub(:new_record?).and_return(false)
      end

      specify '#skip! should reload persisted record' do
        target.should_receive(:reload)
        mapper.trait(:with_trait).skip!
      end

      specify '#use! should use all nested mountings' do
        mapper.trait(:with_trait).skip!
        mock = double('mounting')
        mock.should_receive(:use!)
        mapper.trait(:with_trait).stub(:all_nested_mountings).and_return([mock])
        mapper.trait(:with_trait).use!
      end
    end
  end
end
