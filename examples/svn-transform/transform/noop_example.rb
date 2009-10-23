require 'example_helper'

describe SvnTransform::Transform::Noop do
  before(:each) do
    @file = SvnTransform::File.example
  end
  
  it 'should do nothing' do
    untouched = SvnTransform::File.example
    SvnTransform::Transform::Noop.new(@file).run.should be_false
    @file.body.should == untouched.body
    @file.basename.should == untouched.basename
    @file.properties.should == untouched.properties
  end
end
