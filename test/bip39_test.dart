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
    setUp(() {});

    test('mnemoic to entropy', () async {
      final Uint8List entropy =
          await bip39.mnemonicToEntropy(vmnemonic, wordlist);
      expect(entropy, equals(convertEntropy(ventropy)));
    });

    test('mnemonic to seed hex', () async {
      final seedHex = bip39.mnemonicToSeedHex(vmnemonic, password);
      expect(seedHex, equals(vseedHex));
    });

    test('entropy to mnemonic', () async {
      final entropy = convertEntropy(ventropy);

      final code = await bip39.entropyToMnemonic(entropy, wordlist);
      expect(code, equals(vmnemonic));
    });

    test('generate mnemonic', () async {
      bip39.RandomBytes nextBytes = (int size) {
        return convertEntropy(ventropy);
      };
      final code = await bip39.generateMnemonic(
          randomBytes: nextBytes, wordlist: wordlist);
      expect(code, equals(vmnemonic),
          reason: 'generateMnemonic returns nextBytes entropy unmodified');
    });

    test('validate mnemonic', () async {
      expect(await bip39.validateMnemonic(vmnemonic, wordlist), isTrue,
          reason: 'validateMnemonic returns true');
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

Uint8List convertEntropy(String entropy) {
  final regex = new RegExp(r".{1,2}", caseSensitive: false, multiLine: false);
  return Uint8List.fromList(regex
      .allMatches(entropy)
      .map((s) => int.parse(s.group(0), radix: 16))
      .toList(growable: false));
}
