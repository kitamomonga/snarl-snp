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
      end

      attr_reader :commands

      # Adds command key and value to Request
      def []=(cmdkey, value) ; @commands[cmdkey] = value ; end # TODO: normalize
      # Returns command value for command key
      def [](cmdkey)        ; @commands[cmdkey]     ; end

      # Returns Request query string with SNP_TERMINAL_STRING "\r\n"
      def to_str ; query + SNP_TERMINAL_STRING ; end # FIXME: include "\r\n"?
      alias :to_s :to_str
      # Returns Request query string. has no SNP_TERMINAL_STRING "\r\n".
      def inspect ; query ; end
      def action ; @commands['action'] ; end

      private

      def order_command_pair
        action = @commands['action']
        @commands.to_a.sort_by{|pair| SNP_ACTIONS[action].index(pair[0])}
      end

      def query
        normalize
        order_command_pair.map{|pair| pair.join('=')}.join(SNP_SEPARATOR)
      end

      # normalize item pairs
      # - symbol keys and upcase KEYS are normalized into downcased string keys.
      # - query should not have any "\r". use "\n"
      # - when value is nil, delete the item pair.
      def normalize
        norm_commands = Hash[*@commands.map{|k, v| [crlf2lf(k).downcase, crlf2lf(v)]}.flatten]
        action = normalize_action(norm_commands['action'])
        norm_commands['action'] = action
        @commands = SNP_HEADER.dup
        available_commands_in(action).each do |cmd|
          @commands[cmd] = norm_commands[cmd] if norm_commands[cmd]
        end
      end

      def normalize_action(action_type)
        action_type.downcase.gsub(/-/){'_'}.sub(/\Aaddclass\Z/){'add_class'}
      end

      def available_commands_in(action)
        SNP_ACTIONS[action] || {}
      end

      def crlf2lf(s)
        s ? s.to_s.gsub(/\r\n/){"\n"}.gsub(/\r/){"\n"} : s
      end

    end
  end
end

