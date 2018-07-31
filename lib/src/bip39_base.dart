import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:resource/resource.dart';
import 'dart:convert';
import 'dart:async';

//import 'package:pointycastle/random/auto_seed_block_ctr_random.dart';
//import 'package:pointycastle/block/modes/ctr.dart';

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

const int _SIZE_8BITS = 255;
const String _INVALID_ENTROPY = 'Invalid entroy';
const String _INVALID_MNEMONIC = 'Invalid mnemonic';
const String _INVALID_CHECKSUM = 'Invalid checksum';

String _getWordlistName(Wordlist wordlist) {
  switch (wordlist) {
    case Wordlist.CHINESE_SIMPLIFIED:
      return 'chinese_simplified';
    case Wordlist.CHINESE_TRADITIONAL:
      return 'chinese_traditional';
    case Wordlist.ENGLISH:
      return 'english';
    case Wordlist.FRENCH:
      return 'french';
    case Wordlist.ITALIAN:
      return 'italian';
    case Wordlist.JAPANESE:
      return 'japanese';
    case Wordlist.KOREAN:
      return 'korean';
    case Wordlist.SPANISH:
      return 'spanish';
    default:
      return 'english';
  }
}

Uint8List _nextBytes(int size) {
  final rnd = Random.secure();
  final bytes = Uint8List(size);
  for (var i = 0; i < size; i++) {
    bytes[i] = rnd.nextInt(_SIZE_8BITS);
  }
  return bytes;
}

int _binaryToByte(String binary) {
  return int.parse(binary, radix: 2);
}

String _bytesToBinary(Uint8List bytes) {
  return bytes.map((byte) => byte.toRadixString(2).padLeft(8, '0')).join('');
}

String deriveChecksumBits(Uint8List entropy) {
  final ENT = entropy.length * 8;
  final CS = ENT ~/ 32;

  final hash = sha256.convert(entropy);
  return _bytesToBinary(Uint8List.fromList(hash.bytes)).substring(0, CS);
}

// ByteData mnemonicToEntropy(String mnemonic, Wordlist wordlist) {}

Future<String> entropyToMnemonic(Uint8List entropy, Wordlist wordlist) async {
  if (entropy.length < 16) {
    throw ArgumentError(_INVALID_ENTROPY);
  }
  if (entropy.length > 32) {
    throw ArgumentError(_INVALID_ENTROPY);
  }
  if (entropy.length % 4 != 0) {
    throw ArgumentError(_INVALID_ENTROPY);
  }

  final entroypyBits = _bytesToBinary(entropy);
  final checksumBits = deriveChecksumBits(entropy);

  final bits = entroypyBits + checksumBits;

  final regex = new RegExp(r".{1,11}", caseSensitive: false, multiLine: false);
  final chunks = regex
      .allMatches(bits)
      .map((match) => match.group(0))
      .toList(growable: false);

  final wordRes = await _loadWordlist(wordlist);

  return chunks
      .map((binary) => wordRes[_binaryToByte(binary)])
      .join(wordlist == Wordlist.JAPANESE ? '\u3000' : ' ');
}

Future<String> generateMnemonic({
  int strength = 128,
  Wordlist wordlist = _DEFAULT_WORDLIST,
}) async {
  assert(strength % 32 == 0);

  final entropy = _nextBytes(strength ~/ 8);

  return await entropyToMnemonic(entropy, wordlist);
}

// bool validateMnemonic(String mnemonic, Wordlist wordlist) {}

Future<List<String>> _loadWordlist(Wordlist wordlist) async {
  final res =
      Resource('package:bip39/src/wordlists/${_getWordlistName(wordlist)}.txt');
  final rawWords = await res.readAsString(encoding: utf8);
  return rawWords
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList(growable: false);
}
