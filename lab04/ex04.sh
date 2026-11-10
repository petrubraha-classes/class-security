# choose a file
echo "salut, ce mai faci?" > message.txt
# generate a message authentication code, and create an authenticated encryption of it
openssl rand -out chacha_key.bin 32 # ChaCha20 key on 256 bits
openssl rand -out nonce.bin 12 # Nonce for ChaCha20 (12 bytes)
openssl enc -chacha20 -K "$(xxd -p -c 32 chacha_key.bin)" -iv "$(xxd -p -c 12 nonce.bin)" -in message.txt -out ciphertext.bin
# compute a message digest of the file
openssl rand -out hmac_key.bin 32 # HMAC key on 256 bits
openssl dgst -sha256 -hmac "$(cat hmac_key.bin)" ciphertext.bin > hmac_ciphertext.bin
cat ciphertext.bin hmac_ciphertext.bin > final_AE_message.bin
