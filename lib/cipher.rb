class CipherSupport
  include Singleton

  def encrypt(unencrypted_string:)
    init
    $log.info("Encrypt string " + unencrypted_string)
    @encrypt.update(unencrypted_string)
    @encrypt.final.bytes.to_s
  end

  def decrypt(encrypted_string:)
    init
    $log.info("Decrypt string " + encrypted_string)
    b = eval encrypted_string
    $log.info("Decrypt array " + b.inspect)
    decrypt_me = b.map(&:chr).join
    $log.info("dddd " + decrypt_me)
    @decrypt.update( decrypt_me)
    @decrypt.final
  end

  private
  def init
    #128 bit AES Cipher Block Chaining encryption
    @encrypt = OpenSSL::Cipher::AES.new(128, :CBC)
    @decrypt = OpenSSL::Cipher::AES.new(128, :CBC)
    secret = Rails.application.secrets.secret_key_cipher_support
    @encrypt.key = secret
    @decrypt.key = secret
    @encrypt.encrypt
    @decrypt.decrypt
  end
end

# load './lib/cipher.rb'
#v = CipherSupport.instance.encrypt(unencrypted_string: 'bob')
# v = CipherSupport.instance.decrypt(encrypted_string: v)
