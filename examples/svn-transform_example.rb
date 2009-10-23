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
end
