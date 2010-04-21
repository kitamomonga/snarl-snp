class Snarl
  class SNP
    module Error
      class SNPError < StandardError
        def initialize(response, request=nil) # request is String or Request
          @response, @request = response, request
        end
        attr_accessor :request, :response
        def code ; @response.code ; end
        def message ; "(#{code}) #{@response.message}" ; end
        def ok? ; @response.ok? ; end
      end

      class Casual < SNPError ; end

      class SNP_OK < Casual ; end
      # (0) OK

      class SNP_ERROR_NOT_REGISTERED < Casual ; end
      # (202) The application hasn't been registered.

      class SNP_ERROR_ALREADY_REGISTERED < Casual ; end
      # (203) The application is already registered.

      class SNP_ERROR_CLASS_ALREADY_EXISTS < Casual ; end
      # (204) Class is already registered.

      class Fatal < SNPError ; end

      class SNP_ERROR_FAILED < Fatal ; end
      # (101) An internal error occurred - usually this represents a fault within Snarl itself.

      class SNP_ERROR_UNKNOWN_COMMAND < Fatal ; end
      # (102) An unknown action was specified.

      class SNP_ERROR_TIMED_OUT < Fatal ; end
      # (103) The command sending (or subsequent reply) timed out.

      class SNP_ERROR_BAD_PACKET < Fatal ; end
      # (107) The command packet is wrongly formed.

      class SNP_ERROR_NOT_RUNNING < Fatal ; end
      # (201) Incoming network notification handling has been disabled by the user.

      class RUBYSNARL_UNKNOWN_RESPONSE < Fatal ; end
      # (???) Snarl returns unknown return code.

      CODE_TO_OBJ = {
        '0' => SNP_OK,
        '101'  => SNP_ERROR_FAILED,
        '102' => SNP_ERROR_UNKNOWN_COMMAND,
        '103' => SNP_ERROR_TIMED_OUT,
        '107' => SNP_ERROR_BAD_PACKET,
        '201' => SNP_ERROR_NOT_RUNNING,
        '202' => SNP_ERROR_NOT_REGISTERED,
        '203' => SNP_ERROR_ALREADY_REGISTERED,
        '204' => SNP_ERROR_CLASS_ALREADY_EXISTS
      }

      def self.klass(response, request=nil)
        if klass = Error::CODE_TO_OBJ[response.to_s] then
          klass
        elsif response.kind_of?(Error::SNPError)
          response
        else
          Error::RUBYSNARL_UNKNOWN_RESPONSE
        end
      end

      def self.raise(response, request)
        Error.klass.new(response, request)
      end

    end
  end
end
