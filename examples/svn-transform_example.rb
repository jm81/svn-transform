require 'example_helper'

describe "SvnTransform" do
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
    
    it 'should add a [Class, args] Array to the @file_transforms Array' do
      @svn_t.file_transform(Class, 'a', 1)
      @svn_t.instance_variable_get(:@file_transforms).should ==
          [[Object, []], [Class, ['a', 1]]]
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
      @file = SvnTransform::File.example
      
      @klass = Class.new do
        def initialize(file, arg1 = nil, arg2 = nil)
          @file = file
          @arg1 = arg1
          @arg2 = arg2
        end
        def run
          if @arg2
            @file.body += " #{@arg2}"
          else
            @file.body = "body from transform Class"
          end
        end
      end
    end
    
    it 'should run +file+ through each file_transform' do
      @svn_t.file_transform do |file|
        file.properties['other'] = 'other_val'
      end
      @svn_t.file_transform(@klass)
      @svn_t.file_transform(@klass, 'ARG1', 'ARG2')
      @svn_t.__send__(:process_file_transforms, @file)
      
      @file.body.should == 'body from transform Class ARG2'
      @file.properties.should ==
          {'prop:svn' => 'property value', 'other' => 'other_val'}
    end
  end
  
  describe '#dir_transform' do
    before(:each) do
      @svn_t = SvnTransform.new('in', 'out')
      @svn_t.dir_transform(Object)
    end
    
    it 'should add a [Class, args] Array to the @dir_transforms Array' do
      @svn_t.dir_transform(Class, 'a', 1)
      @svn_t.instance_variable_get(:@dir_transforms).should ==
        [[Object, []], [Class, ['a', 1]]]
    end
    
    it 'should add a block to the @dir_transforms Array' do
      @svn_t.dir_transform { |dir| p dir }
      @svn_t.instance_variable_get(:@dir_transforms)[1].should be_kind_of(Proc)
    end
    
    it 'should raise an Error if neither is provided' do
      lambda { @svn_t.dir_transform }.should raise_error(ArgumentError)
    end
  end
  
  describe '#process_dir_transforms' do
    before(:each) do
      @svn_t = SvnTransform.new('in', 'out')
      @dir = SvnTransform::Dir.example
    end
  
    it 'should run +dir+ through each dir_transform' do
      @svn_t.dir_transform do |dir|
        dir.properties['other'] = 'other_val'
      end
      
      @svn_t.__send__(:process_dir_transforms, @dir)
      
      @dir.properties.should ==
         {'prop:svn' => 'property value', 'other' => 'other_val'}
    end
  end
end
