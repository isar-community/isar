part of isar;

/// The bare minimum size for a custom secret as defined in XXH3.
/// See https://github.com/Cyan4973/xxHash/blob/b1a61dff654af43552b5ee05c737b6fd2a0ee14b/xxhash.h#L931
const kSecretSizeMin = 136;

/// When hashing inputs of length greater than 240, the [HashLongFunction]
/// is used. The default is [kXXH3HashLongFunction64Bit].
typedef HashLongFunction = int Function(
    Uint8List input, int seed, Uint8List secret);

/// The default HashLongFunction from xxHash.
/// See [HashLongFunction].
const HashLongFunction kXXH3HashLongFunction64Bit = xXH3HashLong64bInternal;

/// Perform an XXH3 hash of the input data.
/// The input data is provided as a [Uint8List] to avoid having to
/// perform conversions internally.
///
/// Optionally, a [secret] may be specified (if none is specified,
/// the default seed is used). If a secret is specified, it must be
/// greater in length than [kSecretSizeMin].
///
/// Per XXH3, the secret **MUST** look like a bunch of random bytes as
/// the quality of the secret impacts the dispersion of the hash algorithm.
/// "Trivial" or structured data such as repeated sequences or a text
/// document should be avoided.
///
/// The [seed] may be customized (the default value of the seed is 0).
///
/// A custom [HashLongFunction] may also be specified. By default,
/// this is the [kXXH3HashLongFunction64Bit] which is the HashLongFunction
/// included with xxHash.
///
/// To convert a [List] of [int]s to a [Uint8List], you can use
/// [Uint8List.fromList].
///
/// The resulting 64-bit value is returned as an [int].
int xxh3(
  Uint8List input, {
  Uint8List? secret,
  int seed = 0,
  HashLongFunction hashLongFunction = kXXH3HashLongFunction64Bit,
}) {
  return xXH3_64bitsInternal(
    input: input,
    seed: seed,
    secret: secret ?? kSecret,
    hashLongFunction: hashLongFunction,
  );
}
