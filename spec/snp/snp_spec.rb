require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'stringio'

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

  describe "initialize" do
    it "new('192.168.0.2', 9887). (snarl_working_machine_host, snarl_port_9887)" do
      host, port, verbose = '192.168.0.2', 9887, true
      snp = Snarl::SNP.new(host, port, verbose)
      snp['host'].should eql(host)
      snp['port'].should eql(port)
      snp.verbose.should eql(verbose)
    end
    it "default host is 127.0.0.1, default port is 9887. when SNP.new()" do
      bk_host = ENV['SNARL_HOST']
      ENV['SNARL_HOST'] = nil
      bk_port = ENV['SNARL_PORT']
      ENV['SNARL_PORT'] = nil
      snp = Snarl::SNP.new
      snp['host'].should eql('127.0.0.1')
      snp['port'].should eql(9887)
      snp.verbose.should eql(false)
      ENV['SNARL_HOST'] = bk_host
      ENV['SNARL_PORT'] = bk_port
    end
  end

  describe "#request" do

    module ErrorPair
      def self.casual_errors
        {
          'SNP/1.1/202/Not Registered' => Snarl::SNP::Error::SNP_ERROR_NOT_REGISTERED,
          'SNP/1.1/203/Already Registered' => Snarl::SNP::Error::SNP_ERROR_ALREADY_REGISTERED,
          'SNP/1.1/204/Class Already Exists' => Snarl::SNP::Error::SNP_ERROR_CLASS_ALREADY_EXISTS,
          'SNP/1.1/201/Not Running' => Snarl::SNP::Error::SNP_ERROR_NOT_RUNNING,
          'SNP/1.1/101/Failed' => Snarl::SNP::Error::SNP_ERROR_FAILED,
        }
      end

      def self.fatal_errors
        {
          'SNP/1.1/102/Unknown Connamd' => Snarl::SNP::Error::SNP_ERROR_UNKNOWN_COMMAND,
          'SNP/1.1/103/Timed Out' => Snarl::SNP::Error::SNP_ERROR_TIMED_OUT,
          'SNP/1.1/107/Bad packet' => Snarl::SNP::Error::SNP_ERROR_BAD_PACKET,
          'SNP/1.1/998/!Snarl::SNP\'s original error(unknown response code)' => Snarl::SNP::Error::RUBYSNARL_UNKNOWN_RESPONSE
        }
      end
    end

    before :all do
      @register ="type=SNP#?version=1.0#?action=register#?app=#{@app}\r\n"
      @add_class = "type=SNP#?version=1.0#?action=add_class#?app=#{@app}#?class=#{@class}\r\n"
      @notification = "type=SNP#?version=1.0#?action=notification#?app=#{@app}#?title=Raw!#?text=text!#?timeout=10\r\n"
      @unregister = "type=SNP#?version=1.0#?action=unregister#?app=#{@app}\r\n"
    end

    it "returns SNP::Response object" do
      snp_open do |snp|
        snp.request("fake").should be_kind_of(Snarl::SNP::Response)
      end
    end

    it "if argument is String, it is used as-is" do
      req_str = "fake"
      snp_open do |snp|
        snp.request(req_str).request_str.should eql(req_str)
      end
    end

    it "Hash argument is converted in SNP::Request" do
      notification = {
        :app => @app,
        :action => action = 'notification',
        :class => @class,
        :title => title = 'title',
        :text => text = 'text',
        :timeout => timeout = 9
      }
      expected = "type=SNP#?version=1.0#?action=#{action}#?app=#{@app}#?class=#{@class}#?title=#{title}#?text=#{text}#?timeout=#{timeout}\r\n"
      snp_open do |snp|
        snp.request(notification).request_str.should eql(expected)
      end
    end

    describe "if snp.logger is set, put send/get logs to logger" do

      def sio_logger(sio)
        logger = Logger.new(sio)
        logger.datetime_format = ""
        logger
      end

      def expected_log_output(str, level='DEBUG')
        /#{level[0,1]},\s+\[#\d+\]\s+#{Regexp.quote("#{level} -- : #{str}")}/
      end

      it "request string is put to log" do
        log = StringIO.new
        req_query = "type=SNP#?version=1.0#?action=notification#?title=title#?text=text#?timeout=10"
        expected =  "notification: \"#{req_query}\""
        snp_open do |snp|
          snp.logger = sio_logger(log)
          snp.notification('title', 'text')
          log.rewind
          log.read.should match(expected_log_output(expected, 'DEBUG'))
        end
      end

      it "response string is put to log" do
        log = StringIO.new
        expected = "notification: SNP/1.1/0/OK/1234/"
        snp_open do |snp|
          snp.logger = sio_logger(log)
          snp.notification('title', 'text')
          log.rewind
          log.read.should match(expected_log_output(expected, 'INFO'))
        end
      end

      it "if no casual errors raise, log has 2 lines(reqstr, response)" do
        log = StringIO.new
        snp_open do |snp|
          snp.logger = sio_logger(log)
          snp.notification('title', 'text')
          log.rewind
          log.readlines.size.should eql(2)
        end
      end

      it "casual error is put regardress of snp.verbose" do
        log = StringIO.new
        expected = "register: (ignored) (203) Application is already registered"
        snp_open do |snp|
          snp.logger = sio_logger(log)
          snp.stub!(:send).and_return('SNP/1.1/203/Application is already registered')
          snp.register('Ruby-Snarl')
          log.rewind
          log.read.should match(expected_log_output(expected, 'INFO'))
        end
      end
    end

    describe "raises no Error::Casual when respnse is casual error and setting is default(SNP#verbose is unset, false)" do
      ErrorPair.casual_errors.each_pair do |res, err|
        e = <<E
        it "not raise #{err}" do
          snp_open do |snp|
            snp.stub!(:send).and_return("#{res}")
            lambda{snp.request("fake")}.should_not raise_error(#{err})
          end
        end
E
        instance_eval(e)
      end
    end

    describe "raises Error::Casual when respnse is casual error and SNP#verbose is set to true" do
      ErrorPair.casual_errors.each_pair do |res, err|
        e = <<E
        it "raise #{err}" do
          snp_open do |snp|
            snp.verbose = true
            snp.stub!(:send).and_return("#{res}")
            lambda{snp.request("fake")}.should raise_error(#{err})
          end
        end
E
        instance_eval(e)
      end
    end

    describe "raises Error::Fatal when response is fatal error" do
      ErrorPair.fatal_errors.each_pair do |res, err|
        e = <<E
        it "raise #{err}" do
          snp_open do |snp|
            snp.stub!(:send).and_return("#{res}")
            lambda{snp.request("fake")}.should raise_error(#{err})
          end
        end
E
        instance_eval(e)
      end
    end

    describe "raises Error::Fatal when response is fatal error regardless of SNP#verbose" do
      ErrorPair.fatal_errors.each_pair do |res, err|
        e = <<E
        it "raise #{err}" do
          snp_open do |snp|
            snp.stub!(:send).and_return("#{res}")
            lambda{snp.request("fake")}.should raise_error(#{err})
          end
        end
E
        instance_eval(e)
      end
    end

    describe "returns SNP::Response when error does not raise" do
      it "when SNP/1.1/0/OK, returns its SNP::Response object" do
        snp_open do |snp|
          snp.stub!(:send).and_return("SNP/1.1/0/OK")
          snp.request("fake").inspect.should eql("SNP/1.1/0/OK")
        end
      end
      ErrorPair.casual_errors.keys.each do |res|
        e = <<E
        it "when #{res}, returns its SNP::Response object" do
          snp_open do |snp|
            snp.stub!(:send).and_return("#{res}")
            snp.request("fake").inspect.should eql("#{res}")
          end
        end
E
        instance_eval(e)
      end
    end

  end

  describe "#add_classes" do

    it "runs add_class for each argument (if Array, use add_classes(*arr))" do
      classes = [['1', 'one'], ['2', 'two']]
      snp_open do |snp|
        snp.register(@app)
        snp.stub!(:send).and_return{|req| "SNP/1.1/0/OK/#{req.to_s.scan(/class=(\d)/).flatten[0]}"}
        snp.add_classes(*classes).map{|res| res.infomation}.should eql(['1', '2'])
        snp.unregister(@app)
      end
    end
    it "runs add_class for multi_class_str each argument" do
      snp_open do |snp|
        snp.register(@app)
        snp.stub!(:send).and_return{|req| "SNP/1.1/0/OK/#{req.to_s.scan(/class=(\d)/).flatten[0]}"}
        snp.add_classes('1', '2').map{|res| res.infomation}.should eql(['1', '2'])
        snp.unregister(@app)
      end
    end
  end

  describe "#snarl_hello" do
    it "returns Snarl release identifier string without popup" do
      snp_open do |snp|
        snp.stub!(:send).and_return("SNP/1.1/0/OK/Snarl R2.21")
        expected = "Snarl R2.21"
        snp.snarl_hello.should eql(expected)
      end
    end
  end

  describe "#snarl_version" do
    it "returns Snarl (inner) version string without popup" do
      snp_open do |snp|
        snp.stub!(:send).and_return("SNP/1.1/0/OK/40.15")
        expected = "40.15"
        snp.snarl_version.should eql(expected)
      end
    end
  end

  describe "#iconset" do
    it "set icon using" do
      iconset = {:red => 'red.jpg', :blue => 'blue.jpg'}
      snp_open do |snp|
        snp.register(@app)
        snp.iconset(iconset)
        snp.notification('icon!', 'icon1!', :red, 1).request_str.should match(/icon=red\.jpg/)
        snp.notification('icon!', 'icon2!', :blue, 1).request_str.should match(/icon=blue\.jpg/)
      end
    end
  end
end
