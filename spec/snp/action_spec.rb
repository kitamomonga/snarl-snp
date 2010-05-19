require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "SNP" do

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

  describe "#register" do
    it "makes valid SNP command string" do
      expected = "type=SNP#?version=1.0#?action=register#?app=#{@app}\r\n"
      snp_open do |snp|
        snp.register(@app).request_str.should eql(expected)
      end
    end
  end

  describe "#unregister" do
    it "makes valid SNP command string" do
      expected = "type=SNP#?version=1.0#?action=unregister#?app=#{@app}\r\n"
      snp_open do |snp|
        snp.unregister(@app).request_str.should eql(expected)
      end
    end
    it "raises error when snp has no @app yet" do
      snp_open do |snp|
        lambda{snp.unregister}.should raise_error(RuntimeError)
      end
    end
  end

  describe "#add_class" do
    describe "makes valid SNP command string" do
      it "snp.add_class(clsname) has class=clsname" do
        expected = "type=SNP#?version=1.0#?action=add_class#?app=#{@app}#?class=#{@class}\r\n"
        snp_open do |snp|
          snp.register(@app)
          snp.add_class(@class).request_str.should eql(expected)
        end
      end
      it "snp.add_class(clsname, clstitle) has class=clsname#?title=clstitle" do
        clstitle = 'classtitle'
        expected = "type=SNP#?version=1.0#?action=add_class#?app=#{@app}#?class=#{@class}#?title=#{clstitle}\r\n"
        snp_open do |snp|
          snp.register(@app)
          snp.add_class(@class, clstitle).request_str.should eql(expected)
        end
      end
    end
    it "raises error when snp has no @app yet" do
      clstitle = 'classtitle'
      snp_open do |snp|
        lambda{snp.add_class(@class, clstitle)}.should raise_error(RuntimeError)
      end
    end
  end

  describe "#notification" do
    describe "makes valid SNP command string" do
      it "sends title, text, icon, timeout, class" do
        expected = "type=SNP#?version=1.0#?action=notification#?app=Ruby-Snarl#?class=cls#?title=tit#?text=tex(4 no icon popups)#?timeout=9#?icon=ico\r\n"
        snp_open do |snp|
          snp.register(@app)
          snp.add_class(@class)
          res = snp.notification('tit', 'tex(4 no icon popups)', 'ico', 9, 'cls')
          res.request_str.should eql(expected)
        end
      end
      it "sends keyword-hash, keys=[:title, :text, :icon, :timeout, :class]" do
        expected = "type=SNP#?version=1.0#?action=notification#?app=Ruby-Snarl#?class=cls#?title=tit#?text=tex#?timeout=9#?icon=ico\r\n"
        snp_open do |snp|
          snp.register(@app)
          snp.add_class(@class)
          res = snp.notification(:title => 'tit', :text => 'tex', :icon => 'ico', :timeout => 9, :class => 'cls')
          res.request_str.should eql(expected)
        end
      end
      it "sends 'anonymous' message if not registered yet" do
        expected = "type=SNP#?version=1.0#?action=notification#?title=tit#?text=tex#?timeout=9#?icon=ico\r\n"
        snp_open do |snp|
          res = snp.notification('tit', 'tex', 'ico', 9)
          res.request_str.should eql(expected)
        end
      end
      it "sends 'anonymous' message if keyhash has {:app => nil} pair" do
        expected = "type=SNP#?version=1.0#?action=notification#?title=tit#?text=tex#?timeout=9#?icon=ico\r\n"
        snp_open do |snp|
          res = snp.notification(:app => nil, :title => 'tit', :text => 'tex', :icon => 'ico', :timeout => 9)
          res.request_str.should eql(expected)
        end
      end
    end
  end

  describe "#hello" do
    it "makes valid SNP command string" do
      expected = "type=SNP#?version=1.0#?action=hello\r\n"
      snp_open do |snp|
        snp.hello.request_str.should eql(expected)
      end
    end
  end

  describe "#version" do
    it "makes valid SNP command string" do
      expected = "type=SNP#?version=1.0#?action=version\r\n"
      snp_open do |snp|
        snp.version.request_str.should eql(expected)
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
    it "['text'] returns {:title => snp.title, :text => 'text', :timeout => DEFAULT_TIMEOUT}, when snp['title'] is set" do
      params = ['text']
      snp = Snarl::SNP.new
      snp['title'] = 'snp.title'
      expected = {:action => 'notification', :title => 'snp.title', :text => "text", :timeout => @default_timeout}
      snp.__send__(:normalize_notification_params, params).should eql(expected)
    end
    it "['text', 9] returns {:title => DEFAULT_TITLE, :text => 'text', :timeout => 9}" do
      params = ['text', 9]
      expected = {:action => 'notification', :title => @default_title, :text => "text", :timeout => 9}
      normalize_notification_params(params).should eql(expected)
    end
    it "['text', 9] returns {:title => snp.title, :text => 'text', :timeout => 9}, when snp['title'] is set" do
      params = ['text', 9]
      snp = Snarl::SNP.new
      snp['title'] = 'snp.title'
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
      app = 'app'
      snp = Snarl::SNP.new
      snp['app'] = app
      expected = {:action => 'notification', :app => app, :title => @default_title, :text => "text", :timeout => @default_timeout}
      snp.__send__(:normalize_notification_params, params).should eql(expected)
    end
    it "if @app is nil, app is unset" do
      params = [{:text => 'text'}]
      snp = Snarl::SNP.new
      snp['app'] = nil
      expected = {:action => 'notification', :title => @default_title, :text => "text", :timeout => @default_timeout}
      snp.__send__(:normalize_notification_params, params).should eql(expected)
    end
    it "title == param['title'] || snp['title'] || 'Ruby-Snarl'" do
      param_title = 'param_title'
      snp_title = 'snp_title'

      params = [{:title => param_title}]
      Snarl::SNP.new do |snp|
        snp['title'] = snp_title
        snp.__send__(:normalize_notification_params, params)[:title].should eql(param_title)
      end

      params = [{}]
      Snarl::SNP.new do |snp|
        snp['title'] = snp_title
        snp.__send__(:normalize_notification_params, params)[:title].should eql(snp_title)
      end

      params = [{}]
      Snarl::SNP.new do |snp|
        snp.__send__(:normalize_notification_params, params)[:title].should eql(Snarl::SNP::DEFAULT_TITLE)
      end
    end
    it "timeout == param['timeout'] || snp['timeout'] || 10" do
      param_timeout = 11
      snp_timeout = 12

      params = [{:timeout => param_timeout}]
      Snarl::SNP.new do |snp|
        snp['timeout'] = snp_timeout
        snp.__send__(:normalize_notification_params, params)[:timeout].should eql(param_timeout)
      end

      params = [{}]
      Snarl::SNP.new do |snp|
        snp['timeout'] = snp_timeout
        snp.__send__(:normalize_notification_params, params)[:timeout].should eql(snp_timeout)
      end

      params = [{}]
      Snarl::SNP.new do |snp|
        snp.__send__(:normalize_notification_params, params)[:timeout].should eql(Snarl::SNP::DEFAULT_TIMEOUT)
      end
    end
    it "icon == iconset(param['icon']) || param['icon'] || snp['icon'] || #unset" do
      set_icon = ':set_icon'
      param_icon = 'param_icon'
      snp_icon = 'snp_icon'

      params = [{:icon => :set_icon}]
      Snarl::SNP.new do |snp|
        snp['iconset'] = {:set_icon => set_icon}
        snp['icon'] = snp_icon
        snp.__send__(:normalize_notification_params, params)[:icon].should eql(set_icon)
      end

      params = [{:icon => param_icon}]
      Snarl::SNP.new do |snp|
        snp['icon'] = snp_icon
        snp.__send__(:normalize_notification_params, params)[:icon].should eql(param_icon)
      end

      params = [{}]
      Snarl::SNP.new do |snp|
        snp['icon'] = snp_icon
        snp.__send__(:normalize_notification_params, params)[:icon].should eql(snp_icon)
      end

      params = [{}]
      Snarl::SNP.new do |snp|
        snp.__send__(:normalize_notification_params, params).should_not have_key(:icon)
      end
    end
  end
end
