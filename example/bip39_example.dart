import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;

String _bytesToHex(Uint8List bytes) {
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('');
}

main() async {
  final mnemonic = await bip39.generateMnemonic();
  print('mnemonic code: ${mnemonic}');

  print(bip39.mnemonicToSeedHex('basket actual'));

  print(bip39.mnemonicToSeed('basket actual'));

  // defaults to BIP39 English word list
  // uses HEX strings for entropy
  var mnemonic2 =
      await bip39.entropyHexToMnemonic('00000000000000000000000000000000');
  // => abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about

  // reversible
  bip39.mnemonicToEntropy(mnemonic2);
  // => '00000000000000000000000000000000'
}
