class Snarl
  class SNP
    class Request
      PROTOCOL_NAME = "SNP"
      PROTOCOL_VERSION ="1.0"

      SNP_ACTIONS = {
        'register'     => %w(type version action app),
        'add_class'    => %w(type version action app class title),
        'notification' => %w(type version action app class title text timeout icon priority),
        'unregister'   => %w(type version action app),
        'hello'        => %w(type version action),
        'version'      => %w(type version action),
      }

      # You have to send non-ascii messages by "Windows" encoding.
      ENCODING = 'cp932'

      SNP_SEPARATOR = '#?'
      SNP_TERMINAL_STRING = "\r\n"
      SNP_HEADER = {'type' => PROTOCOL_NAME, 'version' => PROTOCOL_VERSION}

      # make SNP request string from command hash and is Request object.
      def initialize(cmd_hash={})
        @commands = {}.update(cmd_hash)
        normalize unless @commands.empty?
      end

      attr_reader :commands

      # Adds command key and value to Request
      def []=(cmdkey, value)
        norm_cmdkey = normalize_cmdkey(cmdkey)
        if norm_cmdkey == 'action' then
          @commands['action'] = normalize_action_value(value)
        else
          @commands[norm_cmdkey] = normalize_value(value)
        end
      end
      # Returns command value for command key
      def [](cmdkey) ; @commands[cmdkey] ; end

      # Returns Request query string with SNP_TERMINAL_STRING "\r\n"
      def to_str ; query + SNP_TERMINAL_STRING ; end # FIXME: include "\r\n"?
      alias :to_s :to_str
      # Returns Request query string. has no SNP_TERMINAL_STRING "\r\n".
      def inspect ; query.inspect ; end
      def action ; @commands['action'] ; end

      private

      def align_command_pair
        @commands.to_a.sort_by{|pair| SNP_ACTIONS[action].index(pair[0])}
      end

      def query
        # @commands is already normalized
        align_command_pair.map{|pair| pair.join('=')}.join(SNP_SEPARATOR)
      end

      # normalize command item pairs {cmdkey => value}
      # - symbol keys and upcase KEYS are normalized into downcased string keys.
      # - value should not have any "\r". use one "\n" as a newline.
      # - {'action' => 'add-class' or :add_class} are {'action' => 'add_class'}.
      # - when value is nil, delete the pair.
      def normalize
        unnormalized_commands = @commands.dup
        @commands = SNP_HEADER.dup
        unnormalized_commands.each{|cmdkey, value| self[cmdkey] = value}
        available_commands = SNP_ACTIONS[self.action] || [] # or raise
        @commands.delete_if{|cmdkey, value| !available_commands.include?(cmdkey)}
        @commands.delete_if{|cmdkey, value| value.nil?} # || value.empty? # TODO: "timeout=" is vaild SNP?
        @commands
      end

      def normalize_cmdkey(cmdkey)
        crlf2lf(cmdkey).downcase
      end
      def normalize_value(value)
        crlf2lf(value)
      end

      def crlf2lf(s)
        s ? s.to_s.gsub(/\r\n/){"\n"}.gsub(/\r/){"\n"} : s
      end

      def normalize_action_value(value)
        normalize_value(value).downcase.gsub(/-/){'_'}.sub(/\Aaddclass\Z/){'add_class'}
      end
    end
  end
end

