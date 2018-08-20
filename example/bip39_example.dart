import 'dart:convert';
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:pointycastle/pointycastle.dart';

String _bytesToHex(Uint8List bytes) {
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
}

main() async {
  final sha256 = Digest("SHA-256");
  final sha512 = Digest("SHA-512");
  final sha256result = sha256.process(utf8.encode('123'));
  final sha512result = sha512.process(utf8.encode('123'));
//  print('sha256: ${sha256.convert(utf8.encode('123'))}');
//  print('sha512: ${sha512.convert(utf8.encode('123'))}');
  print('sha256: ${_bytesToHex(sha256result)}');
  print('sha512: ${_bytesToHex(sha512result)}');

  final mnemonic = await bip39.generateMnemonic();
  print('mnemonic code: ${mnemonic}');
}
