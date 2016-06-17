#monkeypatch founde here:
#https://github.com/thoughtbot/paperclip/issues/1924
module Paperclip
  # do not require any validations
  #turn off warnings
  v = $VERBOSE
  $VERBOSE = nil
  REQUIRED_VALIDATORS = []
  $VERBOSE = v
  # do not complain when missing validations
  class Attachment
    def missing_required_validator?
      false
    end
  end

  # skip media type spoof detection
  module Validators
    class MediaTypeSpoofDetectionValidator < ActiveModel::EachValidator
      def validate_each(record, attribute, value)
        true
      end
    end
  end

end