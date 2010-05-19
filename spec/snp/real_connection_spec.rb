require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Snarl::SNP" do

  before :all do
    @host = SNARL_HOST # from spec_helper
    @port = SNARL_PORT # from spec_helper
    @app = Snarl::SNP::DEFAULT_TITLE
    @class = '1'
  end

  describe ".open{|snp| ...}" do
    it "supplies Snarl::SNP object block" do
      Snarl::SNP.open(@host, @port) do |snp|
        snp.notification('hello Snarl::SNP test!', 10)
      end
    end
  end

  def snp_open(&block)
    snp = Snarl::SNP.new(@host, @port)
    block.call(snp)
  end

  it "full SNP popup procedure goes well" do
    lambda{
      snp_open do |snp|
        snp.register(@app)
        snp.add_class(@class, 'classtitle')
        res = snp.notification('tit', 'tex(no icon popups)', 'ico', 9, @class)
        snp.unregister(@app)
      end
    }.should_not raise_error
  end

  describe "#register" do
    it "twice raises error SNP_ERROR_ALREADY_REGISTERED" do
      snp_open do |snp|
        snp.register(@app)
        snp.verbose = true
        lambda{snp.register(@app)}.should raise_error(Snarl::SNP::Error::SNP_ERROR_ALREADY_REGISTERED)
        snp.unregister(@app)
      end
    end
    it "empty app raises error SNP_ERROR_BAD_PACKET" do
      snp_open do |snp|
        snp.verbose = true
        lambda{snp.register('')}.should raise_error(Snarl::SNP::Error::SNP_ERROR_BAD_PACKET)
      end
    end
  end

  describe "#add_class" do
    it "empty classtitle raises no error" do
      snp_open do |snp|
        snp.register(@app)
        snp.verbose = true
        lambda{snp.add_class(@class)}.should_not raise_error(Snarl::SNP::Error)
        snp.unregister(@app)
      end
    end
    it "add same class raises error SNP_ERROR_CLASS_ALREADY_EXISTS" do
      snp_open do |snp|
        snp.register(@app)
        snp.add_class(@class)
        snp.verbose = true
        lambda{snp.add_class(@class)}.should raise_error(Snarl::SNP::Error::SNP_ERROR_CLASS_ALREADY_EXISTS)
        snp.unregister(@app)
      end
    end
    it "empty class raises error SNP_ERROR_BAD_PACKET" do
      snp_open do |snp|
        snp.register(@app)
        snp.verbose = true
        lambda{snp.add_class('')}.should raise_error(Snarl::SNP::Error::SNP_ERROR_BAD_PACKET)
      end
    end
  end

  describe "#notification" do
    it "'anonymous-class' notification is not considered as a bad packet" do
      snp_open do |snp|
        lambda{
          snp.register(@app)
          snp.verbose = true
          snp.notification(:text => 'anonymous class test', :timeout => '2')
        }.should_not raise_error(Snarl::SNP::Error)
      end
    end
    it "'anonymous-app' notification is not considered as a bad packet" do
      snp_open do |snp|
        lambda{
          snp.verbose = true
          snp.notification(:text => 'anonymous app test', :timeout => '2')
        }.should_not raise_error(Snarl::SNP::Error)
      end
    end
  end

  describe "#unregister" do
    it "unregister before registering raises error SNP_ERROR_NOT_REGISTERED" do
      snp_open do |snp|
        snp.unregister(@app)
        snp.verbose = true
        lambda{snp.unregister(@app)}.should raise_error(Snarl::SNP::Error::SNP_ERROR_NOT_REGISTERED)
      end
    end
    it "empty app raises error SNP_ERROR_BAD_PACKET" do
      snp_open do |snp|
        snp.verbose = true
        lambda{snp.unregister('')}.should raise_error(Snarl::SNP::Error::SNP_ERROR_BAD_PACKET)
      end
    end
  end

  describe "#hello" do
    it "returns Snarl release identifier" do
      snp_open do |snp|
        snp.hello.infomation.should match(/\ASnarl /)
      end
    end
  end

  describe "#version" do
    it "returns Snarl (inner) version" do
      snp_open do |snp|
        snp.version.infomation.should match(/[\d\.]+/)
      end
    end
  end

  describe "#request" do
    it "misspelling action raises SNP_ERROR_BAD_PACKET" do
      snp_open do |snp|
        lambda{
          snp.request("type=SNP#?version=1.0#?action=notification2#?app=#{@app}#?title=err!#?text=this never popup#?timeout=10\r\n")
        }.should raise_error(Snarl::SNP::Error::SNP_ERROR_BAD_PACKET)
      end
    end
  end

  # FIXME: I have no idea to let class methods run under #stub!

  describe ".ping" do
    it "ping" do
      expected = "type=SNP#?version=1.0#?action=notification#?title=Ruby-Snarl#?text=Ruby Snarl-SNP Ping Message#?timeout=10#?icon=3\r\n"
      Snarl::SNP.ping(@host).request_str.should eql(expected)
    end
  end

  describe ".show_message" do
    it "show_message(host, port, title, text, timeout, icon) shows popup message" do
      expected = "type=SNP#?version=1.0#?action=notification#?title=snp_spec#?text=test mesage#?timeout=2#?icon=icon\r\n"
      Snarl::SNP.show_message(@host, @port, 'snp_spec', 'test mesage', 2, 'icon').request_str.should eql(expected)
    end
    it "if port Integer is omitted, (host, title, text, timeout, icon) is treated as (host, nil, title, text, timeout, icon)" do
      expected = "type=SNP#?version=1.0#?action=notification#?title=snp_spec#?text=test mesage#?timeout=2#?icon=icon\r\n"
      Snarl::SNP.show_message(@host, 'snp_spec', 'test mesage', 2, 'icon').request_str.should eql(expected)
    end
  end

  # ============================================
  # snp_procedure.rb

  describe ".load" do
    it "SNP.load(yaml){...} loads yaml and executes as SNP" do
      yaml = <<EOY # for bypassing emacs ruby-mode indent bug, 'class : ...' is '"class" : ...'
host : #{@host}
port : #{@port}
app : Ruby-Snarl
"class" : class1
EOY
      lambda{
        Snarl::SNP.load(yaml) do |snp|
          snp.notification('yaml load test')
        end
      }.should_not raise_error
    end
    it "SNP.load(yaml_with_notify) loads yaml and executes as SNP automatically" do
      yaml = <<EOY # for bypassing emacs ruby-mode indent bug, 'class : ...' is '"class" : ...'
host : #{@host}
port : #{@port}
app : Ruby-Snarl
"class" : class1
title : yaml test
text : hello,yaml!
EOY
      lambda{
        Snarl::SNP.load(yaml) do |snp|
          snp.notification('yaml load test')
        end
      }.should_not raise_error
    end
    it "SNP.load(yaml, Logger.new){...} puts SNPProcedure log to Logger" do
      sio = StringIO.new
      logger = Logger.new(sio)
      yaml = <<EOY
host : #{@host}
port : #{@port}
app : Ruby-Snarl
EOY
      expected = Regexp.quote('register: "type=SNP#?version=1.0#?action=register#?app=Ruby-Snarl')
      Snarl::SNP.load(yaml, logger) do |snp|
      end
      sio.rewind
      sio.read.should match(expected)
    end
  end

  describe "#set_logger" do
    before :all do
      @yaml = <<EOY
host : #{@host}
port : #{@port}
app : Ruby-Snarl
EOY
    end

    before do
      @logpath = Tempfile.new('snarlsnprealconnectionspecrb').path
    end

    it "set logger_obj as snp['logger'] when load(yaml, logger_obj)" do
      logger = Logger.new(@logpath)
      Snarl::SNP.load(@yaml, logger) do |snp|
        snp.logger.should eql(logger)
      end
    end

    it "set Logger.new(string) as snp['logger'] when load(yaml, string)" do
      logger = @logpath
      expected = Regexp.quote('register: "type=SNP#?version=1.0#?action=register#?app=Ruby-Snarl')
      Snarl::SNP.load(@yaml, logger) do |snp|
      end
      File.open(logger){|f| f.read}.should match(expected)
    end

    it "set Logger.new(logpath) as snp['logger'] when load(\"logfile : logpath\")" do
      yaml = "#{@yaml}\nlogfile : #{@logpath}"
      expected = Regexp.quote('register: "type=SNP#?version=1.0#?action=register#?app=Ruby-Snarl')
      Snarl::SNP.load(yaml) do |snp|
      end
      File.open(@logpath){|f| f.read}.should match(expected)
    end

    it "set lvl to Logger.new(file_y).level when load(\"logfile : file_y\\nloglevel : lvl\")" do
      loglevel = 4
      yaml = "#{@yaml}\nlogfile : #{@logpath}\nloglevel : #{loglevel}"
      Snarl::SNP.load(yaml) do |snp|
        snp.logger.level.should eql(loglevel)
      end
    end

    it "does not set lvl to load_arg_logger.level when load(\"loglevel : lvl\", load_arg_logger)" do
      loglevel = 4
      logger = @logpath
      yaml = "#{@yaml}\nloglevel : #{loglevel}"
      Snarl::SNP.load(yaml, logger) do |snp|
        snp.logger.level.should_not eql(loglevel)
        snp.logger.level.should eql(0)
      end
    end
  end

  # =============================================
  # bin/snarl_snp.rb
  if defined?(TEST_SNARL_SNP_BIN_SPEC) then
    class ::SNPBin
      remove_const :"BINCMD_OPTION"
    end
  else
    TEST_SNARL_SNP_BIN_SPEC=true
  end
  load File.expand_path(File.dirname(__FILE__) + '/../../bin/snarl_snp')

  describe "SNPBin" do

    before :all do
      @argv_bak = ARGV.dup
    end
    after :all do
      ARGV.replace(@argv_bak)
    end

    describe "run" do
      it "#exec_snplib" do
        arg = ['-H', SNARL_HOST, '-p', SNARL_PORT.to_s, '-a', 'Ruby-Snarl', '-c', 'class', '-m', 'exec text']
        ARGV.replace([__FILE__] + arg)
        lambda{
          SNPBin.new.run
        }.should_not raise_error
      end
    end
  end
end
