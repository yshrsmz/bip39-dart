# BIP39

[![Build Status](https://travis-ci.org/yshrsmz/bip39-dart.svg?branch=master)](https://travis-ci.org/yshrsmz/bip39-dart)

Dart implementation of [Bitcoin BIP39](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki): Mnemonic code for generating deterministic keys

## Usage

A simple usage example:

```dart
import 'package:bip39/bip39.dart' as bip39;

main() {
  // Generate a random mnemonic (uses Random.secure() under the hood), defaults to 128-bits of entropy
  var mnemonic = await bip39.generateMnemonic();
  // => 'alarm boost mom torch couple owner myself gift sugar tell ticket panther'
  
  bip39.mnemonicToSeedHex('basket actual');
  // => '5cf2d4a8b0355e90295bdfc565a022a409af063d5365bb57bf74d9528f494bfa4400f53d8349b80fdae44082d7f9541e1dba2b003bcfec9d0d53781ca676651f'
  
  bip39.mnemonicToSeed('basket actual');
  // => [92, 242, 212, 168, 176, 53, 94, 144, 41, 91, 223, 197, 101, 160, 34, 164, 9, 175, 6, 61, 83, 101, 187, 87, 191, 116, 217, 82, 143, 73, 75, 250, 68, 0, 245, 61, 131, 73, 184, 15, 218, 228, 64, 130, 215, 249, 84, 30, 29, 186, 43, 0, 59, 207, 236, 157, 13, 83, 120, 28, 166, 118, 101, 31]
  
  await bip39.validateMnemonic(mnemonic);
  // => true
  
  await bip39.validateMnemonic('basket actual');
  // => false
  
  
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/yshrsmz/bip39-dart
