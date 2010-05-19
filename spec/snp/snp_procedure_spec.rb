require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Snarl::SNP" do

  before :all do
    @host = '192.168.0.2'
    @port = 9887
    @app = Snarl::SNP::DEFAULT_TITLE
    @class = '1'
  end

  def snp_open(&block)
    snp = Snarl::SNP.new(@host, @port)
    snp.stub!(:send).and_return('SNP/1.1/0/OK/1234/')
    block.call(snp)
  end

  describe "#auto_register" do
    it "do register when snp['app'] exists" do
      expected = "type=SNP#?version=1.0#?action=register#?app=#{@app}\r\n"
      snp_open do |snp|
        snp['app'] = @app
        snp.auto_register.request_str.should eql(expected)
      end
    end
    it "do nothing when snp['app'] is nil/unset/empty" do
      snp_open do |snp|
        snp['app'] = nil
        snp.auto_register.should be_nil
      end
      snp_open do |snp|
        snp.instance_variable_get(:@config).config.delete('app')
        snp.auto_register.should be_nil
      end
      snp_open do |snp|
        snp['app'] = ""
        snp.auto_register.should be_nil
      end
    end

  end
  describe "#auto_add_class" do
    before :all do
      classname1, classtitle1 = 'classname1', 'classtitle1'
      classname2 = 'classname2'
      @res1 = "type=SNP#?version=1.0#?action=add_class#?app=#{@app}#?class=#{classname1}#?title=#{classtitle1}\r\n"
      @res2 = "type=SNP#?version=1.0#?action=add_class#?app=#{@app}#?class=#{classname2}\r\n"
      @classes = [[classname1, classtitle1], [classname2, nil]]
    end

    it "do register when snp['class'] exists" do
      expected = [@res1, @res2]
      snp_open do |snp|
        snp['app'] = @app
        snp['class'] = @classes
        snp.auto_add_class.map{|e| e.request_str}.should eql(expected)
      end
    end
    it "do nothing when snp['class'] is nil/unset/empty" do
      snp_open do |snp|
        snp['app'] = @app
        snp['class'] = nil
        snp.auto_add_class.should be_nil
      end
      snp_open do |snp|
        snp['app'] = @app
        snp.instance_variable_get(:@config).config.delete('class')
        snp.auto_add_class.should be_nil
      end
      snp_open do |snp|
        snp['app'] = @app
        snp['class'] = []
        snp.auto_add_class.should be_nil
      end
    end
    it "do nothing when snp['app'] is unset" do
      snp_open do |snp|
        snp.instance_variable_get(:@config).config.delete('app')
        snp['class'] = @classes
        snp.auto_add_class.should be_nil
      end
    end
  end

  describe "#auto_notification" do
    it "snp['notification'] == {notify_arg_hash} with snp['app']" do
      expected = "type=SNP#?version=1.0#?action=notification#?app=#{@app}#?title=title#?text=text#?timeout=10\r\n"
      snp_open do |snp|
        snp['app'] = @app
        snp['notification'] = {'title' => 'title', 'text' => 'text'}
        snp.auto_notification.request_str.should eql(expected)
      end
    end
    it "snp['notification'] == {notify_arg_hash} without snp['app'] but hash has {'app' => app}" do
      expected = "type=SNP#?version=1.0#?action=notification#?app=#{@app}#?title=title#?text=text#?timeout=10\r\n"
      snp_open do |snp|
        snp['notification'] = {'app' => @app, 'title' => 'title', 'text' => 'text'}
        snp.auto_notification.request_str.should eql(expected)
      end
    end
    it "snp['notification'] == [notify_arg_array]" do
      expected = "type=SNP#?version=1.0#?action=notification#?app=#{@app}#?title=title#?text=text#?timeout=9\r\n"
      snp_open do |snp|
        snp['app'] = @app
        snp['notification'] = ['title', 'text', 9]
        snp.auto_notification.request_str.should eql(expected)
      end
    end
    it "snp['notification'] == [{notify_arg_hash1}, {notify_arg_hash2}, ...]" do
      arg1 = {'title' => 'title1', 'text' => 'text1', 'timeout' => 8}
      arg2 = {'title' => 'title2', 'text' => 'text2', 'timeout' => 7}
      notifications = [arg1, arg2]
      res1 = "type=SNP#?version=1.0#?action=notification#?app=#{@app}#?title=title1#?text=text1#?timeout=8\r\n"
      res2 = "type=SNP#?version=1.0#?action=notification#?app=#{@app}#?title=title2#?text=text2#?timeout=7\r\n"
      expected = [res1, res2]
      snp_open do |snp|
        snp['app'] = @app
        snp['notification'] = notifications
        snp.auto_notification.map{|res| res.request_str}.should eql(expected)
      end
    end
    it "snp['notification'] == nil, build notify_hash from app,text,title,..." do
      expected = "type=SNP#?version=1.0#?action=notification#?app=#{@app}#?class=class#?title=title#?text=text#?timeout=6\r\n"
      snp_open do |snp|
        snp['app'] = @app
        snp.instance_variable_get(:@config).config.delete('notification')
        snp['title'] = 'title'
        snp['text'] = 'text'
        snp['timeout'] = '6'
        snp['class'] = 'class'
        snp.auto_notification.request_str.should eql(expected)
      end
    end
  end

  describe "#auto_unregister" do
    it "do unregister when snp['unregister'] and snp['app'] exist" do
      expected = "type=SNP#?version=1.0#?action=unregister#?app=#{@app}\r\n"
      snp_open do |snp|
        snp['app'] = @app
        snp['unregister'] = true
        snp.auto_unregister.request_str.should eql(expected)
      end
    end
    it "do nothing when snp['unregister'] is nil/unset/false" do
      snp_open do |snp|
        snp['app'] = @app
        snp['unregister'] = nil
        snp.auto_unregister.should be_nil
      end
      snp_open do |snp|
        snp['app'] = @app
        snp.instance_variable_get(:@config).config.delete('unregister')
        snp.auto_unregister.should be_nil
      end
      snp_open do |snp|
        snp['app'] = @app
        snp['unregister'] = false
        snp.auto_unregister.should be_nil
      end
    end
    it "do nothing when snp['app'] is nil/unset/empty" do
      snp_open do |snp|
        snp['app'] = nil
        snp['unregister'] = true
        snp.auto_unregister.should be_nil
      end
      snp_open do |snp|
        snp.instance_variable_get(:@config).config.delete('app')
        snp['unregister'] = true
        snp.auto_unregister.should be_nil
      end
      snp_open do |snp|
        snp['app'] = ""
        snp['unregister'] = true
        snp.auto_unregister.should be_nil
      end
    end
  end

  describe "#autoexecute_with_config!" do
    before do
      @classname, @classtitle = 'classname', 'classtitle'
      @classes = [[@classname, @classtitle]]
      @title, @text = 'title', 'text'
      @notifications = {'title' => @title, 'text' => @text}
    end

    it "do register and add_class and notification automatically" do
      res_register = "type=SNP#?version=1.0#?action=register#?app=#{@app}\r\n"
      res_add_class = "type=SNP#?version=1.0#?action=add_class#?app=#{@app}#?class=#{@classname}#?title=#{@classtitle}\r\n"
      res_notification = "type=SNP#?version=1.0#?action=notification#?app=#{@app}#?title=#{@title}#?text=#{@text}#?timeout=10\r\n"
      expected = [res_register, res_add_class, res_notification]
      snp_open do |snp|
        snp['app'] = @app
        snp['add_class'] = @classes
        snp['notification'] = @notifications
        snp.autoexecute_with_config!.flatten.map{|res| res.request_str}.should eql(expected)
      end
    end
    it "do nothing if no snp['app'] and snp['add_class'] and snp['notification']" do
      snp_open do |snp|
        snp.instance_variable_get(:@config).config.delete('app')
        snp.instance_variable_get(:@config).config.delete('add_class')
        snp.instance_variable_get(:@config).config.delete('notification')
        snp.autoexecute_with_config!.flatten.should eql([nil, nil, nil])
      end
    end
  end

  describe "#apply_yaml" do
    it "apply yamldata to snp" do
      app, classname = 'app', 'class'
      yamldata = "app : #{app}\nclass : #{classname}\n"
      snp_open do |snp|
        snp['app'].should be_nil
        snp['class'].should be_nil
        snp.apply_yaml(yamldata)
        snp['app'].should eql(app)
        snp['class'].should eql([[classname, nil]])
      end
    end
  end

  # describe "#set_logger" #=> real_connection_spec.rb
end
