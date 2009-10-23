require 'example_helper'

describe SvnTransform::File do
  before(:each) do
    @file = SvnTransform::File.example
  end
  
  describe '#initialize' do
    it 'should set #path' do
      @file.path.should be_kind_of(Pathname)
      @file.path.to_s.should == '/path/to/file.txt'
    end
    
    it 'should set #body (extracted from node_data)' do
      @file.body.should == 'body of file'
    end
    
    it 'should set #properties (extracted from node_data)' do
      @file.properties.should == {'prop:svn' => 'property value'}
    end
    
    it 'should set #rev_num' do
      @file.rev_num.should == 10
    end
    
    it 'should set #rev_props' do
      @file.rev_props.should == {'svn:author' => 'me'}
    end
  end
  
  describe '#basename' do
    it 'should return the basename of the path' do
      @file.basename.should == 'file.txt'
    end
  end
  
  describe '#basename=' do
    it 'should update the path' do
      @file.basename = 'app.exe'
      @file.path.should == Pathname.new('/path/to/app.exe')
      @file.basename.should == 'app.exe'
    end
  end
  
  describe '#body=' do
    it 'should set @body' do
      @file.body = 'new body'
      @file.body.should == 'new body'
    end
  end
  
  describe '#properties=' do
    it "should reject an Argument that doesn't respond to #each_pair" do
      lambda { @file.properties = 'properties' }.should raise_error(ArgumentError)
      @file.properties.should == {'prop:svn' => 'property value'}
    end
    
    it 'should set @properties' do
      @file.properties = {'diffprop' => 'value'}
      @file.properties.should == {'diffprop' => 'value'}
    end
  end
  
  describe '#skip!' do
    it 'should set #skip? to true' do
      @file.skip?.should be_false
      @file.skip!
      @file.skip?.should be_true
    end
  end
end