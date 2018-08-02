import 'dart:typed_data';

import 'package:crypto/src/digest.dart';
import 'package:crypto/src/utils.dart';
import 'package:typed_data/typed_data.dart';

const _mask64 = 0xffffffffffffffff;
const _bytesPerWord64 = 8;

abstract class Hash64Sink implements Sink<List<int>> {
  /// The inner sink that this should forward to.
  final Sink<Digest> _sink;

  /// Whether the hash function operates on big-endian words.
  final Endian _endian;

  /// The words in the current chunk.
  ///
  /// This is an instance variable to avoid re-allocating, but its data isn't
  /// used across invocations of [_iterate].
  final Uint64List _currentChunk;

  /// Messages with more than 2^53-1 bits are not supported. (This is the
  /// largest value that is representable on both JS and the Dart VM.)
  /// So the maximum length in bytes is (2^53-1)
  static const _maxMessageLengthInBytes = 0x0003ffffffffffff;

  /// The length of the input data so far, in bytes.
  int _lengthInBytes = 0;

  /// Data that has yet to be processed by the hash function.
  final _pendingData = new Uint8Buffer();

  /// Whether [close] has been called.
  bool _isClosed = false;

  /// The words in the current digest.
  ///
  /// This should be updated each time [updateHash] is called.
  Uint64List get digest;

  /// Creates a new hash.
  ///
  /// [chunkSizeInWords] represents the size of the input chunks processed by
  /// the algorithm, in terms of 64-bit words.
  Hash64Sink(this._sink, int chunkSizeInWords, {Endian endian = Endian.big})
      : _endian = endian,
        _currentChunk = Uint64List(chunkSizeInWords);

  /// Runs a single iteration of the hash computation, updating [digest] with
  /// the result.
  ///
  /// [chunk] is the current chunk, whose size is given by the
  /// `chunkSizeInWords` parameter passed to the constructor.
  void updateHash(Uint64List chunk);

  @override
  void add(List<int> data) {
    if (_isClosed) throw new StateError('Hash.add() called after close().');
    _lengthInBytes += data.length;
    _pendingData.addAll(data);
    _iterate();
  }

  @override
  void close() {
    if (_isClosed) return;
    _isClosed = true;

    _finalizeData();
    _iterate();
    assert(_pendingData.isEmpty);
    _sink.add(new Digest(_byteDigest()));
    _sink.close();
  }

  Uint8List _byteDigest() {
    if (_endian == Endian.host) return digest.buffer.asUint8List();

    var byteDigest = new Uint8List(digest.lengthInBytes);
    var byteData = byteDigest.buffer.asByteData();
    for (var i = 0; i < digest.length; i++) {
      byteData.setUint64(i * _bytesPerWord64, digest[i]);
    }
    return byteDigest;
  }

  /// Iterates through [_pendingData], updating the hash computation for each
  /// chunk.
  void _iterate() {
    var pendingDataBytes = _pendingData.buffer.asByteData();
    var pendingDataChunks = _pendingData.length ~/ _currentChunk.lengthInBytes;
    for (var i = 0; i < pendingDataChunks; i++) {
      // Copy words from the pending data buffer into the current chunk buffer.
      for (var j = 0; j < _currentChunk.length; j++) {
        _currentChunk[j] = pendingDataBytes.getUint64(
            i * _currentChunk.lengthInBytes + j * _bytesPerWord64, _endian);
      }

      // Run the hash function on the current chunk.
      updateHash(_currentChunk);
    }

    // Remove all pending data up to the last clean chunk break.
    _pendingData.removeRange(
        0, pendingDataChunks * _currentChunk.lengthInBytes);
  }

  /// Finalizes [_pendingData].
  ///
  /// This adds a 1 bit to the end of the message, and expands it with 0 bits to
  /// pad it out.
  void _finalizeData() {
    // Pad out the data with 0x80, eight 0s, and as many more 0s as we need to
    // land cleanly on a chunk boundary.
    _pendingData.add(0x80);
    var contentsLength = _lengthInBytes + 17;
    var finalizedLength = _roundUp(contentsLength, _currentChunk.lengthInBytes);
    for (var i = 0; i < finalizedLength - contentsLength; i++) {
      _pendingData.add(0);
    }

    if (_lengthInBytes > _maxMessageLengthInBytes) {
      throw new UnsupportedError(
          'Hashing is unsupported for messages with more than 2^53 bits.');
    }

    var lengthInBits = _lengthInBytes * bitsPerByte;
    // assert(lengthInBits < pow(2, 64));

    // Add the full length of the input data as a 64-bit value at the end of the
    // hash.
    var offset = _pendingData.length;
    _pendingData.addAll(new Uint8List(16));
    var byteData = _pendingData.buffer.asByteData();

    // We're essentially doing byteData.setUint64(offset, lengthInBits, _endian)
    // here, but that method isn't supported on dart2js so we implement it
    // manually instead.
    // var highBits = lengthInBits >> 32;
    // var lowBits = lengthInBits & _mask64;
    // if (_endian == Endian.big) {
    //   byteData.setUint64(offset, highBits, _endian);
    //   byteData.setUint64(offset + bytesPerWord, lowBits, _endian);
    // } else {
    //   byteData.setUint64(offset, lowBits, _endian);
    //   byteData.setUint64(offset + bytesPerWord, highBits, _endian);
    // }
    byteData.setUint64(offset + _bytesPerWord64, lengthInBits, _endian);
    print(
        'byteData: ${_pendingData}, size: ${_pendingData.length}, lengthInBits: ${lengthInBits}');
  }

  /// Rounds [val] up to the next multiple of [n], as long as [n] is a power of
  /// two.
  int _roundUp(int val, int n) => (val + n - 1) & -n;
}
