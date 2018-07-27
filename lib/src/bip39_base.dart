import 'dart:math';
import 'dart:typed_data';


// https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki
// https://github.com/bitcoin/bips/tree/master/bip-0039
// https://github.com/bitcoinjs/bip39/blob/master/index.js

enum Wordlist {
  CHINESE_SIMPLIFIED,
  CHINESE_TRADITIONAL,
  ENGLISH,
  FRENCH,
  ITALIAN,
  JAPANESE,
  KOREAN,
  SPANISH,
}

const Wordlist _DEFAULT_WORDLIST = Wordlist.ENGLISH;

ByteData mnemonicToEntropy(String mnemonic, Wordlist wordlist) {

}

String entropyToMnemonic(ByteData entropy, Wordlist wordlist) {

}

String generateMnemonic({
  int strength = 128,
  Wordlist wordlist = _DEFAULT_WORDLIST,
}){
  assert(strength % 32 == 0);

  final random = Random.secure();
}

bool validateMnemonic(String mnemonic, Wordlist wordlist) {

}

List<String> _loadWordlist(Wordlist wordlist) {

}

/// Checks if you are awesome. Spoiler: you are.
class Awesome {
  bool get isAwesome => true;
}
