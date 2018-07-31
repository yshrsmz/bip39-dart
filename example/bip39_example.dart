import 'package:bip39/bip39.dart' as bip39;

main() async {

  final mnemonic = await bip39.generateMnemonic();
  print('mnemonic code: ${mnemonic}');
}
