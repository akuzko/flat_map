require 'spec_helper'

module FlatMap
  module PersistenceSpec
    class TargetClass < Struct.new(:attr_a, :attr_b)
    end

    class OtherTargetClass < Struct.new(:attr_c, :attr_d)
    end

    module ArbitraryModule
    end

    class TargetClassMapper < Mapper
      include ArbitraryModule

      map :attr_a
      map :dob => :attr_b, :multiparam => Date
    end

    class InheritedClassMapper < TargetClassMapper
    end

    class ExplicitNameMapper < Mapper
      self.target_class_name = 'FlatMap::PersistenceSpec::OtherTargetClass'
    end
  end

  describe Mapper::Persistence do
    describe '#target_class' do
      it 'should detect target_class from mapper class name' do
        PersistenceSpec::TargetClassMapper.target_class.should == PersistenceSpec::TargetClass
      end

      it 'should detect target_class from nearest ancestor when inherited' do
        PersistenceSpec::InheritedClassMapper.target_class.should == PersistenceSpec::TargetClass
      end

      it 'should use explicit class name if specified' do
        PersistenceSpec::ExplicitNameMapper.target_class.should == PersistenceSpec::OtherTargetClass
      end
    end

    describe '.build' do
      it 'should use target class to build a new object for mapper' do
        PersistenceSpec::TargetClassMapper.should_receive(:new).with(kind_of(PersistenceSpec::TargetClass), :used_trait)
        PersistenceSpec::TargetClassMapper.build(:used_trait)
      end
    end

    describe '.find' do
      let(:target){ PersistenceSpec::TargetClass.new('a', 'b') }

      it 'should delegate to target class to find object for mapper' do
        PersistenceSpec::TargetClass.should_receive(:find).with(1).and_return(target)
        PersistenceSpec::TargetClassMapper.should_receive(:new).with(target, :used_trait)
        PersistenceSpec::TargetClassMapper.find(1, :used_trait)
      end
    end

    describe 'behavior' do
      let(:target){ PersistenceSpec::TargetClass.new('a', 'b') }
      let(:mapper){ PersistenceSpec::TargetClassMapper.new(target){} }

      specify '#model_name' do
        mapper.model_name.should == 'mapper'
      end

      specify '#to_key should delegate to target' do
        target.should_receive(:to_key).and_return(1)
        mapper.to_key.should == 1
      end

      specify '#persisted? when target does not respond to :persised?' do
        mapper.should_not be_persisted
      end

      specify '#persisted? when target responds to :persisted?' do
        target.stub(:persisted?).and_return(true)
        mapper.should be_persisted
      end

      specify '#id when target does not respond to :id' do
        mapper.id.should be_nil
      end

      specify '#id when target responds to :id' do
        target.stub(:id).and_return(1)
        mapper.id.should == 1
      end

      describe '#write with multiparams' do
        let(:params) {{
          'attr_a'     => 'A',
          'dob(0i)' => '1999',
          'dob(1i)' => '01',
          'dob(2i)' => '02'
        }}

        it 'should assign values properly' do
          mapper.write(params)
          target.attr_a.should == 'A'
          target.attr_b.should == Date.new(1999, 1, 2)
        end
      end

      describe '#save_target' do
        it 'should return true for owned mappers' do
          mapper.extension.save_target.should be_true
        end

        it 'should return true if target does not respond to #save' do
          mapper.save_target.should be_true
        end

        it 'should save with no validation if target responds to #save' do
          target.should_receive(:save).with(:validate => false).and_return(true)
          mapper.save_target.should be_true
        end
      end

      describe '#apply' do
        let(:params){{ :attr_a => 'A' }}

        it 'should write params first' do
          mapper.should_receive(:write).with(params)
          ActiveRecord::Base.should_receive(:transaction).and_yield
          mapper.apply(params)
        end

        it 'should not save if not valid' do
          mapper.stub(:valid?).and_return(false)
          mapper.should_not_receive(:save)
          mapper.apply(params)
        end

        it 'should save if valid' do
          mapper.stub(:valid?).and_return(true)
          ActiveRecord::Base.should_receive(:transaction).and_yield
          mapper.should_receive(:save)
          mapper.apply(params)
        end
      end

      specify '#save_self_with_callbacks saves target in a save callbacks' do
        mapper.should_receive(:run_callbacks).with(:save).and_yield
        mapper.should_receive(:save_target)
        mapper.save_self_with_callbacks
      end
    end
  end
end
