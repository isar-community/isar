// ignore_for_file: public_member_api_docs, unnecessary_parenthesis
// ignore_for_file: constant_identifier_names

part of isar;

const int kXXHPrime32_1 = 0x9E3779B1;
const int kXXHPrime32_2 = 0x85EBCA77;
const int kXXHPrime32_3 = 0xC2B2AE3D;

const int kXXHPrime64_1_HIGH = 0x9E3779B1;
const int kXXHPrime64_1_LOW = 0x85EBCA87;
const int kXXHPrime64_2_HIGH = 0xC2B2AE3D;
const int kXXHPrime64_2_LOW = 0x27D4EB4F;
const int kXXHPrime64_3_HIGH = 0x165667B1;
const int kXXHPrime64_3_LOW = 0x9E3779F9;
const int kXXHPrime64_4_HIGH = 0x85EBCA77;
const int kXXHPrime64_4_LOW = 0xC2B2AE63;
const int kXXHPrime64_5_HIGH = 0x27D4EB2F;
const int kXXHPrime64_5_LOW = 0x165667C5;

int mix64(int high, int low) {
  // Combine high and low parts using bitwise operations
  return (high * 0x100000000) + low;
}

/// The number of secret bytes consumed at each accumulation.
const int kSecretConsumeRate = 8;
const int kStripeLength = 64;
const int kAccNB = 8; // = kStripeLength ~/ sizeof(uint64_t)

const int kXXH3MidSizeMax = 240;

/// The default pseudo-random secret value for an XXH3 hash, originally
/// taken from FARSH.
final kSecret = Uint8List.fromList([
  0xb8, 0xfe, 0x6c, 0x39, 0x23, 0xa4, 0x4b, 0xbe, 0x7c, 0x01, 0x81, 0x2c, //
  0xf7, 0x21, 0xad, 0x1c, 0xde, 0xd4, 0x6d, 0xe9, 0x83, 0x90, 0x97, 0xdb, //
  0x72, 0x40, 0xa4, 0xa4, 0xb7, 0xb3, 0x67, 0x1f, 0xcb, 0x79, 0xe6, 0x4e, //
  0xcc, 0xc0, 0xe5, 0x78, 0x82, 0x5a, 0xd0, 0x7d, 0xcc, 0xff, 0x72, 0x21, //
  0xb8, 0x08, 0x46, 0x74, 0xf7, 0x43, 0x24, 0x8e, 0xe0, 0x35, 0x90, 0xe6, //
  0x81, 0x3a, 0x26, 0x4c, 0x3c, 0x28, 0x52, 0xbb, 0x91, 0xc3, 0x00, 0xcb, //
  0x88, 0xd0, 0x65, 0x8b, 0x1b, 0x53, 0x2e, 0xa3, 0x71, 0x64, 0x48, 0x97, //
  0xa2, 0x0d, 0xf9, 0x4e, 0x38, 0x19, 0xef, 0x46, 0xa9, 0xde, 0xac, 0xd8, //
  0xa8, 0xfa, 0x76, 0x3f, 0xe3, 0x9c, 0x34, 0x3f, 0xf9, 0xdc, 0xbb, 0xc7, //
  0xc7, 0x0b, 0x4f, 0x1d, 0x8a, 0x51, 0xe0, 0x4b, 0xcd, 0xb4, 0x59, 0x31, //
  0xc8, 0x9f, 0x7e, 0xc9, 0xd9, 0x78, 0x73, 0x64, 0xea, 0xc5, 0xac, 0x83, //
  0x34, 0xd3, 0xeb, 0xc3, 0xc5, 0x81, 0xa0, 0xff, 0xfa, 0x13, 0x63, 0xeb, //
  0x17, 0x0d, 0xdd, 0x51, 0xb7, 0xf0, 0xda, 0x49, 0xd3, 0x16, 0x55, 0x26, //
  0x29, 0xd4, 0x68, 0x9e, 0x2b, 0x16, 0xbe, 0x58, 0x7d, 0x47, 0xa1, 0xfc, //
  0x8f, 0xf8, 0xb8, 0xd1, 0x7a, 0xd0, 0x31, 0xce, 0x45, 0xcb, 0x3a, 0x8f, //
  0x95, 0x16, 0x04, 0x28, 0xaf, 0xd7, 0xfb, 0xca, 0xbb, 0x4b, 0x40, 0x7e, //
]);

/// A dart implementation of xxh64_avalanche.
/// Mixes all the bits to finalize the hash.
/// The final mix ensures the input bits have all had a chance to impact any
/// bit in the output digest thereby removing bias from the distribution.
int _xXH64Avalanche(int h) {
  h ^= h >>> 33;
  h *= mix64(kXXHPrime64_2_HIGH, kXXHPrime64_2_LOW);
  h ^= h >>> 29;
  h *= mix64(kXXHPrime64_3_HIGH, kXXHPrime64_3_LOW);
  return h ^ (h >>> 32);
}

/// Dart implementation of the xxh3_avalanche.
/// A fast avalanche stage for when input bits have been already partially
/// mixed.
int _xXH3Avalanche(int h) {
  h ^= h >>> 37;
  h *= mix64(0x16566791, 0x9E3779F9);
  return h ^ (h >>> 32);
}

/// Dart implementation of the xxh3_rrmxmx.
/// Based on Pelle Evensen's rrmxmx and preferred when input has not been
/// mixed.
int _xXH3rrmxmx(int h, int length) {
  h ^= ((h << 49) | (h >>> 15)) ^ ((h << 24) | (h >>> 40));
  h *= mix64(0x9FB21C65, 0x1E98DF25);
  h ^= (h >>> 35) + length;
  h *= mix64(0x9FB21C65, 0x1E98DF25);
  return h ^ (h >>> 28);
}

/// Dart implementation of the xxh3_mix16b hash function from XXH3.
int _xXH3Mix16B(
  Uint8List input,
  Uint8List secret,
  int seed, {
  int inputOffset = 0,
  int secretOffset = 0,
}) {
  return mul128Fold64(
    readLE64(input, inputOffset) ^ (readLE64(secret, secretOffset) + seed),
    readLE64(input, inputOffset + 8) ^
        (readLE64(secret, secretOffset + 8) - seed),
  );
}

/// Dart implementation of the xxh3_accumulate_512 hash function from XXH3.
void _xXH3Accumulate512(
  List<int> acc,
  Uint8List input,
  Uint8List secret, {
  int inputOffset = 0,
  int secretOffset = 0,
}) {
  for (var i = 0; i < kAccNB; i++) {
    final dataVal = readLE64(input, inputOffset + (8 * i));
    final dataKey = dataVal ^ readLE64(secret, secretOffset + (i * 8));
    acc[i ^ 1] += dataVal;
    acc[i] += dataKey.toUnsigned(32) * (dataKey >>> 32);
  }
}

/// The default [HashLongFunction] for XXH3.
int xXH3HashLong64bInternal(Uint8List input, int seed, Uint8List secret) {
  if (seed == 0) {
    secret = kSecret;
  } else if (secret == kSecret) {
    final kSecretDefaultSize = kSecret.lengthInBytes;
    final updatedSecret = Uint8List(kSecretDefaultSize);
    final secretData = ByteData.sublistView(updatedSecret);

    for (var i = 0; i < kSecretDefaultSize; i += 16) {
      secretData.setUint64(i, readLE64(kSecret, i) + seed, Endian.little);
      secretData.setUint64(
        i + 8,
        readLE64(kSecret, i + 8) - seed,
        Endian.little,
      );
    }

    secret = updatedSecret;
  }

  final length = input.lengthInBytes;
  final secretLength = secret.lengthInBytes;

  final acc = [
    kXXHPrime32_3,
    mix64(kXXHPrime64_1_HIGH, kXXHPrime64_1_LOW),
    mix64(kXXHPrime64_2_HIGH, kXXHPrime64_2_LOW),
    mix64(kXXHPrime64_3_HIGH, kXXHPrime64_3_LOW),
    mix64(kXXHPrime64_4_HIGH, kXXHPrime64_4_LOW),
    kXXHPrime32_2,
    mix64(kXXHPrime64_5_HIGH, kXXHPrime64_5_LOW),
    kXXHPrime32_1,
  ];
  final nbStripesPerBlock =
      (secretLength - kStripeLength) ~/ kSecretConsumeRate;
  final blockLen = kStripeLength * nbStripesPerBlock;
  final nbBlocks = (length - 1) ~/ blockLen;

  for (var n = 0; n < nbBlocks; n++) {
    for (var i = 0; i < nbStripesPerBlock; i++) {
      _xXH3Accumulate512(
        acc,
        input,
        secret,
        inputOffset: n * blockLen + i * kStripeLength,
        secretOffset: i * kSecretConsumeRate,
      );
    }

    for (var i = 0; i < kAccNB; i++) {
      acc[i] = (acc[i] ^
              (acc[i] >>> 47) ^
              readLE64(secret, secretLength - kStripeLength + 8 * i)) *
          kXXHPrime32_1;
    }
  }

  final nbStripes = ((length - 1) - (blockLen * nbBlocks)) ~/ kStripeLength;
  for (var i = 0; i < nbStripes; i++) {
    _xXH3Accumulate512(
      acc,
      input,
      secret,
      inputOffset: nbBlocks * blockLen + i * kStripeLength,
      secretOffset: i * kSecretConsumeRate,
    );
  }
  _xXH3Accumulate512(
    acc,
    input,
    secret,
    inputOffset: length - kStripeLength,
    secretOffset: secretLength - kStripeLength - 7,
  );
  var result = length * mix64(kXXHPrime64_1_HIGH, kXXHPrime64_1_LOW);
  for (var i = 0; i < 4; i++) {
    result += mul128Fold64(
      acc[2 * i] ^ readLE64(secret, 11 + 16 * i),
      acc[2 * i + 1] ^ readLE64(secret, 11 + 16 * i + 8),
    );
  }
  return _xXH3Avalanche(result);
}

/// The internal entry point for the 64-bit variant of the XXH3 hash.
int xXH3_64bitsInternal({
  required Uint8List input,
  required int seed,
  required Uint8List secret,
  required HashLongFunction hashLongFunction,
}) {
  if (secret.lengthInBytes < kSecretSizeMin) {
    throw ArgumentError.value(
      secret,
      'secret',
      'The specified secret is too short. It must be at least $kSecretSizeMin bytes.',
    );
  }

  final length = input.lengthInBytes;

  // Refer to XXH3_64bits_withSecretAndSeed, notice that if the seed is not
  // the default and the length is less than the midSizeMax, a custom secret
  // will be ignored.
  if (seed != 0 && length <= kXXH3MidSizeMax && secret != kSecret) {
    secret = kSecret;
    // The original source code also specifies hashLong as NULL, I'm assuming
    // that's because it would never be used with the length being less than
    // kXXH3MidSizeMax, rather than as a preventative measure.
  }

  if (length == 0) {
    return _xXH64Avalanche(
      seed ^ (readLE64(secret, 56) ^ readLE64(secret, 64)),
    );
  } else if (length < 4) {
    final keyed = ((((input[0])) << 16) |
            (((input[length >>> 1])) << 24) |
            input[length - 1] |
            ((length) << 8)) ^
        ((readLE32(secret) ^ readLE32(secret, 4)) + seed);

    return _xXH64Avalanche(keyed);
  } else if (length <= 8) {
    final keyed = (readLE32(input, length - 4) + ((readLE32(input)) << 32)) ^
        ((readLE64(secret, 8) ^ readLE64(secret, 16)) -
            (seed ^ ((swap32((seed))) << 32)));
    return _xXH3rrmxmx(keyed, length);
  } else if (length <= 16) {
    final inputLo = readLE64(input) ^
        ((readLE64(secret, 24) ^ readLE64(secret, 32)) + seed);
    final inputHi = readLE64(input, length - 8) ^
        ((readLE64(secret, 40) ^ readLE64(secret, 48)) - seed);
    final acc =
        length + swap64(inputLo) + inputHi + mul128Fold64(inputLo, inputHi);
    return _xXH3Avalanche(acc);
  } else if (length <= 128) {
    var acc = length * mix64(kXXHPrime64_1_HIGH, kXXHPrime64_1_LOW);
    var secretOff = 0;
    for (var i = 0, j = length; j > i; i += 16, j -= 16) {
      acc += _xXH3Mix16B(
        input,
        secret,
        seed,
        inputOffset: i,
        secretOffset: secretOff,
      );
      acc += _xXH3Mix16B(
        input,
        secret,
        seed,
        inputOffset: j - 16,
        secretOffset: secretOff + 16,
      );
      secretOff += 32;
    }
    return _xXH3Avalanche(acc);
  } else if (length <= 240) {
    var acc = length * mix64(kXXHPrime64_1_HIGH, kXXHPrime64_1_LOW);
    final nbRounds = length ~/ 16;

    var i = 0;
    for (; i < 8; ++i) {
      acc += _xXH3Mix16B(
        input,
        secret,
        seed,
        inputOffset: 16 * i,
        secretOffset: 16 * i,
      );
    }
    acc = _xXH3Avalanche(acc);

    for (; i < nbRounds; ++i) {
      acc += _xXH3Mix16B(
        input,
        secret,
        seed,
        inputOffset: 16 * i,
        secretOffset: 16 * (i - 8) + 3,
      );
    }

    acc += _xXH3Mix16B(
      input,
      secret,
      seed,
      inputOffset: length - 16,
      secretOffset: kSecretSizeMin - 17,
    );
    return _xXH3Avalanche(acc);
  } else {
    return hashLongFunction(input, seed, secret);
  }
}
