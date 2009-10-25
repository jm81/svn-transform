require 'example_helper'

describe SvnTransform::Transform::Newline do
  before(:each) do
    @file = SvnTransform::File.example
    @klass = SvnTransform::Transform::Newline
    @transform = @klass.new(@file, "<br \/>\n")
  end
  
  describe '#initialize' do
    it 'should set @file' do
      @transform.instance_variable_get(:@file).should be(@file)
    end
    
    it 'should set @newline' do
      @transform.instance_variable_get(:@newline).should == "<br \/>\n"
      @klass.new(@file).instance_variable_get(:@newline).should == "\n"
    end
  end
  
  describe '#all_to_lf' do
    it 'should convert CRs and CRLFs to LFs' do
      str = "\nabc\r\n\n\rdef\r\rghi\r\n\r\n\njkl\r"
      @transform.__send__(:all_to_lf, str).should ==
          "\nabc\n\n\ndef\n\nghi\n\n\njkl\n"
    end
  end
  
  describe '#run' do
    it 'should return false if no changes made' do
      input = "\r\nabc\r\n"
      @file.body = input
      @klass.new(@file, @klass::CRLF).run.should be_false
      @file.body.should be(input)
    end
    
    it 'should return true and update @file.body if changes made' do
      input = "\r\nabc\r\n"
      @file.body = input
      @klass.new(@file).run.should be_true
      @file.body.should == "\nabc\n"
    end
    
    it 'should replace all newlines with @newline' do
      input = "\r\nabc\r\n\n\n\r"
      @file.body = input
      @klass.new(@file, "NL").run.should be_true
      @file.body.should == "NLabcNLNLNLNL"
    end
  end
end
