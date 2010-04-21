# -*- coding:utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "SNP" do

  before :all do
    @host = '192.168.0.2'
    @port = 9887
    @app = Snarl::SNP::DEFAULT_TITLE
    @class = '1'
    Snarl::SNP::Config.reset
  end

  describe "initialize" do
    it "new('192.168.0.2', 9887). (snarl_working_machine_host, snarl_port_9887)" do
      host, port, verbose = '192.168.0.2', 9887, true
      snp = Snarl::SNP.new(host, port, verbose)
      snp.instance_variable_get(:@host).should eql(host)
      snp.instance_variable_get(:@port).should eql(port)
      snp.verbose.should eql(verbose)
    end
    it "default host is 127.0.0.1, default port is 9887. when SNP.new()" do
      snp = Snarl::SNP.new
      snp.instance_variable_get(:@host).should eql(nil)
      snp.instance_variable_get(:@port).should eql(nil)
      snp.verbose.should eql(false)
    end
  end

  describe "#request" do
    describe "send raw string" do
      before :all do
        @register ="type=SNP#?version=1.0#?action=register#?app=#{@app}\r\n"
        @add_class = "type=SNP#?version=1.0#?action=add_class#?app=#{@app}#?class=#{@class}\r\n"
        @notification = "type=SNP#?version=1.0#?action=notification#?app=#{@app}#?title=Raw!#?text=raw message!#?timeout=10\r\n"
        @unregister = "type=SNP#?version=1.0#?action=unregister#?app=#{@app}\r\n"
      end

      it "raises error according to SNP#verbose" do
        Snarl::SNP.open(@host, @port) do |snp|
          lambda{
            snp.request(@register)
            snp.request(@register)
          }.should_not raise_error(Snarl::SNP::Error::SNP_ERROR_ALREADY_REGISTERED)
        end
        Snarl::SNP.open(@host, @port) do |snp|
          snp.verbose = true
          lambda{
            snp.request(@register)
            snp.request(@register)
          }.should raise_error(Snarl::SNP::Error::SNP_ERROR_ALREADY_REGISTERED)
        end
      end

      it "sends command text" do
        lambda{
          Snarl::SNP.open(@host, @port) do |snp|
            begin
              snp.request(@register)
            rescue Snarl::SNP::Error::SNP_ERROR_ALREADY_REGISTERED
            end
            begin
              snp.request(@add_class)
            rescue Snarl::SNP::Error::SNP_ERROR_CLASS_ALREADY_EXISTS
            end
            snp.request(@notification)
            snp.request(@unregister)
          end
        }.should_not raise_error
      end
    end
    describe "send hash" do
      before :each do
        @register = {
          :action => 'register',
          :app => @app
        }
        @add_class = {
          :app => @app,
          :action => 'add_class',
          :class => @class
        }
        @notification = {
          :app => @app,
          :action => 'notification',
          :class => @class,
          :title => 'command!',
          :text => 'Hashed message!',
          :timeout => 10
        }
        @unregister = {
          :action => 'unregister',
          :app => @app
        }
      end

      it "raises error according to SNP#verbose" do
        Snarl::SNP.open(@host, @port) do |snp|
          lambda{
            snp.request(@register)
            snp.request(@register)
          }.should_not raise_error(Snarl::SNP::Error::SNP_ERROR_ALREADY_REGISTERED)
        end
        Snarl::SNP.open(@host, @port) do |snp|
          snp.verbose = true
          lambda{
            snp.request(@register)
            snp.request(@register)
          }.should raise_error(Snarl::SNP::Error::SNP_ERROR_ALREADY_REGISTERED)
        end
      end

      it "sends command Hash" do
        lambda{
          Snarl::SNP.open(@host, @port) do |snp|
            begin
              snp.request(@register)
            rescue Snarl::SNP::Error::SNP_ERROR_ALREADY_REGISTERED
            end
            begin
              snp.request(@add_class)
            rescue Snarl::SNP::Error::SNP_ERROR_CLASS_ALREADY_EXISTS
            end
            snp.request(@notification)
            snp.request(@unregister)
          end
        }.should_not raise_error
      end
    end
  end

  describe "#add_classes" do
    it "adds two class pair like [['class1', 'one'], ['class2', 'two']]" do
      classes = [['1', 'one'], ['2', 'two']]
      lambda{
        Snarl::SNP.open(@host, @port) do |snp|
          snp.register(@app)
          snp.add_classes(classes)
          snp.notification('First class', '1!', nil, 4, '1')
          snp.notification('Second class', '2!', nil, 4, '2')
          snp.unregister(@app)
        end
      }.should_not raise_error
    end
  end

  describe "#snarl_hello" do
    it "returns Snarl release identifier string without popup" do
      Snarl::SNP.open(@host) do |snp|
        snp.snarl_hello.should match(/\ASnarl /)
      end
    end
  end

  describe "#snarl_version" do
    it "returns Snarl (inner) version string without popup" do
      Snarl::SNP.open(@host) do |snp|
        snp.snarl_version.should match(/[\d\.]+/)
      end
    end
  end

  describe "#iconset" do
    it "set icon using" do
      iconset = {:red => 'red.jpg', :blue => 'blue.jpg'}
      Snarl::SNP.open(@host, @port) do |snp|
        snp.register(@app)
        snp.iconset(iconset)
        snp.notification('icon!', 'icon1!', :red, 1).request.to_s.should match(/icon=red\.jpg/)
        snp.notification('icon!', 'icon2!', :blue, 1).request.to_s.should match(/icon=blue\.jpg/)
      end
    end
  end

  describe ".ping" do
    it "ping!" do
      lambda{Snarl::SNP.ping(@host)}.should_not raise_error
    end
    it "no host ping!" do
      Snarl::SNP::Config.host = @host
      lambda{Snarl::SNP.ping(nil)}.should_not raise_error
    end
  end

  describe ".open{|snp| ...}" do
    it "supplies Snarl::SNP object block" do
      Snarl::SNP.open(@host, @port) do |snp|
        snp.notification('hello!', 10) # TODO: default timeout
      end
    end
  end

  describe ".show_message" do
    it "show_message(host, port, title, text, timeout, icon) shows popup message" do
      lambda{Snarl::SNP.show_message(@host, @port, 'snp_spec', 'test mesage', 2, nil)}.should_not raise_error
    end
    it "show_message(host, text) shows popup message with ease" do
      lambda{Snarl::SNP.show_message(@host, 'short mesage')}.should_not raise_error
    end
  end

end

describe "SNP1.1 feature" do
  # NOTE: With "type=SNP#?version=1.0" also works on Snarl R2.21. wow.

  before :all do
    @host = '192.168.0.2'
    @port = 9887
    @app = Snarl::SNP::DEFAULT_TITLE
    @class = '1'
  end

  # Supports notification feedback forwarding in the form of 3xx codes sent to the remote application's port.
  ## How test?

  describe "new action" do

    describe "action=hello receives Snarl release identifier (i.e. Snarl R2.21)." do
      it "type=SNP#?version=1.1#?action=hello\\r\\n" do
        Snarl::SNP.open(@host) do |snp|
          res = snp.request("type=SNP#?version=1.1#?action=hello\r\n")
          res.inspect.should match(/\ASNP\/1.1\/0\/OK\/Snarl /)
        end
      end
    end

    describe "action=version receives Snarl (inner) version (i.e. 40.15)" do
      it "type=SNP#?version=1.1#?action=version\\r\\n" do
        Snarl::SNP.open(@host) do |snp|
          res = snp.request("type=SNP#?version=1.1#?action=version\r\n")
          res.inspect.should match(/\ASNP\/1.1\/0\/OK\/[\d\.]+\Z/)
        end
      end
    end

  end

  describe "notification returns notification token value." do
    it "counter?" do
      Snarl::SNP.open(@host) do |snp|
        snp.register(@app)
        snp.add_class(@class)
        res = snp.request("type=SNP#?version=1.1#?action=notification#?app=#{@app}#?title=1.1!#?text=val!#?timeout=2\r\n")
        res.inspect.should match(/\ASNP\/1.1\/0\/OK\/\d+\Z/)
        snp.unregister(@class)
      end
    end
  end

#   describe "notification icon path can be URL" do
#     it "use Google News Icon" do
#       lambda{
#         Snarl::SNP.open(@host) do |snp|
#           snp.register(@app)
#           snp.add_class(@class)
#           icon = 'http://www.google.com/images/newspaper.gif'
#           res = snp.request("type=SNP#?version=1.1#?action=notification#?app=#{@app}#?title=1.1!#?text=Google News!!#?timeout=4#?icon=#{icon}\r\n")
#           snp.unregister(@class)
#         end
#       }.should_not raise_error
#     end
#   end
end

