# Information Security

- See https://crypto.ancamarianica.ro/
- See https://link.springer.com/content/pdf/10.1007/978-3-642-21793-7_40.pdf
- `lab${x}` - uses the `guide${x-1}`

## Attacks

- man-in-the-middle (lab02)
- arp-spoofing (lab04)

## Courses

1. **IS-Introduction_to_IS.pdf**: the foundation (security goals, threats, terminology).
2. **IS-CryptoBasics.pdf**: general cryptography concepts that the later material builds on.
3. **IS-CryptoBasics_SKC.pdf**: symmetric key cryptography, which is simpler and usually taught first.
4. **IS-CryptoBasics_PKC.pdf**: public key cryptography, which is usually motivated by the limits of symmetric keys (key distribution).
5. **IS-KeyManagement.pdf**: how keys are generated, distributed, and stored. It makes more sense once you know both SKC and PKC.
6. **IS-Authentication.pdf**: proving identity, which relies on crypto concepts such as hashes, signatures, and keys.
7. **IS-Access_Control.pdf**: the general concepts of authorization, once identity is established.
8. **IS-Access_Control_DAC.pdf**: discretionary access control, the more familiar model.
9. **IS-Access_Control_MAC.pdf**: mandatory access control, usually covered after DAC as a contrast.

## Projects

```
1. Secure Shell (Project 12). SSH moves to first. It’s a real protocol with a layered design (transport, authentication, connection) that you can study down to the message level. It covers Diffie-Hellman and elliptic-curve key exchange, host keys and trust-on-first-use, public-key authentication, symmetric encryption and MACs, and channel multiplexing and tunneling. You can also capture a handshake in Wireshark or write a small client, which gives you something concrete to show.

2. Secure messaging (Project 11). It moves up to second. If you take “protocols” to mean the cryptographic ones, it’s the most technically rich of the three: X3DH, the Double Ratchet, forward secrecy and post-compromise security, group messaging, and Olvid’s own design, which avoids phone numbers and central identity servers. The JMS and Enterprise Integration Patterns references add a systems and architecture side. The scope is still loosely defined, so you’d want to settle early whether you’re focusing on the cryptography or the messaging architecture.

3. Cloud security (Project 13). It drops to third, and your concern is valid. As written, it’s broad and descriptive rather than technical. If you chose it, you’d need to narrow it yourself to something with real depth, such as IAM and policy evaluation, key management and envelope encryption, or container and VM isolation.
```
