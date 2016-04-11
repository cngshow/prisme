class CipherSupport
  include Singleton

  def encrypt(unencrypted_string:)
    init
    @encrypt.update(unencrypted_string)
    @encrypt.final.bytes.to_s
  end

  def decrypt(encrypted_string:)
    init
    b = eval encrypted_string
    @decrypt.update( b.map(&:chr).join)
    @decrypt.final
  end

  private
  def init
    #128 bit AES Cipher Block Chaining encryption
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
# v = CipherSupport.instance.decrypt(encrypted_string: v)
