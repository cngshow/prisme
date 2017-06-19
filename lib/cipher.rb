require 'cgi'

#This base class can be used for encrypting and decrypting things that don't depend on the aitc environment.  The salt is constant.
#Currently, it is used to encrypt/decrypt service passowrds (git, tomcat, nexus etc)
class CipherSupport
  include Singleton

  def chunk(string, size)
    string.scan(/.{1,#{size}}/)
  end

  def encrypt(unencrypted_string:)
    #consider a refactor one day... Move CGI::escape code to this level, out of role controller.
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
      if (!(encrypted_string.first.eql?('[') && encrypted_string.last.eql?(']')))
        #If t is a token and I compare
        # CGI::unescape t
        #with
        # java.net.URLDecoder.decode(t, java.nio.charset.StandardCharsets::UTF_8.name)
        #they always agree.  Same for the equivalent encoders.  Something strange is going on in our java framework where both the encoders/decoders are gorking
        #the encode/decode up.  The java side takes great pains to ensure the token is never 'molested'.  We will check to see if our
        #string was unencoded or not now...
        encrypted_string = CGI::unescape encrypted_string
      end
      encrypted_string_array = eval encrypted_string
      encrypted_string_array.each do |encrypted|
        init
        @decrypt.update(encrypted.to_s)
        result << @decrypt.final
      end
    rescue OpenSSL::Cipher::CipherError => ex
      $log.warn("I was unable to decrypt: ")
      $log.warn("#{encrypted_string}")
      $log.warn("Caller:")
      $log.warn(caller[0][/`.*'/][1..-2])
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
      result = decrypt(encrypted_string: token)
      $log.debug(result)
      hash = JSON.parse  result
      date = hash['time']
    rescue Exception => ex
      $log.warn("I could not parse the incoming token, #{ex.message}")
      parsed = false
    end
    parsed && !date.nil?
  end

  protected
  def my_secret
    Rails.application.secrets.secret_key_cipher_support['SERVICES']
  end

  private
  def init
    #128 bit AES Cipher Feedback (CFB)
    @encrypt = OpenSSL::Cipher::AES.new(128, :CFB)
    @decrypt = OpenSSL::Cipher::AES.new(128, :CFB)
   # @encrypt.padding=256
   # @decrypt.padding=256
    secret = my_secret
    @encrypt.key = secret
    @decrypt.key = secret
    @encrypt.encrypt
    @decrypt.decrypt
  end
end

#The salt is tied to the aitc environment.
class TokenSupport < CipherSupport
  protected
  def my_secret
    Rails.application.secrets.secret_key_cipher_support[PRISME_ENVIRONMENT]
  end
end

# load './lib/cipher.rb'
# v = CipherSupport.instance.encrypt(unencrypted_string: 'devtest@devtest.com')
# v = CipherSupport.instance.decrypt(encrypted_string: v)
# v = CipherSupport.instance.encrypt(unencrypted_string: 'devtest')
# "[\"jK\\x90\\xA1\\x1Fk\\x87\\xD7\\xC3\\xD8\\xA8\\x9A\\x18\\xD4fC\"]"
