
# when config file exists, require this config
class Snarl
  class SNP
    class Config

      DEFAULT_HOST = '127.0.0.1'
      DEFAULT_PORT = 9887
      @host = nil
      @port = nil

      def self.host
        @host || ENV['SNARL_HOST'] || DEFAULT_HOST
      end
      def self.host=(v)
        @host = if v then v.to_s else nil end
      end

      def self.port
        @port || ENV['SNARL_PORT'] || DEFAULT_PORT
      end
      def self.port=(v)
        @port = if v then v.to_i else nil end
      end

      def self.reset
        self.host = nil
        self.port = nil
      end
    end
  end
end
