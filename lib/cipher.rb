require 'cgi'

class CipherSupport
  include Singleton

  def chunk(string, size)
    string.scan(/.{1,#{size}}/)
  end

  def encrypt(unencrypted_string:)
    r_val = []
    chunks = chunk(unencrypted_string, 15)
    chunks.each do |chunk|
      init
      @encrypt.update(chunk)
      r_val << @encrypt.final#.bytes.to_s
    end
    r_val.inspect
  end

  def decrypt(encrypted_string:)
    result = ""
    begin
      encrypted_string_array = eval encrypted_string
      encrypted_string_array.each do |encrypted|
        init
        @decrypt.update(encrypted.to_s)
        result << @decrypt.final
      end
    rescue OpenSSL::Cipher::CipherError => ex
      $log.error("I was unable to decrypt: ")
      $log.error("#{encrypted_string}")
      $log.error("Caller:")
      $log.error(caller[0][/`.*'/][1..-2])
      raise ex
    end
    result
  end

  def stringify_token(s)
    s.gsub(', ','#!#')
  end

  def jsonize_token(s)
    s.gsub('#!#',', ')
  end

  def generate_security_token
    token_hash = {'time' => Time.now.to_i}
    CGI::escape encrypt(unencrypted_string: token_hash.to_json.to_s)
  end

  def valid_security_token?(token:)
    parsed = true
    date = nil
    $log.debug("token is #{token}")
    begin
      result = decrypt(encrypted_string: (CGI::unescape token))
      $log.debug(result)
      hash = JSON.parse  result
      date = hash['time']
    rescue Exception => ex
      $log.warn("I could not parse the incoming token, #{ex.message}")
      parsed = false
    end
    parsed && !date.nil?
  end

  private
  def init
    #128 bit AES Cipher Feedback (CFB)
    @encrypt = OpenSSL::Cipher::AES.new(128, :CFB)
    @decrypt = OpenSSL::Cipher::AES.new(128, :CFB)
   # @encrypt.padding=256
   # @decrypt.padding=256
    secret = Rails.application.secrets.secret_key_cipher_support
    @encrypt.key = secret
    @decrypt.key = secret
    @encrypt.encrypt
    @decrypt.decrypt
  end
end

# load './lib/cipher.rb'
# v = CipherSupport.instance.encrypt(unencrypted_string: 'devtest@devtest.com')
# v = CipherSupport.instance.decrypt(encrypted_string: v)
# v = CipherSupport.instance.encrypt(unencrypted_string: 'devtest')
# "[\"jK\\x90\\xA1\\x1Fk\\x87\\xD7\\xC3\\xD8\\xA8\\x9A\\x18\\xD4fC\"]"
