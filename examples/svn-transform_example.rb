require 'example_helper'

describe "SvnTransform" do
  it 'should rename properties as specified'
  it 'should not move skipped properties'
  it 'should quote in yaml if the key string has a colon'
  it 'should retain body updates'
  it 'should merge with existing YAML Front Matter (using most recent update)'
  it 'should update properties in YAML when svn properties are updated'
  it 'should retain all adds and deletes'
  
  describe '#update_eof' do
    it 'should alter newlines if config[:eof] set (to LF)'
    it 'should alter newlines if config[:eof] set (to CRLF)'
    it 'should not alter newlines if config[:eof] is nil'
  end
  
  describe '#convert' do
    it 'should make full conversion correctly'
  end
  
  describe 'direct copy' do
    it 'should make a MOL copy' do
      SvnFixture::Repository.instance_variable_set(:@repositories, {})
      load File.dirname(__FILE__) + '/fixtures/original.rb'
      in_repo = SvnFixture.repo('original')
      SvnTransform.new(in_repo.uri, 'directcopy').convert
      SvnTransform.compare(in_repo.repos_path, SvnFixture.repo('directcopy').repos_path).should be_true
      SvnFixture.repo('original').destroy
      SvnFixture.repo('directcopy').destroy
    end
  end
  
  describe '#file_transform' do
    before(:each) do
      @svn_t = SvnTransform.new('in', 'out')
      @svn_t.file_transform(Object)
    end
    
    it 'should add a Class to the @file_transforms Array' do
      @svn_t.file_transform(Class)
      @svn_t.instance_variable_get(:@file_transforms).should ==
          [Object, Class]
    end
    
    it 'should add a block to the @file_transforms Array' do
      @svn_t.file_transform { |file| p file }
      @svn_t.instance_variable_get(:@file_transforms)[1].should be_kind_of(Proc)
    end
    
    it 'should raise an Error if neither is provided' do
      lambda { @svn_t.file_transform }.should raise_error(ArgumentError)
    end
  end
  
  describe '#process_file_transforms' do
    before(:each) do
      @svn_t = SvnTransform.new('in', 'out')
      @file = SvnTransform::File.new(
        '/path/to/file.txt', # Actually a Pathname
        ['body of file', {'prop:svn' => 'property value'}],
        10,
        {'svn:author' => 'me'}
      )
      
      @klass = Class.new do
        def initialize(file)
          @file = file
        end
        def run
          @file.body = 'body from transform Class'
        end
      end
    end
    
    it 'should run +file+ through each file_transform' do
      @svn_t.file_transform do |file|
        file.properties['other'] = 'other_val'
      end
      @svn_t.file_transform(@klass)
      @svn_t.__send__(:process_file_transforms, @file)
      
      @file.body.should == 'body from transform Class'
      @file.properties.should ==
          {'prop:svn' => 'property value', 'other' => 'other_val'}
    end
  end
end
