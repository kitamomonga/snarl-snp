require 'yaml' # some users don't use rubygems
class Snarl
  class SNP
    module SNPProcedure
      def is_app_available? ; self['app'] && !self['app'].empty? ; end
      def auto_register
        if is_app_available? then
          register(self['app'])
        end
      end

      def is_class_available? ; self['class'] && !self['class'].empty? ; end
      def auto_add_class
        if is_app_available? && is_class_available? then
          add_classes(*self['class'])
        end
      end

      def is_notification_available? ; self['notification'] && !self['notification'].empty? ; end
      def auto_notification
        _notify_arg_is_array = is_notification_available? && self['notification'].kind_of?(Array)
        _notify_arg_is_arraied_notify_hashes = is_notification_available? && self['notification'].first.kind_of?(Hash)

        if is_notification_available? then
          if _notify_arg_is_array then
            if _notify_arg_is_arraied_notify_hashes then
              # [{notify_hash1}, {notify_hash2}, ...]
              self['notification'].map{|h| notification(h)}
            else
              # [title, text, timeout, icon, class]
              notification(*self['notification'])
            end
          else
            # {notify_hash}
            notification(self['notification'])
          end
        else # config has no 'notification' key
          # build notify arg from config
          h = {}
          h[:app] = self['app'] if self['app']
          h[:title] = self['title'] if self['title']
          h[:text] = self['text'] if self['text']
          h[:timeout] = self['timeout'] if self['timeout']
          h[:icon] = self['icon'] if self['icon']
          h[:class] = self['class'][0][0] if is_class_available? # snp['class'] == [['clsnam', 'clstit']]
          notification(h) if (h.has_key?(:text)||h.has_key?(:title))
        end
      end

      private :is_app_available?, :is_class_available?, :is_notification_available?

      def auto_unregister
        if self['unregister'] && is_app_available? then
          unregister(self['app'])
        end
      end

      def autoexecute_with_config!
        [auto_register,
         auto_add_class,
         auto_notification]
      end

      def apply_yaml(yamldata)
        YAML.load(yamldata).each do |k ,v|
          self[k] = v
        end
      end

      def set_logger(arg_logger)
        # TODO: support for another Logger
        if arg_logger then
          require 'logger' # FIXME: oh twice?
          arg_logger = Logger.new(arg_logger) unless arg_logger.respond_to?(:warn)
          self.logger = arg_logger
        elsif self['logfile'] then
          require 'logger' # FIXME: oh ...
          logger = Logger.new(self['logfile'])
          logger.level = self['loglevel'] if self['loglevel']
          self.logger = logger
        else
          # do nothing
        end
      end

      def load(yamldata, logger = nil, &block)
        apply_yaml(yamldata)
        # apply/overwrite user Logger object
        # yaml cannot make 'raw' Logger object
        set_logger(logger)
        begin
          autoexecute_with_config!
          block.call(self) if block_given?
        ensure
          auto_unregister
        end
        self
      end
    end

    def self.load(*args, &block)
      self.new.load(*args, &block)
    end
  end
end
