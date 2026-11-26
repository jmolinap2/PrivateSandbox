import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

import '../../shared/errors/vault_exceptions.dart';

/// Chunked AES-256-GCM encryption/decryption so a file is never fully
/// buffered in memory, as required by the plan ("cifrado por streaming").
///
/// Each chunk of up to [chunkSize] plaintext bytes is encrypted
/// independently with its own 12-byte nonce (an 8-byte random per-file
/// prefix followed by a 4-byte big-endian chunk counter), so nonces never
/// repeat within a file and are extremely unlikely to repeat across files.
/// On disk each chunk is stored as `cipherText (chunk length) || tag (16
/// bytes)`; chunk boundaries on decrypt are derived from the known
/// plaintext file size, so no extra framing bytes are needed.
class StreamCipher {
  const StreamCipher._();

  static const int chunkSize = 1 << 20; // 1 MiB
  static const int _macLength = 16;
  static final AesGcm _algorithm = AesGcm.with256bits();

  /// Encrypts [input] into [output] and returns the SHA-256 hex digest of
  /// the original plaintext, computed in the same pass.
  ///
  /// [isCancelled] is polled once per chunk; if it ever returns true the
  /// encryption stops and throws [CancelledException]. The caller is
  /// responsible for deleting the (partial) [output]. Checking on chunk
  /// boundaries keeps a cancel responsive without leaving a half-written
  /// ciphertext chunk.
  static Future<String> encryptFile({
    required File input,
    required File output,
    required SecretKey fileKey,
    required Uint8List noncePrefix,
    bool Function()? isCancelled,
  }) async {
    final reader = ChunkedStreamReader<int>(input.openRead());
    final sink = output.openWrite();
    final digestSink = _DigestSink();
    final hashConversion = crypto.sha256.startChunkedConversion(digestSink);
    try {
      var counter = 0;
      while (true) {
        if (isCancelled != null && isCancelled()) {
          throw const CancelledException();
        }
        final chunk = await reader.readChunk(chunkSize);
        if (chunk.isEmpty) break;
        hashConversion.add(chunk);
        final nonce = _buildNonce(noncePrefix, counter);
        final box = await _algorithm.encrypt(
          chunk,
          secretKey: fileKey,
          nonce: nonce,
        );
        sink.add(box.cipherText);
        sink.add(box.mac.bytes);
        counter++;
      }
      hashConversion.close();
      await sink.flush();
      return digestSink.value.toString();
    } finally {
      await reader.cancel();
      await sink.close();
    }
  }

  /// Streams decrypted plaintext chunks from [input]. The caller must know
  /// the exact original [plainFileSize] to locate chunk boundaries.
  static Stream<Uint8List> decryptStream({
    required File input,
    required SecretKey fileKey,
    required Uint8List noncePrefix,
    required int plainFileSize,
    bool Function()? isCancelled,
  }) async* {
    final raf = await input.open();
    try {
      var counter = 0;
      var remaining = plainFileSize;
      while (remaining > 0) {
        if (isCancelled != null && isCancelled()) {
          throw const CancelledException();
        }
        final plainChunkLen = remaining >= chunkSize ? chunkSize : remaining;
        final cipherChunk = await raf.read(plainChunkLen);
        final macBytes = await raf.read(_macLength);
        final nonce = _buildNonce(noncePrefix, counter);
        final clear = await _algorithm.decrypt(
          SecretBox(cipherChunk, nonce: nonce, mac: Mac(macBytes)),
          secretKey: fileKey,
        );
        yield Uint8List.fromList(clear);
        remaining -= plainChunkLen;
        counter++;
      }
    } finally {
      await raf.close();
    }
  }

  /// Decrypts [input] without writing plaintext to disk, returning only its
  /// SHA-256 hex digest. Used to verify that a freshly-written ciphertext
  /// round-trips to exactly the hash computed from the original file.
  static Future<String> hashDecryptedContent({
    required File input,
    required SecretKey fileKey,
    required Uint8List noncePrefix,
    required int plainFileSize,
    bool Function()? isCancelled,
  }) async {
    final digestSink = _DigestSink();
    final hashConversion = crypto.sha256.startChunkedConversion(digestSink);
    await for (final chunk in decryptStream(
      input: input,
      fileKey: fileKey,
      noncePrefix: noncePrefix,
      plainFileSize: plainFileSize,
      isCancelled: isCancelled,
    )) {
      hashConversion.add(chunk);
    }
    hashConversion.close();
    return digestSink.value.toString();
  }

  static Uint8List _buildNonce(Uint8List noncePrefix, int counter) {
    final nonce = Uint8List(12);
    nonce.setRange(0, 8, noncePrefix);
    final counterBytes = ByteData(4)..setUint32(0, counter, Endian.big);
    nonce.setRange(8, 12, counterBytes.buffer.asUint8List());
    return nonce;
  }
}

/// Captures the single [crypto.Digest] produced by a chunked SHA-256
/// conversion. `package:crypto` only exposes this as an internal
/// `DigestSink`, so it is reimplemented here against its public `Sink` API.
class _DigestSink implements Sink<crypto.Digest> {
  crypto.Digest? _value;

  crypto.Digest get value => _value!;

  @override
  void add(crypto.Digest data) => _value = data;

  @override
  void close() {}
}
