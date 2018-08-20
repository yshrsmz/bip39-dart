import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> vectors =
      json.decode(File('./test/vectors.json').readAsStringSync(encoding: utf8));

  int i = 0;
  (vectors['english'] as List<dynamic>).forEach((list) {
    testVector('English', bip39.Wordlist.ENGLISH, 'TREZOR', list, i);
    i++;
  });

  i = 0;
  (vectors['japanese'] as List<dynamic>).forEach((list) {
    testVector(
        'Japanese', bip39.Wordlist.JAPANESE, 'メートルガバヴァぱばぐゞちぢ十人十色', list, i);
    i++;
  });
}

void testVector(String description, bip39.Wordlist wordlist, String password,
    List<dynamic> v, int i) {
  final ventropy = v[0];
  final vmnemonic = v[1];
  final vseedHex = v[2];

  group('for ${description}(${i}), ${ventropy}', () {
    var entropy;
    setUp(() {
      final regex =
          new RegExp(r".{1,2}", caseSensitive: false, multiLine: false);
      entropy = Uint8List.fromList(regex
          .allMatches(ventropy)
          .map((s) => int.parse(s.group(0), radix: 16))
          .toList(growable: false));
    });

    test('entropy to mnemonic', () async {
      final code = await bip39.entropyToMnemonic(entropy, wordlist);
      expect(code, equals(vmnemonic));
    });

    test('mnemonic to seed hex', () async {
      final seedHex = bip39.mnemonicToSeedHex(vmnemonic, password: password);
      expect(seedHex, equals(vseedHex));
    });
  });
}

List<String> loadWordlist(String name) {
  final raw =
      File('./lib/src/wordlists/${name}.txt').readAsStringSync(encoding: utf8);
  return raw
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList(growable: false);
}
