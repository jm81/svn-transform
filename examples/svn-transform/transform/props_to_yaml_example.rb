require 'example_helper'

describe SvnTransform::Transform::PropsToYaml do
  before(:each) do
    @klass = SvnTransform::Transform::PropsToYaml
    @file = SvnTransform::File.example
    @file.body = "Body Only\n"
    @file.properties = {'title' => 'Hello', 'prop:one' => 'o', 'prop:two' => 't'}
  end
  
  describe '#run (file)' do
    it 'should move all if instruction is :all' do
      @klass.new(@file, :all).run.should be_true
      @file.body.should == "--- \ntitle: Hello\nprop:two: t\nprop:one: o\n---\n\nBody Only\n"
      @file.properties.should == {}
    end
    
    it 'should add to existing Yaml props' do
      @file.body = "--- \nnewprop: hi\n---\n\nBody Only\n"
      @klass.new(@file, :all).run.should be_true
      @file.body.should == "--- \ntitle: Hello\nprop:two: t\nnewprop: hi\nprop:one: o\n---\n\nBody Only\n"
      @file.properties.should == {}
      
      @file.body = "---\nnewprop: hi\n...\nBody Only\n"
      @file.properties = {'title' => 'Hello', 'prop:one' => 'o', 'prop:two' => 't'}
      @klass.new(@file, :all).run.should be_true
      @file.body.should == "--- \ntitle: Hello\nprop:two: t\nnewprop: hi\nprop:one: o\n---\n\nBody Only\n"
      @file.properties.should == {}
    end
    
    it 'should override existing Yaml props that conflict with Svn props' do
      @file.body =  "---\nnewprop: hi\ntitle: World\n...\nBody Only\n"
      @klass.new(@file, :all).run.should be_true
      @file.body.should == "--- \ntitle: Hello\nprop:two: t\nnewprop: hi\nprop:one: o\n---\n\nBody Only\n"
    end
    
    it 'should match a string' do
      @klass.new(@file, [['title', 'newtitle']]).run.should be_true
      @file.body.should == "--- \nnewtitle: Hello\n---\n\nBody Only\n"
      @file.properties.should == {'prop:one' => 'o', 'prop:two' => 't'}
    end
    
    it 'should match a regex' do
      @klass.new(@file, [[/\Aprop:(.*)\Z/, 'p-\1']]).run.should be_true
      @file.body.should == "--- \np-two: t\np-one: o\n---\n\nBody Only\n"
      @file.properties.should == {'title' => 'Hello'}
    end
    
    it 'should move props' do
      @klass.new(@file, [[/prop/, :move]]).run.should be_true
      @file.body.should == "--- \nprop:two: t\nprop:one: o\n---\n\nBody Only\n"
      @file.properties.should == {'title' => 'Hello'}
    end
    
    it 'should delete props' do
      @klass.new(@file, [[/prop/, :delete]]).run.should be_true
      @file.body.should == "Body Only\n"
      @file.properties.should == {'title' => 'Hello'}
    end
    
    it 'should not add empty yaml to body' do
      @klass.new(@file, [['nothing', :move]]).run.should be_false
      @file.body.should == "Body Only\n"
      @file.properties.should == {'title' => 'Hello', 'prop:one' => 'o', 'prop:two' => 't'}
    end
    
    it 'should return false if nothing happens' do
      @klass.new(@file, [['nothing', :move]]).run.should be_false
      @file.body.should == "Body Only\n"
      @file.properties.should == {'title' => 'Hello', 'prop:one' => 'o', 'prop:two' => 't'}
    end
    
    it 'should handle multiple instructions' do
      @file.body = "---\ntitle: Hello\nyaml_only: yaml\n---\nBody Only\n"
      @file.properties = {'ws:title' => 'Hello World', 'ws:published' => 'y', 'ws:tags' => 'this; that'}
      @klass.new(@file, [['ws:tags', 'topics'], [/\Aws:(.*)\Z/, '\1']]).run.should be_true
      @file.body.should == "--- \ntitle: Hello World\npublished: y\ntopics: this; that\nyaml_only: yaml\n---\n\nBody Only\n"
      @file.properties.should == {}
    end
  end
  
  describe '#run (directory)' do
    # The best way I can see to test this is just run a full example.
    it 'should move properties to YAML file' do
      load 'fixtures/dir_props.rb'
      in_repo = SvnFixture.repo('dir_props')
      transform = SvnTransform.new(in_repo.uri, 'dir_props_out')
      transform.dir_transform(@klass, :all)
      transform.convert
      
      out_sess = SvnTransform::Session.new(SvnFixture.repo('dir_props_out').uri)
      repo = out_sess.session
      repo.stat('noprops/meta.yml', 1).should be_nil
      
      repo.dir('svnprops', 1)[1]['one'].should be_nil
      repo.dir('svnprops', 1)[1]['two'].should be_nil
      repo.stat('svnprops/meta.yml', 1).should_not be_nil
      repo.file('svnprops/meta.yml', 1)[0].should == "--- \ntwo: t\none: o\n"
      
      repo.dir('yamlprops', 1)[1]['one'].should be_nil
      repo.dir('yamlprops', 1)[1]['two'].should be_nil
      repo.file('yamlprops/meta.yml', 1)[0].should == "---\none: yaml\n"
      
      repo.dir('bothprops', 1)[1]['one'].should be_nil
      repo.dir('bothprops', 1)[1]['two'].should be_nil
      repo.file('bothprops/meta.yml', 1)[0].should == "--- \ntwo: yaml\none: o\n"
      
      SvnFixture.repo('dir_props').destroy
      SvnFixture.repo('dir_props_out').destroy
    end
  end
  
  describe 'yaml_split' do
    def get_split
      @klass.new(@file, :all).__send__(:yaml_split)[1]
    end
    
    it 'should split out yaml (end with ---)' do
      @file.body = "---\none: two\nthree: four\n---\n\nBody"
      get_split.should == 'Body'
    end
    
    it 'should remove yaml (end with ...)' do
      @file.body = "---\none: two\nthree: four\n...\n\nBody"
      get_split.should == 'Body'
    end
    
    it 'should handle newlines well' do
      @file.body = "---\r\none: two\r\nthree: four\r\n---\r\n\r\nBody"
      get_split.should == 'Body'
      @file.body = "--- \r\none: two\r\nthree: four\r\n\n---\r\n\r\n\n\nBody"
      get_split.should == 'Body'
      @file.body = "---     \n\none: two\nthree: four\n\n...\n\nBody"
      get_split.should == 'Body'
    end
  end
end
