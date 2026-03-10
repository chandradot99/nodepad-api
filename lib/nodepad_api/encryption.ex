defmodule NodepadApi.Encryption do
  @aad "AES256GCM"

  def encrypt(plaintext) do
    secret = encryption_key()
    iv = :crypto.strong_rand_bytes(16)
    {ciphertext, tag} = :crypto.crypto_one_time_aead(:aes_256_gcm, secret, iv, plaintext, @aad, true)
    (iv <> tag <> ciphertext) |> Base.encode64()
  end

  def decrypt(ciphertext_encoded) do
    secret = encryption_key()
    <<iv::binary-16, tag::binary-16, ciphertext::binary>> =
      Base.decode64!(ciphertext_encoded)
    :crypto.crypto_one_time_aead(:aes_256_gcm, secret, iv, ciphertext, @aad, tag, false)
  end

  defp encryption_key do
    System.get_env("ENCRYPTION_KEY") |> Base.decode64!()
  end
end
