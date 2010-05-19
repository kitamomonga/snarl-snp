class Snarl # conpat for ruby-snarl

  class SNP

    include Action
    include SNPProcedure

    # default "timeout command" value. popup disappers in 10 seconds.
    DEFAULT_TIMEOUT = 10

    # default title for "non-title" notification
    DEFAULT_TITLE = 'Ruby-Snarl'

    # Snarl::SNP.new('127.0.0.1', 9887)
    def initialize(host=nil, port=nil, verbose=false, &block)
      @config = Config.new
      if host && YAML.load(host).kind_of?(Hash) then
        port.respond_to?(:debug) ? load(host, port, &block) : load(host, nil, &block)
      else
        self['host'] = host
        self['port'] = port
        self['verbose'] = verbose
        yield(self) if block_given?
      end
    end
    attr_reader :config

    def []=(k, v) ; @config[k] =v ; end
    def [](k) ; @config[k] ; end

    # When you set it true, all unimportant SNP errors raise.
    # Default is false, Snarl::SNP::Error::Casual are disabled.
    def verbose=(v) ; self['verbose'] = v ; end
    def verbose ; self['verbose'] ; end

#    # a value of SNP command "app".
#    attr_reader :app
#
#    attr_accessor :title

#    # a value of SNP command "timeout".
#    attr_accessor :timeout

    # set Logger object. It is used when sending request and getting response.
    def logger=(logger)
      self['logger'] = (logger.kind_of?(Class) ? logger.new($stdout) : logger)
    end
    def logger ; self['logger'] ; end

    # send Snarl::SNP::Request/Hash/String and get Snarl::SNP::Response fron Snarl.
    # When the response "fatal" response, raise errors.
    # When method +verbose+ returns true, "casual" errors also raises.
    def request(req)
      req = Request.new(req) if req.kind_of?(Hash)
      action = if req.kind_of?(Request) then req.action else '(string)' end
      debug("#{action}: #{req.inspect}")
      begin
        res = get_response(req)
        info("#{action}: #{res.inspect}")
      rescue Error::Casual => ex
        info("#{action}: (ignored) #{ex.message}")
        raise if verbose
        res = ex.response
      rescue Error::Fatal => ex
        error("#{action}: #{ex.message}")
        raise
      rescue Errno::ECONNREFUSED => ex
        error("#{ex.message} / #{self['host'].inspect}:#{self['port'].inspect}")
        raise
      end
      return res
    end

    # SHORTCUT METHODS ----------------

    # add_classes('type1', 'type2', 'type3')
    # add_classes(['type1', desc1], ['type2', desc2], ['type3', desc3])
    # add_classes(*array_of_pairs)
    # returns [add_class_response1, add_class_response2, add_class_response3]
    def add_classes(*classes)
      classes.map{|e| e.kind_of?(String) ? [e, nil] : e}.map{|p| add_class(*p)}
    end

    # returns icon path if SNP knows. optional.
    def icon(s)
      if self['iconset'] && self['iconset'].has_key?(s) then self['iconset'][s] else s end
    end

    # set icons pair. quite optional.
    #   snp.iconset({:red => 'red.jpg'})
    #   snp.notification('title', 'text', :red) #=> sends "icon=red.jpg"
    #   snp.notification('title', 'text', 'blue') #=> sends "icon=blue"
    def iconset(icons) ; self['iconset'] = icons ; end
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

    # send message only. app and class is "anonymous".
    #   Snarl::SNP.show_message(host, 9887, title, text, timeout, icon)
    #   Snarl::SNP.show_message(host, title, text, timeout, icon)
    #   Snarl::SNP.show_message(host, title, text)
    #   Snarl::SNP.show_message(host, text)
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

    def send(req)
      # normalize just before using # FIXME:
      TCPSocket.open(self['host'], self['port']) do |s|
        s.write(req)
        s.gets
      end
    end

    def get_response(req)
      res = Response.new(send(req))
      res.request = req
      res
    end

    def error(m); logger.error(m) if logger ; end
    def info(m);  logger.info(m)  if logger ; end
    def debug(m); logger.debug(m) if logger ; end

  end
end
