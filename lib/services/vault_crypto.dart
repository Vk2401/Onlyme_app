import 'dart:convert';

class VaultCrypto {
  static const _k = r'OnlyMe$V@ult$C1ph3r$2024$Pr1v@t3';

  static String encrypt(String plaintext) {
    if (plaintext.isEmpty) return '';
    final b = utf8.encode(plaintext);
    final k = utf8.encode(_k);
    final x = List<int>.generate(b.length, (i) => b[i] ^ k[i % k.length]);
    return 'enc:${base64Url.encode(x)}';
  }

  static String decrypt(String stored) {
    if (stored.isEmpty) return '';
    if (!stored.startsWith('enc:')) return stored; // legacy plaintext
    try {
      final b = base64Url.decode(stored.substring(4));
      final k = utf8.encode(_k);
      final x = List<int>.generate(b.length, (i) => b[i] ^ k[i % k.length]);
      return utf8.decode(x);
    } catch (_) {
      return stored;
    }
  }
}
