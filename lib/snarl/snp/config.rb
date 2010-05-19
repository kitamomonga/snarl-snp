class Snarl
  class SNP
    class Config

      DEFAULT_HOST = '127.0.0.1'
      DEFAULT_PORT = 9887

      def initialize
        @config = {}
        default_config
      end

      attr_reader :config # mainly for debug

      def default_config
        self['host'] = if $SAFE > 0 then DEFAULT_HOST else ENV['SNARL_HOST'] || DEFAULT_HOST end
        self['port'] = if $SAFE > 0 then DEFAULT_PORT else ENV['SNARL_PORT'] || DEFAULT_PORT end
      end
      private :default_config

      def []=(k, v) ; Normalize.store(k, v, @config) ; end
      def [](k) ; @config[k.to_s] ; end
      def reset ; @config = {} ; end
      def to_yaml ; @config.to_yaml ; end

      class Normalize

        def self.store(k, v, hash)
          nkey, nvalue = new(k, v).normalize
          hash.store(nkey, nvalue) if nkey && nvalue != nil
        end

        def initialize(k, v)
          @key, @value = k, v
        end

        def normalize
          # NOTE: [xxx, nil] is not set to @config
          # TODO : [k, v] should be equal to {k ,v}
          v = @value
          case @key.to_s
          when 'host' then
            ['host', if is_yaml_undef?(v) then nil else v end]
          when 'port' then
            # {:port => '9887'} is {'port' => 9887}
            ['port', if is_yaml_undef?(v) then nil else v.to_i end]
          when 'app', 'application', 'name', 'register' then
            ['app', if is_yaml_undef?(v) then nil else v end]
          when 'class', 'add_class', 'classes' then
            # {:class => 'cls'} and {'add_class' => {'cls' => nil}} are {'class' => ['cls', nil]}
            ['class', extract_classes(v)]
          when 'title' then
            ['title', if is_yaml_undef?(v) then nil else v end]
          when 'text', 'body', 'msg' then
            ['text', if is_yaml_undef?(v) then nil else v end]
          when 'timeout', 'duration', 'sec' then
            ['timeout', if is_yaml_undef?(v) then 0 else v.to_i end] # "timeout: nil" is sticky
          when 'sticky' then
            ['timeout', if is_yaml_false?(v) then nil else 0 end]
          when 'icon' then # NOTE: is "this notification icon", not "iconset setting"
            ['icon', if is_yaml_undef?(v) then nil else v end]
          when 'notification', 'notify', 'message' then
            ['notification', if is_yaml_undef?(v) then nil else v end]
          when 'unregister' then
            ['unregister', if is_yaml_false?(v) then false else true end]
          when 'iconset' then
            ['iconset', if is_yaml_undef?(v) then nil else v end]

          when 'log', 'logger' then # useless on yaml?
            ['logger', v]
          when 'logfile' then
            ['logfile', extract_logfile(v)]
          when 'loglevel', 'logger.level', 'log_level' then
            ['loglevel', extract_loglevel(v)]

          when 'config' then
            ['config', if is_yaml_undef?(v) then nil else v end]
          when 'yaml' then
            ['yaml', if is_yaml_undef?(v) then nil else v end]

          else [@key.to_s, v] # or raise?
          end
        end

        private

        def is_yaml_undef?(v)
          v == 'nil' || v == nil || v == ':nil' || v == :nil || v == '' || v == [] || v == {}
        end
        def is_yaml_false?(v)
          is_yaml_undef?(v) || v == false || v == 'false' || v == :false || v == ':false'
        end

        def extract_classes(v)
          if v.kind_of?(Array) then
            res = []
            v.each do |a|
              pair = [a].flatten
              pair.push(nil) if pair.size == 1
              res << pair
            end
            return res
          elsif v.kind_of?(String)
            return [[v, nil]]
          else
            return nil
          end
        end

        def extract_logfile(v)
          if is_yaml_undef?(v) then nil else {'$stdout' => $stdout, '$stderr' => $stderr}[v.to_s] || v end
        end

        def extract_loglevel(v)
          if is_yaml_undef?(v) then
            return 0
          else
            return /\d/ =~ v.to_s ? v.to_s.to_i : (%w(DEBUG INFO WARN ERROR FATAL).index(v.to_s.upcase) || 0)
          end
        end
      end
    end
  end
end
