# -*- coding:utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Request" do

  describe "normalize_action" do
    def normalize_action(action)
      Snarl::SNP::Request.new.__send__(:normalize_action, action)
    end
    it "returns action String, add-class is add_class" do
      normalize_action('register').should eql('register')
      normalize_action('add-class').should eql('add_class')
    end
  end

  describe "#[]=" do
    it "set commands with []=" do
      req = Snarl::SNP::Request.new
      req[:action] = 'register'
      req['app'] = 'Just Testing...'
      expected = {"app"=>"Just Testing...", :action =>"register"}
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
