require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Snarl::SNP::Config" do

  before :all do
    @host   = '0.0.0.0'
    @port   = 9876
    @app    = 'app'
    @class1 = 'class1'
    @classtitle1 = @class1 + 'title'
    @class2 = 'class2'
    @class3 = 'class3'
    @title = 'title'
    @timeout = 9
    @icon = 'icon.jpg'
    @text = 'text'

    # just only for bypassing emacs ruby-mode indent bug, class is "class"
    @yaml = <<YAML
host : #{@host}
port : #{@port}
app  : #{@app}
"class" :
  - [#{@class1}, #{@classtitle1}]
  - [#{@class2}]
  - #{@class3}
notification :
  title : #{@title}
  text : #{@text}
  timeout : #{@timeout}
  icon : #{@icon}
  "class" : #{@class1}
unregister : false
logfile : $stdout
loglevel : 0
YAML
  end

  before do
  end

  describe ".initialize" do
    before :all do
      @backup_host = ENV['SNARL_HOST']
      @backup_port = ENV['SNARL_PORT']
    end
    after :all do
      ENV['SNARL_HOST'] = @backup_host
      ENV['SNARL_PORT'] = @backup_port
    end

    it "When ENV['SNARL_PORT'] is nil, default host is 127.0.0.1" do
      ENV['SNARL_HOST'] = nil
      Snarl::SNP::Config.new['host'].should eql('127.0.0.1')
    end
    it "When ENV['SNARL_PORT'] is set, default host is SNARL_HOST" do
      ENV['SNARL_HOST'] = '192.168.0.2'
      Snarl::SNP::Config.new['host'].should eql('192.168.0.2')
    end

    it "When ENV['SNARL_PORT'] is nil, default port is 9887.to_i" do
      ENV['SNARL_PORT'] = nil
      Snarl::SNP::Config.new['port'].should eql(9887)
    end
    it "When ENV['SNARL_PORT'] is set, default port is SNARL_PORT.to_i" do
      ENV['SNARL_PORT'] = '12345'
      Snarl::SNP::Config.new['port'].should eql(12345)
    end
  end

  describe "#[]=" do
    it "config['app'] = 'appname' works" do
      appname = 'appname'
      config = Snarl::SNP::Config.new
      config['app'] = appname
      config.instance_variable_get(:@config)['app'].should eql(appname)
    end
    it "Symbol key converts to String. config[':app'] = 'appname' works" do
      appname = 'appname'
      config = Snarl::SNP::Config.new
      config[:app] = appname
      config.instance_variable_get(:@config)['app'].should eql(appname)
    end
  end

  describe "#[]" do
    it "returns @config[k]" do
      appname = 'appname'
      config = Snarl::SNP::Config.new
      config.instance_variable_get(:@config)['app'] = appname
      config['app'].should eql(appname)
    end
  end

  describe "Config" do

    describe ".store" do
      it "normalize pair and store to hash" do
        expected = {
          "host"         => "0.0.0.0",
          "port"         => 9876,
          "app"          => "app",
          "class"        => [["class1", "class1title"], ["class2", nil], ["class3", nil]],
          "notification" => {
            "title"   => "title",
            "text"    => "text",
            "timeout" => 9,
            "icon"    => "icon.jpg",
            "class"   => "class1",
          },
          "unregister"   => false,
          "logfile"      => $stdout,
          "loglevel"     => 0
        }
        actual = {}
        YAML.load(@yaml).each do |k, v|
          Snarl::SNP::Config::Normalize.store(k, v, actual)
        end
        actual.should eql(expected)
      end
    end

    describe "#extract_classes" do
      def extract_classes(v)
        Snarl::SNP::Config::Normalize.new('dum','my').__send__(:extract_classes, v)
      end

      it "if [[class1, title1]], return as is" do
        actual = [['class1', 'title1']]
        expected = actual
        extract_classes(actual).should eql(expected)
      end
      it "if [classonly], returns [[classonly, nil]]" do
        actual = ['class1']
        expected = [['class1', nil]]
        extract_classes(actual).should eql(expected)
      end
      it "if is String, returns [[string, nil]]" do
        actual = 'class1'
        expected = [['class1', nil]]
        extract_classes(actual).should eql(expected)
      end
      it "if is nil, returns nil" do
        actual = nil
        expected = nil
        extract_classes(actual).should eql(expected)
      end
    end

    describe "#extract_loglevel" do
      def extract_loglevel(v)
        Snarl::SNP::Config::Normalize.new('dum','my').__send__(:extract_loglevel, v)
      end

      it "if integer string, returns s.to_i" do
        extract_loglevel('1').should eql(1)
      end
      it "if yaml_undef, returns 0" do
        extract_loglevel(nil).should eql(0)
        extract_loglevel('').should eql(0)
      end
      it "if .to_s matches /\A(debug|info|warn|error|fatal)\Z/i, returns 0-4" do
        extract_loglevel('debug').should eql(0)
        extract_loglevel('INFO').should eql(1)
        extract_loglevel('Warn').should eql(2)
        extract_loglevel(:error).should eql(3)
        extract_loglevel(:FATAL).should eql(4)
      end
      it "if unknown str, returns 0" do
        extract_loglevel('foo').should eql(0)
      end
    end

    describe "#extract_logfile" do
      def extract_logfile(v)
        Snarl::SNP::Config::Normalize.new('dum','my').__send__(:extract_logfile, v)
      end

      it "if '$stdout' or '$stderr', returns its IO object" do
        extract_logfile('$stdout').should eql($stdout)
        extract_logfile('$stderr').should eql($stderr)
      end
      it "returns it as is unless $stdout or $stderr" do
        actual = expected = 'logfile'
        extract_logfile(actual).should eql(expected)
      end
    end

    describe "#normalize" do
      def normalize(k, v)
        Snarl::SNP::Config::Normalize.new(k, v).normalize
      end
      # ah...
      # pending('I do not want to write now')
    end
  end
end
