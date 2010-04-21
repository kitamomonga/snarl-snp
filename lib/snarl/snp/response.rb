class Snarl
  class SNP
    class Response
      ResponseParseRegexp = /\ASNP\/[\d\.]+\/(\d+)\/(.+?)\Z/
      def initialize(s)
        if s.respond_to?(:get) then
          @response = s.get
        else
          @response = s
        end
        parse_response
      end

      attr_reader :code, :message, :infomation, :response
      attr_accessor :request
      alias :status :code

      def parse_response
        if  ResponseParseRegexp =~ @response.chomp then
          @code = $1
          @message, @infomation= $2.split(/\//)
        else
          raise Snarl::SNP::Error::RUBYSNARL_UNKNOWN_RESPONSE.new(self, nil)
        end
        raise error.new(self, nil) unless ok?
      end

      def error ; Error.klass(self.code) ; end

      def to_s    ; code ; end # puts response #=> "0"
      def inspect ; @response.chomp ; end # p response #=> "SNP/1.1/0/OK/456"

      def ok? ; code.to_i.zero? ; end
    end
  end
end
