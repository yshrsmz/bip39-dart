import 'dart:convert';
import 'dart:typed_data';

import 'package:bip39/src/hash_64_sink.dart';
import 'package:crypto/crypto.dart';
import 'package:crypto/src/digest.dart';

const _mask64 = 0xffffffffffffffff;
const _bytesPerWord64 = 8;

int _add64(int x, int y) => (x + y) & _mask64;

/// An instance of [Sha512].
///
/// this instance provides convenient access to the [Sha512][rfc] hash function.
///
/// [rfc]: http://tools.ietf.org/html/rfc6234
final sha512 = new Sha512._();

/// An implementation of the [SHA-512][rfc] hash function.
///
/// [rfc]: http://tools.ietf.org/html/rfc6234
///
/// Note that it's almost always easier to use [sha512] rather than creating a
/// new instance.
class Sha512 extends Hash {
  @override
  final int blockSize = 16 * _bytesPerWord64;

  Sha512._();

  Sha512 newInstance() => new Sha512._();

  @override
  ByteConversionSink startChunkedConversion(Sink<Digest> sink) =>
      ByteConversionSink.from(new _Sha512Sink(sink));
}

const List<int> _noise = const [
  0x428a2f98d728ae22, 0x7137449123ef65cd, 0xb5c0fbcfec4d3b2f, //
  0xe9b5dba58189dbbc, 0x3956c25bf348b538, 0x59f111f1b605d019,
  0x923f82a4af194f9b, 0xab1c5ed5da6d8118, 0xd807aa98a3030242,
  0x12835b0145706fbe, 0x243185be4ee4b28c, 0x550c7dc3d5ffb4e2,
  0x72be5d74f27b896f, 0x80deb1fe3b1696b1, 0x9bdc06a725c71235,
  0xc19bf174cf692694, 0xe49b69c19ef14ad2, 0xefbe4786384f25e3,
  0x0fc19dc68b8cd5b5, 0x240ca1cc77ac9c65, 0x2de92c6f592b0275,
  0x4a7484aa6ea6e483, 0x5cb0a9dcbd41fbd4, 0x76f988da831153b5,
  0x983e5152ee66dfab, 0xa831c66d2db43210, 0xb00327c898fb213f,
  0xbf597fc7beef0ee4, 0xc6e00bf33da88fc2, 0xd5a79147930aa725,
  0x06ca6351e003826f, 0x142929670a0e6e70, 0x27b70a8546d22ffc,
  0x2e1b21385c26c926, 0x4d2c6dfc5ac42aed, 0x53380d139d95b3df,
  0x650a73548baf63de, 0x766a0abb3c77b2a8, 0x81c2c92e47edaee6,
  0x92722c851482353b, 0xa2bfe8a14cf10364, 0xa81a664bbc423001,
  0xc24b8b70d0f89791, 0xc76c51a30654be30, 0xd192e819d6ef5218,
  0xd69906245565a910, 0xf40e35855771202a, 0x106aa07032bbd1b8,
  0x19a4c116b8d2d0c8, 0x1e376c085141ab53, 0x2748774cdf8eeb99,
  0x34b0bcb5e19b48a8, 0x391c0cb3c5c95a63, 0x4ed8aa4ae3418acb,
  0x5b9cca4f7763e373, 0x682e6ff3d6b2b8a3, 0x748f82ee5defb2fc,
  0x78a5636f43172f60, 0x84c87814a1f0ab72, 0x8cc702081a6439ec,
  0x90befffa23631e28, 0xa4506cebde82bde9, 0xbef9a3f7b2c67915,
  0xc67178f2e372532b, 0xca273eceea26619c, 0xd186b8c721c0c207,
  0xeada7dd6cde0eb1e, 0xf57d4f7fee6ed178, 0x06f067aa72176fba,
  0x0a637dc5a2c898a6, 0x113f9804bef90dae, 0x1b710b35131c471b,
  0x28db77f523047d84, 0x32caab7b40c72493, 0x3c9ebe0a15c9bebc,
  0x431d67c49c100d4c, 0x4cc5d4becb3e42b6, 0x597f299cfc657e2a,
  0x5fcb6fab3ad6faec, 0x6c44198c4a475817
];

class _Sha512Sink extends Hash64Sink {
  @override
  final digest = new Uint64List(8);

  final Uint64List _extended;

  _Sha512Sink(Sink<Digest> sink)
      : _extended = new Uint64List(128),
        super(sink, 16) {
    digest[0] = 0x6a09e667f3bcc908;
    digest[1] = 0xbb67ae8584caa73b;
    digest[2] = 0x3c6ef372fe94f82b;
    digest[3] = 0xa54ff53a5f1d36f1;
    digest[4] = 0x510e527fade682d1;
    digest[5] = 0x9b05688c2b3e6c1f;
    digest[6] = 0x1f83d9abfb41bd6b;
    digest[7] = 0x5be0cd19137e2179;
  }

  // Helper functions as defined in http://tools.ietf.org/html/rfc6234
  _rotr64(n, x) => (x >> n) | ((x << (64 - n)) & _mask64);

  _ch(x, y, z) => (x & y) ^ ((~x & _mask64) & z);

  _maj(x, y, z) => (x & y) ^ (x & z) ^ (y & z);

  _bsig0(x) => _rotr64(28, x) ^ _rotr64(34, x) ^ _rotr64(39, x);

  _bsig1(x) => _rotr64(14, x) ^ _rotr64(18, x) ^ _rotr64(41, x);

  _ssig0(x) => _rotr64(1, x) ^ _rotr64(8, x) ^ (x >> 7);

  _ssig1(x) => _rotr64(19, x) ^ _rotr64(61, x) ^ (x >> 6);

  @override
  void updateHash(Uint64List chunk) {
    assert(chunk.length == 16);

    for (var i = 0; i < 16; i++) {
      _extended[i] = chunk[i];
    }
    for (var i = 16; i < 80; i++) {
      _extended[i] = _add64(_add64(_ssig1(_extended[i - 2]), _extended[i - 7]),
          _add64(_ssig0(_extended[i - 15]), _extended[i - 16]));
    }

    int a = digest[0];
    int b = digest[1];
    int c = digest[2];
    int d = digest[3];
    int e = digest[4];
    int f = digest[5];
    int g = digest[6];
    int h = digest[7];

    for (var i = 0; i < 80; i++) {
      var temp1 = _add64(_add64(h, _bsig1(e)),
          _add64(_ch(e, f, g), _add64(_noise[i], _extended[i])));
      var temp2 = _add64(_bsig0(a), _maj(a, b, c));

      h = g;
      g = f;
      f = e;
      e = _add64(d, temp1);
      d = c;
      c = b;
      b = a;
      a = _add64(temp1, temp2);
    }

    // Update hash values after iteration.
    digest[0] = _add64(a, digest[0]);
    digest[1] = _add64(b, digest[1]);
    digest[2] = _add64(c, digest[2]);
    digest[3] = _add64(d, digest[3]);
    digest[4] = _add64(e, digest[4]);
    digest[5] = _add64(f, digest[5]);
    digest[6] = _add64(g, digest[6]);
    digest[7] = _add64(h, digest[7]);
  }
}
