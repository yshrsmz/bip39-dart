import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:hex/hex.dart';
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

  group('invalid entropy', () {
    test('throws for empty entropy', () async {
      expect(bip39.entropyToMnemonic(utf8.encode('')), throwsArgumentError);
    });

    test('throws for entropy that\'s not a multitude of 4 bytes', () async {
      expect(
          bip39.entropyToMnemonic(utf8.encode('000000')), throwsArgumentError);
    });

    test('throws for entropy that is larger than 1024', () async {
      expect(
          bip39.entropyToMnemonic(utf8.encode(Uint8List(1028 + 1).join('00'))),
          throwsArgumentError);
    });
  });

  group('UTF8 passwords', () {
    final password = '㍍ガバヴァぱばぐゞちぢ十人十色';
    final normalizedPassword = 'メートルガバヴァぱばぐゞちぢ十人十色';

    (vectors['japanese'] as List).forEach((v) {
      final vmnemonic = v[1];
      final vseedHex = v[2];

      test('for ${vmnemonic}', () async {
        final result1 = await bip39.mnemonicToSeedHex(vmnemonic, password);
        final result2 =
            await bip39.mnemonicToSeedHex(vmnemonic, normalizedPassword);

        expect(result1, equals(vseedHex));
        expect(result2, equals(vseedHex));
      });
    });
  });

  group('generateMnemonic', () {
    test('can vary entropy length', () async {
      final words = (await bip39.generateMnemonic(strength: 160)).split(' ');

      expect(words.length, equals(15),
          reason: 'can vary generated entropy bit length');
    });

    test('requests the exact amount of data from randomBytes function',
        () async {
      await bip39.generateMnemonic(
          strength: 160,
          randomBytes: (int size) {
            expect(size, 160 / 8);
            return Uint8List(size);
          });
    });
  });

  test('validateMnemonic', () async {
    expect(await bip39.validateMnemonic('sleep kitten'), isFalse,
        reason: 'fails for a mnemonic that is too short');

    expect(
        await bip39.validateMnemonic('sleep kitten sleep kitten sleep kitten'),
        isFalse,
        reason: 'fails for a mnemonic that is too short');

    expect(
        await bip39.validateMnemonic(
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about end grace oxygen maze bright face loan ticket trial leg cruel lizard bread worry reject journey perfect chef section caught neither install industry'),
        isFalse,
        reason: 'fails for a mnemonic that is too long');

    expect(
        await bip39.validateMnemonic(
            'turtle front uncle idea crush write shrug there lottery flower risky shell'),
        isFalse,
        reason: 'fails if mnemonic words are not in the word list');

    expect(
        await bip39.validateMnemonic(
            'sleep kitten sleep kitten sleep kitten sleep kitten sleep kitten sleep kitten'),
        isFalse,
        reason: 'fails for invalid checksum');
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
      expect(entropy, equals(HEX.decode(ventropy)));
    });

    test('mnemonic to seed hex', () async {
      final seedHex = bip39.mnemonicToSeedHex(vmnemonic, password);
      expect(seedHex, equals(vseedHex));
    });

    test('entropy to mnemonic', () async {
      final entropy = HEX.decode(ventropy);

      final code = await bip39.entropyToMnemonic(entropy, wordlist);
      expect(code, equals(vmnemonic));

      final code2 = await bip39.entropyHexToMnemonic(ventropy, wordlist);
      expect(code2, equals(vmnemonic));
    });

    test('generate mnemonic', () async {
      bip39.RandomBytes nextBytes = (int size) {
        return HEX.decode(ventropy);
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
