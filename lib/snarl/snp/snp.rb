class Snarl # conpat for ruby-snarl

  class SNP

    include Action

    # default "timeout command" value. popup disappers in 10 seconds.
    DEFAULT_TIMEOUT = 10

    # default title for "non-title" notification
    DEFAULT_TITLE = 'Ruby-Snarl'

    # Snarl::SNP.new('127.0.0.1', 9887)
    def initialize(host=nil, port=nil, verbose=false)
      @host = host
      @port = port
      @verbose = verbose
      @logger = nil
      @app = nil
      @timeout = nil
      @iconset = {}
      @title = nil
    end

    # When you set it true, all unimportant SNP errors raise.
    # Default is false, Snarl::SNP::Error::Casual are disabled.
    attr_accessor :verbose

    # a value of SNP command "app".
    attr_reader :app

    attr_accessor :title

    # a value of SNP command "timeout".
    attr_accessor :timeout

    # set Logger object. It is used when sending request and getting response.
    def logger=(logger)
      @logger = (logger.kind_of?(Class) ? logger.new($stdout) : logger)
    end

    # send Snarl::SNP::Request/Hash/String and get Snarl::SNP::Response fron Snarl.
    # When the response "fatal" response, raise errors.
    # When method +verbose+ returns true, "casual" errors also raises.
    def request(req)
      req = Request.new(req) if req.kind_of?(Hash)
      debug(req)
      begin
        action = req.kind_of?(Request) ? req.action : '(string)'
        res = get_response(req)
        info("#{action}: #{res.inspect}")
      rescue Error::Casual => ex
        info("#{action}: (ignored) #{ex.message}")
        raise if verbose
      rescue Error::Fatal => ex
        info("#{action}: #{ex.message}")
        raise
      end
      return res
    end

    # SHORTCUT METHODS ----------------

    # add_classes('type1', 'type2', 'type3')
    # add_classes(['type1', desc1], ['type2', desc2], ['type3', desc3])
    def add_classes(*classes)
      classes.each do |classpair|
        classpair = [classpair, nil] if classpair.kind_of?(String)
        add_class(*classpair)
      end
    end

    # returns icon path if SNP knows. optional.
    def icon(s)
      if @iconset.has_key?(s) then @iconset[s] else s end
    end

    # set icons pair. quite optional.
    #   snp.iconset(:red => 'red.jpg')
    #   snp.notification('title', 'text', :red) #=> sends "icon=red.jpg"
    #   snp.notification('title', 'text', 'blue') #=> sends "icon=blue"
    def iconset(icons)
      @iconset = icons
    end
    alias :icons :iconset

    def ping
      notification(DEFAULT_TITLE, 'Ruby Snarl-SNP Ping Message', 3, nil)
    end

    alias :message :notification

    def snarl_hello
      hello.infomation
    end

    def snarl_version
      version.infomation
    end

    #   Snarl::SNP.open(host, port){|snp| snp.register ... }
    # "ensure block" is empty. TCPSocket is closed per access.
    def self.open(host=nil, port=nil, verbose=false, &block)
      client = new(host, port, verbose)
      yield(client) # socket always closed in TCPSocket#open{...}
      client
    end

    # send message only. app is "anonymous".
    #   Snarl::SNP.show_message(host, 9887, title, text, tomeout, icon)
    #   Snarl::SNP.show_message(host, title, text, tomeout, icon)
    def self.show_message(host, port, title=nil, text=nil, timeout=nil, icon=nil)
      # TODO: (host, title, text, 10)
      if port.kind_of?(String) && icon.nil? then
        port, title, text, timeout, icon = nil, port, title, text, timeout
      end
      new(host, port).notification(:title => title, :text => text, :timeout => timeout, :icon => icon)
    end

    def self.ping(host=nil, port=nil)
      new(host, port).ping
    end
    # ----------------- SHORTCUT METHODS

    private

    def get_response(req)
      host = @host || Config.host
      port = @port || Config.port
      TCPSocket.open(host, port) do |s|
        s.write(req)
        res = Response.new(s.gets)
        res.request = req
        res
      end
    end

    def info(m); @logger.info(m) if @logger; end
    def debug(m); @logger.debug(m) if @logger; end

  end
end
