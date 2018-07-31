import 'package:bip39/bip39.dart' as bip39;
import 'package:test/test.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

void main() {
  Map<String, dynamic> vectors =
      json.decode(File('./test/vectors.json').readAsStringSync(encoding: utf8));

  group('A group of tests', () {
    setUp(() async {});

    // testVector('English', bip39.Wordlist.ENGLISH, '', vectors['english'][0], 0);
    int i = 0;
    (vectors['english'] as List<dynamic>).forEach((list) {
      testVector('English', bip39.Wordlist.ENGLISH, '', list, i);
      i++;
    });

    i = 0;
    (vectors['japanese'] as List<dynamic>).forEach((list) {
      testVector('Japanese', bip39.Wordlist.JAPANESE, '', list, i);
      i++;
    });

    // test('First Test', () async {
    //   // await bip39.entropyToMnemonic(entropy, wordlist)
    //   final mnemonic = await bip39.generateMnemonic();
    //   print("mnemonic: $mnemonic");
    // });
  });
}

void testVector(String description, bip39.Wordlist wordlist, String password,
    List<dynamic> v, int i) {
  final ventropy = v[0];
  final vmnemonic = v[1];
  final vseedHex = v[2];

  test('for ${description}(${i}), ${ventropy}', () async {
    final regex = new RegExp(r".{1,2}", caseSensitive: false, multiLine: false);
    final entropy = Uint8List.fromList(regex
        .allMatches(ventropy)
        .map((s) => int.parse(s.group(0), radix: 16))
        .toList(growable: false));

    print('entropy: $entropy');

    final code = await bip39.entropyToMnemonic(entropy, wordlist);
    expect(code, equals(vmnemonic));

    // print('code: $code');
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
