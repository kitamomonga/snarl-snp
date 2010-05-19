require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Request" do

  describe "#normalize_command" do
    def normalize_cmdkey(command)
      Snarl::SNP::Request.new.__send__(:normalize_cmdkey, command)
    end
    it "returns downcased string" do
      normalize_cmdkey('action').should eql('action')
      normalize_cmdkey('Action').should eql('action')
      normalize_cmdkey(:action).should eql('action')
    end
  end

  describe "#normalize_value" do
    def normalize_value(value)
      Snarl::SNP::Request.new.__send__(:normalize_value, value)
    end
    it 'converts one "\r\n" to one "\n"' do
      normalize_value("1\r\n2\r\n").should eql("1\n2\n")
    end
    it 'converts one "\r" to one "\n"' do
      normalize_value("1\r2\r").should eql("1\n2\n")
    end
    it 'never change multiple "\n\n\n\n\n"' do
      many_newline = "1\n\n\n\n\n2"
      normalize_value(many_newline).should eql(many_newline)
    end
  end

  describe "#normalize_action_value" do
    def normalize_action_value(cmdhash)
      Snarl::SNP::Request.new.__send__(:normalize_action_value, cmdhash)
    end
    it "returns action String, add-class is add_class" do
      normalize_action_value('register').should eql('register')
      normalize_action_value(:register).should eql('register')
      normalize_action_value('Register').should eql('register')
      normalize_action_value('add-class').should eql('add_class')
      normalize_action_value(:add_class).should eql('add_class')
    end
  end


  describe "#[]=" do
    it "set command pair with normalization" do
      req = Snarl::SNP::Request.new
      req[:action] = 'add-class'
      req['Class'] = 'Just Testing...'
      expected = {"class"=>"Just Testing...", 'action' =>"add_class"}
      req.commands.should eql(expected)
    end
  end

  describe "#normalize" do
    it "normalize" do
      cmd_hash = {
        :action => 'add-class',
        :app => "Just \r\nTesting\r\n...",
        'tiTLe' => nil,
        :cLASS => '1'
      }
      req = Snarl::SNP::Request.new(cmd_hash)
      req.__send__(:normalize)
      expected = {"app"=>"Just \nTesting\n...", "class"=>"1", "action"=>"add_class", "type"=>"SNP", "version"=>"1.0"}
      req.commands.should eql(expected)
    end
  end

  describe "#to_s" do
    it "is sendable string" do
      action = :notification
      cmds = {
        :action => action,
        :app => 'Just Testing...',
        :class => '1',
        :title => 'Hello',
        :text => 'World!',
        :timeout => 10
      }
      req = Snarl::SNP::Request.new(cmds)
      extepted = "type=SNP#?version=1.0#?action=notification#?app=Just Testing...#?class=1#?title=Hello#?text=World!#?timeout=10\r\n"
      req.to_s.should eql(extepted)
    end
  end

  describe ".build" do
    it "makes Request Object" do
      action = :add_class
      cmds = {
        :action => action,
        :app => 'Just Testing...',
        :class => '1',
        :title => '1 is one'
      }
      req = Snarl::SNP::Request.new(cmds)
      extepted = "type=SNP#?version=1.0#?action=add_class#?app=Just Testing...#?class=1#?title=1 is one\r\n"
      req.to_s.should eql(extepted)
    end
  end
end
