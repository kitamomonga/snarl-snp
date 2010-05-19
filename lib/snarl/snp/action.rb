class Snarl
  class SNP
    module Action

      NOTIFICATION_PARAM_ORDER = [:title, :text, :icon, :timeout, :class, :action, :app]

      # Sends a SNP command "register" to Snarl. For registering +app+ to Snarl setting window.
      #   snp.register('Ruby-Snarl')
      # +app+        :: an application name. Snarl uses it as an application ID.
      # Snarl::SNP keeps +app+ for add_class method and notification method.
      # +app+ default is SNP::DEFAULT_APP, 'Ruby-Snarl'.
      # Returns SNP::Response object.
      #
      # Snarl sends back a casual error when +app+ is already registered.
      # It is treated as SNP::SNPError::Casual::SNP_ERROR_ALREADY_REGISTERED.
      def register(app = nil)
        # when self['app'] == nil/unset and register(nil), SNARL receives SNP_ERROR_BAD_PACKET
        self['app'] = app if app
        cmds = {:action => 'register', :app => self['app']}
        request(Request.new(cmds))
      end
      alias :app= :register

      # Sends a SNP command "add_class" to Snarl. For adding +classid+ class and its +classtitle+ nickname.
      #   snp.add_class('green')
      #   snp.add_class('red', 'failure popup')
      # +classid+    :: classname ID on the registered application
      # +classtitle+ :: display alias for +classname+, optional
      # Returns SNP::Response object.
      # Before adding a class, you should register the application.
      #
      # Snarl sends back a casual error when +classid+ is already added.
      # It is treated as SNP::SNPError::Casual::SNP_ERROR_CLASS_ALREADY_EXISTS.
      def add_class(classid, classtitle=nil)
        # TODO: add_class(app=nil, classid, classtitle=nil)
        # type=SNP#?version=1.0#?action=add_class#?class=t returns (107) Bad Packet
        raise "registering is required. #{self}#register(appname)  before #add_class" unless self['app']
        cmds = {:action => 'add_class', :app => self['app'], :class => classid.to_s, :title => classtitle}
        request(Request.new(cmds))
      end

      # Sends SNP command "notification" to Snarl. For making a popup message itself.
      #   snp.notification('title', 'text', 'icon.jpg', 10, 'classA') # 10 is timeout Integer
      #   snp.notification(:title => 't', :text => 't', :icon => 'i.jpg', :timeout => 10, :class => 'claA')
      # +title+   :: title of popup. String.
      # +text+    :: text body of popup. String. linebreaks should be only "\n". "\r" confuses Snarl.
      # +icon+    :: icon image path of popup. String/#to_s. path on Snarl machine or http URL. bmp/jpg/png/gif.
      # +timeout+ :: display seconds of popup. Integer. if nil, DEFAULT_TIMEOUT 10. if 0, popup never closes automatically.
      # +class+   :: classid of popup. String. It should have been added by "add_class" method when you use.
      # notification(title, text, icon=nil, timeout=nil, classid=nil) or notification(keyword-hash).
      #   snp.notification('title', 'text', 10)
      #   snp.notification('title', 'text')
      #   snp.notification('text') # title == DEFAULT_APP == 'Ruby-Snarl'
      def notification(*keyhash)
        # TODO: priority
        cmds = normalize_notification_params(keyhash)
        request(Request.new(cmds))
      end
      alias :notify :notification

      # Sends SNP command "unregister" to Snarl. For removing +app+ from Snarl setting window.
      #   snp.unregister('Ruby-Snarl')
      # After this, Snarl users can not edit the settings for +app+ 's popup.
      # If you allow users to edit settings, do not send unregister.
      # Without sending unregister, the applications are always reseted when Snarl restarts.
      #
      # Snarl sends back a casual error when +app+ is not registered.
      # It is treated as SNP::SNPError::Casual::SNP_ERROR_NOT_REGISTERED.
      def unregister(app=nil)
        app = app || self['app']
        raise "#{self}#unregister requires appname." unless app
        cmds = {:action => 'unregister', :app => app}
        request(Request.new(cmds))
      end

      # Sends SNP command "hello".
      #   irb> Snarl::SNP.new('127.0.0.1').hello
      #   SNP/1.1/0/OK/Snarl R2.21
      def hello
        request(Request.new({:action => 'hello'}))
      end

      # Sends SNP command "version".
      #   irb> Snarl::SNP.new('127.0.0.1').version
      #   SNP/1.1/0/OK/40.15
      def version
        request(Request.new({:action => 'version'}))
      end

      # UTILS -----------------------------

      private

      def paramarray_to_hash(param_array)
        title, text, icon, timeout, classid, action, app = param_array
        pattern = {
          :only_text => (param_array.size == 1),
          :text_timeout => (param_array.size == 2) && title && text.kind_of?(Integer),
          :title_text_timeout => (param_array.size == 3) && title && text && icon.kind_of?(Integer)
        }
        case
        when pattern[:only_text] then # notify("msg")
          {:title =>  nil, :text => title}
        when pattern[:text_timeout] then # notify("msg", 10)
          {:title =>  nil, :text => title, :timeout => text}
        when pattern[:title_text_timeout] then # notify("tit", "msg", 10)
          {:title => title, :text => text, :timeout => icon}
        else
          Hash[*NOTIFICATION_PARAM_ORDER.zip(param_array).flatten].delete_if{|k, v| v.nil?}
        end
      end

      # we support for:
      # notify(         'text')
      # notify('title', 'text')
      # notify(         'text', 10)
      # notify('title', 'text', 10)
      def normalize_notification_params(param)
        res = Hash.new
        if param[0].kind_of?(Hash) then
          keyhash = param[0]
        else
          keyhash = paramarray_to_hash(param)
        end
        NOTIFICATION_PARAM_ORDER.each do |command|
          keyhash_value = (keyhash[command.to_s] || keyhash[command])
          res[command] =  keyhash_value if keyhash_value
        end
        res[:action]  = 'notification'
        res[:app]     = self['app'] if (res[:app].nil? && self['app']) # default notification
        res[:title]   = (res[:title] || self['title'] || DEFAULT_TITLE)
        res[:timeout] = (res[:timeout] || self['timeout'] || DEFAULT_TIMEOUT)
        if res[:icon] then
          res[:icon] = icon(res[:icon])
        elsif self['icon'] then
          res[:icon] = self['icon']
        end
        return res
      end
    end
  end
end
