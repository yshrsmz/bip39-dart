import 'dart:convert';

import 'package:bip39/bip39.dart' as bip39;
import 'package:bip39/src/sha512.dart';
import 'package:crypto/crypto.dart';

main() async {
  print('sha256: ${sha256.convert(utf8.encode('123'))}');
  print('sha512: ${sha512.convert(utf8.encode('123'))}');

  final mnemonic = await bip39.generateMnemonic();
  print('mnemonic code: ${mnemonic}');
}
