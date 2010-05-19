require 'snp'
class Snarl
  class SNP
    module AutoSNP
      @host=nil
      @port=nil
      @icondir=nil
      @icon_ok=nil
      @icon_fail=nil
      @icon_pending=nil
      @timeout_ok=nil
      @timeout_fail=nil

      attr_accessor :host, :port
      attr_writer :icondir, :icon_ok, :icon_fail, :icon_pending, :timeout_ok, :timeout_fail

      def snp
        Snarl::SNP.load(<<YAML)
host : #{host}
port : #{port}
app  : Autotest::Snarl
"class" :
  - ['green', 'test ok']
  - ['red', 'test fail']
  - ['yellow', 'test pending']
  - ['info', 'system message']
iconset :
   green  : #{File.join(icondir, icon_ok)}
   red    : #{File.join(icondir, icon_fail)}
   yellow : #{File.join(icondir, icon_pending)}
YAML
      end

      # Windows Snarl shortcut's "working folder" (left click property)
      # %HOME%\Application Data\full phat\snarl\styles
      def icondir ; @icondir ||= './' ; end

      # %HOME%\Application Data\full phat\snarl\styles\ok.png works fine
      def icon_ok ; @icon_ok ||= "ok.png" ; end
      def icon_fail ; @icon_fail ||= "fail.png" ; end
      def icon_pending ; @icon_pending ||= "pending.png" ; end

      def timeout_ok ; @timeout_ok ||= 5 ; end
      def timeout_fail ; @timeout_fail ||= 10 ; end

      def timeout(state)
        case state
        when :green then timeout_ok.to_i
        when :red   then timeout_fail.to_i
        else 5
        end
      end

      def classname(state)
        state.to_s
      end

      def snarl(title, text, state)
        snp.notification(
                         :title   => title,
                         :text    => text,
                         :icon    => state.to_s,
                         :timeout => timeout(state),
                         :class   => classname(state)
                         )
      end
    end
  end
end
