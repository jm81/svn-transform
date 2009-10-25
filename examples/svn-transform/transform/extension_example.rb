require 'example_helper'

describe SvnTransform::Transform::Extension do
  before(:each) do
    @file = SvnTransform::File.example
    @klass = SvnTransform::Transform::Extension
    @transform = @klass.new(@file, {:txt => :markdown})
  end
  
  describe '#initialize' do
    it 'should set @file' do
      @transform.instance_variable_get(:@file).should be(@file)
    end
    
    it 'should set @extensions (as strings preceded with dot)' do
      @transform.instance_variable_get(:@extensions).should == {".txt" => ".markdown"}
    end
  end
  
  describe '#run' do
    it 'should return false if no changes made' do
      @file.basename = 'file.other'
      @transform.run.should be_false
      @file.basename.should == 'file.other'
    end
    
    it 'should return true and update @file.basename if changes made' do
      @file.basename = 'file.txt'
      @transform.run.should be_true
      @file.basename.should == 'file.markdown'
    end
    
    it 'should process multiple extension options' do
      @transform = @klass.new(@file, {:txt => :markdown, :ruby => :rb})
      @file.basename = 'file.txt'
      @transform.run.should be_true
      @file.basename.should == 'file.markdown'
      
      @file.basename = 'file.ruby'
      @transform.run.should be_true
      @file.basename.should == 'file.rb'
      
      @file.basename = 'file'
      @transform.run.should be_false
      @file.basename.should == 'file'
    end
  end
end
