# -*- coding:utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Config" do

  before do
    Snarl::SNP::Config.reset
  end

  describe ".host=" do
    it "set host into String" do
      Snarl::SNP::Config.host = 1234
      Snarl::SNP::Config.host.should eql('1234')
    end
    it "set nil, returns default" do
      config = Snarl::SNP::Config.new
      Snarl::SNP::Config.host = nil
      Snarl::SNP::Config.host.should eql(Snarl::SNP::Config::DEFAULT_HOST)
    end
  end

  describe ".port=" do
    it "set port into Integer" do
      Snarl::SNP::Config.port = '9887'
      Snarl::SNP::Config.port.should eql(9887)
    end
    it "set nil, returns default" do
      Snarl::SNP::Config.port = nil
      Snarl::SNP::Config.port.should eql(Snarl::SNP::Config::DEFAULT_PORT)
    end
  end

#   describe ".load_snp_config" do

#     before do
#       @yaml = Tempfile.new('rubysnarlsnpconfigspec')
#     end
#     after do
#       @yaml.close
#     end

#     it "read yaml from argument path" do
#       host = '192.168.0.2'
#       port = 9887
#       @yaml.write("host : #{host}\nport : #{port}")
#       @yaml.close
#       config = Snarl::SNP::Config.load_snp_config(@yaml.path)
#       config.host.should eql(host)
#       config.port.should eql(port) # YAML.load('9887') #=> Integer
#     end
#   end

end
