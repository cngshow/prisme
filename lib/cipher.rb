class CipherSupport
  include Singleton

  def encrypt(unencrypted_string:)
    init
    @encrypt.update(unencrypted_string)
    @encrypt.final
  end

  def decrypt(encrypted_string:)
    init
    @decrypt.update(encrypted_string)
    @decrypt.final
  end

  private
  def init
    @encrypt = OpenSSL::Cipher::AES.new(128, :CBC)
    @decrypt = OpenSSL::Cipher::AES.new(128, :CBC)
    secret = Rails.application.secrets.secret_key_base
    @encrypt.key = secret
    @decrypt.key = secret
    @encrypt.encrypt
    @decrypt.decrypt
  end
end

# load './lib/cipher.rb'
#v = CipherSupport.instance.encrypt(unencrypted_string: 'bob')
#> v = CipherSupport.instance.decrypt(encrypted_string: v)
