require 'spec_helper'

describe FlatMap::Errors do
  let(:errors) {
    described_class.new(
      double( 'mapper', :suffixed? => true,
                        :suffix    => 'foo',
                        'attr_foo' => 2)
    )
  }

  it "preserved errors should appear on #empty? call exactly once" do
    errors.preserve :base, 'an error'
    errors.should_not be_empty
    errors[:base].should == ['an error']
    expect{ errors.empty? }.not_to change{ errors[:base].length }
  end

  it "should add error to mapper with suffix" do
    errors.add(:attr, 'an error')
    errors[:attr_foo].should == ['an error']
  end

  specify '#first_messages' do
    errors.add(:attr, 'first error')
    errors.add(:attr, 'second error')

    errors.first_messages.should == {:attr_foo => 'first error'}
  end
end
