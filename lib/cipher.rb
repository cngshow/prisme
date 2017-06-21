require 'cgi'

#This base class can be used for encrypting and decrypting things that don't depend on the aitc environment.  The salt is constant.
#Currently, it is used to encrypt/decrypt service passowrds (git, tomcat, nexus etc)
class CipherSupport
  include Singleton

  java_import 'gov.vha.isaac.ochre.api.util.PasswordHasher' do |p, c|
    'JCipher'
  end

  def encrypt(unencrypted_string:, preamble: nil)
    begin
      return preamble.to_s +  JCipher.encrypt(my_secret, unencrypted_string)
    rescue => ex
      $log.warn("I was unable to encrypt: ")
      $log.warn("#{unencrypted_string}")
      $log.warn("Caller:")
      $log.warn(caller[0][/`.*'/][1..-2])
      raise ex
    end
  end

  def decrypt(encrypted_string:, preamble: nil)
    encrypted_clone = encrypted_string.clone
    begin
      encrypted_clone.slice!(0, preamble.to_s.length) if preamble
     return (java.lang.String.new(JCipher.decrypt(my_secret,encrypted_clone))).to_s
    rescue => ex
      $log.warn("I was unable to decrypt: ")
      $log.warn("#{encrypted_clone}")
      #$log.warn("with salt: #{my_secret}")
      $log.warn("Caller:")
      $log.warn(caller[0][/`.*'/][1..-2])
      raise ex
    end
  end

  def generate_security_token(preamble: nil)
    token_hash = {'time' => Time.now.to_i}
    encrypt(unencrypted_string: token_hash.to_json.to_s, preamble: preamble)
  end

  def valid_security_token?(token:, preamble: nil)
    parsed = true
    date = nil
    $log.debug("token is #{token}")
    begin
      result = decrypt(encrypted_string: token, preamble: preamble)
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
  end
end

#The salt is tied to the aitc environment.
class TokenSupport < CipherSupport
  protected
  def my_secret
    Rails.application.secrets.secret_key_cipher_support[PRISME_ENVIRONMENT]
  end
end

class TokenDev < CipherSupport
  protected
  def my_secret
    Rails.application.secrets.secret_key_cipher_support['DEV']
  end
end

class TokenTEST < CipherSupport
  protected
  def my_secret
    Rails.application.secrets.secret_key_cipher_support['TEST']
  end
end

class TokenDevBox < CipherSupport
  protected
  def my_secret
    Rails.application.secrets.secret_key_cipher_support['DEV_BOX']
  end
end


# load './lib/cipher.rb'
# v = CipherSupport.instance.encrypt(unencrypted_string: 'devtest@devtest.com')
# v = CipherSupport.instance.decrypt(encrypted_string: v)
# v = CipherSupport.instance.encrypt(unencrypted_string: 'devtest')
# "[\"jK\\x90\\xA1\\x1Fk\\x87\\xD7\\xC3\\xD8\\xA8\\x9A\\x18\\xD4fC\"]"
=begin
irb(main):125:0> a = TokenSupport.instance.encrypt(unencrypted_string: 'devtesthardtoguess')
Rlfae-0S34Lzw57WlN-GpXZX_1LLe-6NSx1lGXFPyEc=$$$fbLsBt2CURzc4B2M48ps3S-lcEy3FG97PJgRaL-4uwzQTwcoJCi_nKZqHUN9K7GZWxtsR0dXe_T-GIlEUy3Haw==
irb(main):126:0> a = TokenSupport.instance.encrypt(unencrypted_string: 'devtest')
OcWsweYoUJJ1BukriEonMH24Im8o1SPqZ9d7mjuNLro=$$$KS-H95Q2s7NfEWD_KHJ5KQLgGIV4R8aQAX4hy72_ybHxiViHdRFBhd7UD4AJ1rHv
=end