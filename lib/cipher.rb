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
    encrypted_string_array = eval encrypted_string
    result = ""
    encrypted_string_array.each do |encrypted|
      init
      @decrypt.update(encrypted.to_s)
      result << @decrypt.final
    end
    result
  end

  private
  def init
    #128 bit AES Cipher Block Chaining encryption
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