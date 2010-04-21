# -*- coding:utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Response" do

  before do
    @res = 'SNP/1.0/0/OK/1234'
  end

  describe "initialize" do
    it "parse string" do
      Snarl::SNP::Response.new(@res).instance_variable_get(:@response).should eql(@res)
    end
    it "parse getable obj" do
      socket = Object.new
      socket.stub!(:get).and_return(@res)
      Snarl::SNP::Response.new(socket).instance_variable_get(:@response).should eql(@res)
    end
  end

  describe "#parse_response" do
    it "raise error when unparsable response" do
      lambda{
        Snarl::SNP::Response.new("SNP/1.0/zerozero/Oops!\r\n")
      }.should raise_error(Snarl::SNP::Error::RUBYSNARL_UNKNOWN_RESPONSE)
    end
  end

  describe "#code" do
    it "SNP1.1 response code(3rd block) on non-error-response is String '0'" do
      Snarl::SNP::Response.new(@res).code.should eql('0')
    end
    it "other response code" do
      begin
      Snarl::SNP::Response.new("SNP/1.1/203/Application is already registered\r\n")
        rescue Snarl::SNP::Error::SNP_ERROR_ALREADY_REGISTERED => ex
        ex.response.code.should eql('203')
      end
    end
  end

  describe "#message" do
    it "SNP1.1 respnse message(4th block) on non-error-response is 'OK'" do
      Snarl::SNP::Response.new(@res).message.should eql('OK')
    end
    it "no 5th block response" do
      begin
      Snarl::SNP::Response.new("SNP/1.1/203/Application is already registered\r\n")
        rescue Snarl::SNP::Error::SNP_ERROR_ALREADY_REGISTERED => ex
        ex.response.message.should eql('Application is already registered')
      end
    end
  end

  describe "#infomation" do
    it "SNP1.1 response infomation(5th opptional block) on non-error-notification-response is integer str" do
      Snarl::SNP::Response.new(@res).infomation.should eql('1234')
    end
    it "no 5th block response, returns nil" do
      begin
        Snarl::SNP::Response.new("SNP/1.1/203/Application is already registered\r\n")
      rescue Snarl::SNP::Error::SNP_ERROR_ALREADY_REGISTERED => ex
        ex.response.infomation.should be_nil
      end
    end
  end

  describe "#error" do
    it "returns Snarl::SNP::Error class" do
      Snarl::SNP::Response.new(@res).error.should eql(Snarl::SNP::Error::SNP_OK)
      begin
        Snarl::SNP::Response.new("SNP/1.0/204/Class is already registered\r\n")
      rescue Snarl::SNP::Error::SNP_ERROR_CLASS_ALREADY_EXISTS => ex
        ex.response.error.should eql(Snarl::SNP::Error::SNP_ERROR_CLASS_ALREADY_EXISTS)
      end
    end
  end

  describe "#ok?" do
    it "returns true when OK response" do
      Snarl::SNP::Response.new(@res).should be_ok
    end
  end

  describe "#to_s" do
    it "to_s is response code" do
      Snarl::SNP::Response.new(@res).to_s.should eql('0')
    end
  end

  describe "#inspect" do
    it "inspect is response string itself" do
      Snarl::SNP::Response.new(@res).inspect.should eql(@res)
    end
  end
end
