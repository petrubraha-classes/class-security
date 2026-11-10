import os
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

def xor_bytes(a: bytes, b: bytes) -> bytes:
    assert len(a) == len(b), "inputs must have the same length"
    return bytes(x ^ y for x, y in zip(a, b))

def encrypt(key: bytes, nonce: bytes, m: bytes) -> bytes:
    # AES in CTR mode turns AES into a stream cipher: c = m xor keystream
    enc = Cipher(algorithms.AES(key), modes.CTR(nonce)).encryptor()
    return enc.update(m) + enc.finalize()

def decrypt(key: bytes, nonce: bytes, c: bytes) -> bytes:
    dec = Cipher(algorithms.AES(key), modes.CTR(nonce)).decryptor()
    return dec.update(c) + dec.finalize()

TEMPLATE = """
Mr. {person_name} please come and get the amount of {target_sum} ron from our office.

Sincerely,
Your Bank
"""

# --- Bank side: original message -----------------------------------------
person_name = "ION"
target_sum = "300"
p1 = TEMPLATE.format(person_name=person_name, target_sum=target_sum).encode()

k = os.urandom(32)       # AES-256 key
nonce = os.urandom(16)   # CTR initial counter block
c1 = encrypt(k, nonce, p1)

# --- Attacker side: knows p1, sees c1, does NOT know k --------------------
p2 = TEMPLATE.format(person_name="DAN", target_sum="900").encode()  # same length!
delta = xor_bytes(p1, p2)
c2 = xor_bytes(c1, delta)

# --- Receiver side: decrypts the tampered ciphertext with the real key ----
m2 = decrypt(k, nonce, c2)

print("c1:", c1.hex())
print("c2:", c2.hex())
print("m2:", m2.decode())
print("m2 == p2:", m2 == p2)
