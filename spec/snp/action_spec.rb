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

  describe "#register" do
    it "everything goes well" do
      lambda{
        Snarl::SNP.open(@host, @port) do |snp|
          snp.register(@app)
          snp.unregister(@app)
        end
      }.should_not raise_error
    end
    it "twice raises error on verbose" do
      Snarl::SNP.open(@host, @port) do |snp|
        snp.verbose = true
        snp.register(@app)
        lambda{snp.register(@app)}.should raise_error(Snarl::SNP::Error::SNP_ERROR_ALREADY_REGISTERED)
        snp.unregister(@app)
      end
      Snarl::SNP.open(@host, @port) do |snp|
        snp.register(@app)
        lambda{snp.register(@app)}.should_not raise_error(Snarl::SNP::Error::SNP_ERROR_ALREADY_REGISTERED)
        snp.unregister(@app)
      end
    end
  end

  describe "#unregister" do
    # it "everything goes well" is done in #register
    it "unregister before register raises error on verbose" do
      Snarl::SNP.open(@host, @port) do |snp|
        snp.verbose = true
        lambda{snp.unregister(@app)}.should raise_error(Snarl::SNP::Error::SNP_ERROR_NOT_REGISTERED)
      end
      Snarl::SNP.open(@host, @port) do |snp|
        lambda{snp.unregister(@app)}.should_not raise_error(Snarl::SNP::Error::SNP_ERROR_NOT_REGISTERED)
      end
    end
  end

  describe "#add_class" do
    it "everything goes well" do
      lambda{
        Snarl::SNP.open(@host, @port) do |snp|
          snp.register(@app)
          snp.add_class(@class)
          snp.unregister(@app)
        end
      }.should_not raise_error
    end
    it "add same class raises error on verbose" do
      Snarl::SNP.open(@host, @port) do |snp|
        snp.verbose = true
        snp.register(@app)
        snp.add_class(@class)
        lambda{snp.add_class(@class)}.should raise_error(Snarl::SNP::Error::SNP_ERROR_CLASS_ALREADY_EXISTS)
        snp.unregister(@app)
      end
      Snarl::SNP.open(@host, @port) do |snp|
        snp.register(@app)
        snp.add_class(@class)
        lambda{snp.add_class(@app)}.should_not raise_error(Snarl::SNP::Error::SNP_ERROR_CLASS_ALREADY_EXISTS)
        snp.unregister(@app)
      end
    end
  end

  describe "#notification" do
    it "sends title, text, icon, timeout, class" do
      Snarl::SNP.open(@host) do |snp|
        snp.register(@app)
        snp.add_class(@class)
        res = snp.notification('tit', 'tex(4 no icon popups)', 'ico', 9, 'cls')
        expected = "type=SNP#?version=1.0#?action=notification#?app=Ruby-Snarl#?class=cls#?title=tit#?text=tex(4 no icon popups)#?timeout=9#?icon=ico\r\n"
        res.request.to_s.should eql(expected)
      end
    end
    it "sends keyword-hash, keys=[:title, :text, :icon, :timeout, :class]" do
      Snarl::SNP.open(@host) do |snp|
        snp.register(@app)
        snp.add_class(@class)
        res = snp.notification(:title => 'tit', :text => 'tex', :icon => 'ico', :timeout => 9, :class => 'cls')
        expected = "type=SNP#?version=1.0#?action=notification#?app=Ruby-Snarl#?class=cls#?title=tit#?text=tex#?timeout=9#?icon=ico\r\n"
        res.request.to_s.should eql(expected)
      end
    end
   it "sends 'anonymous' message if not registered yet" do
      Snarl::SNP.open(@host) do |snp|
        res = snp.notification('tit', 'tex', 'ico', 9)
        expected = "type=SNP#?version=1.0#?action=notification#?title=tit#?text=tex#?timeout=9#?icon=ico\r\n"
        res.request.to_s.should eql(expected)
      end
    end
    it "sends 'anonymous' message if keyhash has {:app => nil} pair" do
      Snarl::SNP.open(@host) do |snp|
        res = snp.notification(:app => nil, :title => 'tit', :text => 'tex', :icon => 'ico', :timeout => 9)
        expected = "type=SNP#?version=1.0#?action=notification#?title=tit#?text=tex#?timeout=9#?icon=ico\r\n"
        res.request.to_s.should eql(expected)
      end
    end
  end

  describe "#hello" do
    it "returns Snarl release identifier" do
      Snarl::SNP.open(@host) do |snp|
        snp.hello.infomation.should match(/\ASnarl /)
      end
    end
  end

  describe "#version" do
    it "returns Snarl (inner) version" do
      Snarl::SNP.open(@host) do |snp|
        snp.version.infomation.should match(/[\d\.]+/)
      end
    end
  end

  describe "#normalize_notification_params" do
    before do
      @snp = Snarl::SNP.new
      @default_title = Snarl::SNP::DEFAULT_TITLE
      @default_timeout = Snarl::SNP::DEFAULT_TIMEOUT
    end
    def normalize_notification_params(param)
      @snp.__send__(:normalize_notification_params, param)
    end

    it "['text'] returns {:title => DEFAULT_TITLE, :text => 'text', :timeout => DEFAULT_TIMEOUT}" do
      params = ['text']
      expected = {:action => 'notification', :title => @default_title, :text => "text", :timeout => @default_timeout}
      normalize_notification_params(params).should eql(expected)
    end
    it "['text'] returns {:title => snp.title, :text => 'text', :timeout => DEFAULT_TIMEOUT}, when snp.title is set" do
      params = ['text']
      snp = Snarl::SNP.new
      snp.title = 'snp.title'
      expected = {:action => 'notification', :title => 'snp.title', :text => "text", :timeout => @default_timeout}
      snp.__send__(:normalize_notification_params, params).should eql(expected)
    end
    it "['text', 9] returns {:title => DEFAULT_TITLE, :text => 'text', :timeout => 9}" do
      params = ['text', 9]
      expected = {:action => 'notification', :title => @default_title, :text => "text", :timeout => 9}
      normalize_notification_params(params).should eql(expected)
    end
    it "['text', 9] returns {:title => snp.title, :text => 'text', :timeout => 9}, when snp.title is set" do
      params = ['text', 9]
      snp = Snarl::SNP.new
      snp.title = 'snp.title'
      expected = {:action => 'notification', :title => 'snp.title', :text => "text", :timeout => 9}
      snp.__send__(:normalize_notification_params, params).should eql(expected)
    end
    it "['title', 'text', 9] returns {:title => 'title', :text => 'text', :timeout => 9}" do
      params = ['title', 'text', 9]
      expected = {:action => 'notification', :title => 'title', :text => 'text', :timeout => 9}
      normalize_notification_params(params).should eql(expected)
    end
    it "[1,2,3,4,5,6,7] returns {:title, :text, :icon, :timeout, :class, :action, :app} Hash" do
      timeout = 9
      params = ['title', 'text', 'icon', timeout, 'class', 'action', 'app']
      expected = {:action => 'notification', :title => 'title', :text => 'text', :icon => 'icon', :timeout => timeout,
        :class => 'class', :app => 'app'}
      normalize_notification_params(params).should eql(expected)
    end
    it "[1,2,3,4,nil,nil,nil] returns {:title, :text, :icon, :timeout} Hash. nil-value key is omitted" do
      timeout = 9
      params = ['title', 'text', 'icon', timeout, nil, nil, nil]
      expected = {:action => 'notification', :title => 'title', :text => 'text', :icon => 'icon', :timeout => timeout}
      normalize_notification_params(params).should eql(expected)
    end
    it "when already registered, app is @app" do
      params = [{:text => 'text'}]
      snp = Snarl::SNP.new
      snp.instance_variable_set(:@app, 'app')
      expected = {:action => 'notification', :app => 'app', :title => @default_title, :text => "text", :timeout => @default_timeout}
      snp.__send__(:normalize_notification_params, params).should eql(expected)
    end
    it "if @app is :anonymous, app is nil" do
      params = [{:text => 'text'}]
      snp = Snarl::SNP.new
      snp.instance_variable_set(:@app, :anonymous)
      expected = {:action => 'notification', :app => nil, :title => @default_title, :text => "text", :timeout => @default_timeout}
      snp.__send__(:normalize_notification_params, params).should eql(expected)
    end

  end
end

