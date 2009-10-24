require 'example_helper'

describe SvnTransform::Dir do
  before(:each) do
    @dir = SvnTransform::Dir.example
  end
  
  describe '#initialize' do
    it 'should set #path' do
      @dir.path.should be_kind_of(Pathname)
      @dir.path.to_s.should == '/path/to/dir'
    end
    
    it 'should set #entries (extracted from node_data)' do
      @dir.entries.should == {'entry.txt' => nil}
    end
    
    it 'should set #repos' do
      @dir.repos.should == :repos # Actually, a Svn::Ra::Session
    end
    
    it 'should set #fixture_dir' do
      @dir.fixture_dir.should == :fixture_dir # Actually, a SvnFixture::Directory
    end
    
    it 'should set #properties (extracted from node_data)' do
      @dir.properties.should == {'prop:svn' => 'property value'}
    end
    
    it 'should set #rev_num' do
      @dir.rev_num.should == 10
    end
    
    it 'should set #rev_props' do
      @dir.rev_props.should == {'svn:author' => 'me'}
    end
  end
  
  describe '#basename' do
    it 'should return the basename of the path' do
      @dir.basename.should == 'dir'
    end
  end
  
  describe '#properties=' do
    it "should reject an Argument that doesn't respond to #each_pair" do
      lambda { @dir.properties = 'properties' }.should raise_error(ArgumentError)
      @dir.properties.should == {'prop:svn' => 'property value'}
    end
    
    it 'should set @properties' do
      @dir.properties = {'diffprop' => 'value'}
      @dir.properties.should == {'diffprop' => 'value'}
    end
  end
end
