// ignore_for_file: public_member_api_docs
// ignore_for_file: constant_identifier_names

part of isar;

//
// Buffers
//

/// Reads a 32-bit little-endian integer from the specified buffer at the
/// specified byte offset. (If unspecified, [byteOffset] is 0 which means the
// /// value is read from the start of the buffer.)
int readLE32(Uint8List value, [int byteOffset = 0]) {
  return ByteData.sublistView(value).getUint32(byteOffset, Endian.little);
}

/// Reads a 64-bit little-endian integer from the specified buffer at the
/// specified byte offset. (If unspecified, [byteOffset] is 0 which means the
/// value is read from the start of the buffer.)
int readLE64(Uint8List value, [int byteOffset = 0]) {
  return ByteData.sublistView(value).getUint64(byteOffset, Endian.little);
}

//
// Math
//

/// Holds a pair of integers, aims to be analogous to an std::pair in C++.
/// Used to represent a 128-bit integer.
class PairInt {
  PairInt(this.lhs, this.rhs);
  int lhs;
  int rhs;
}

/// Multiplies the 64-bit integers stored in [lhs] and [rhs] (bitwise) and
/// stores the result in a 128-bit integer in the form of a [PairInt].
PairInt mult64to128(int lhs, int rhs) {
  final loLo = (lhs.toUnsigned(32) * rhs.toUnsigned(32)).toUnsigned(64);
  final hiLo = (lhs >>> 32) * rhs.toUnsigned(32);
  final loHi = lhs.toUnsigned(32) * (rhs >>> 32);
  final hiHi = (lhs >>> 32) * (rhs >>> 32);
  final cross = (loLo >>> 32) + hiLo.toUnsigned(32) + loHi;
  final upper = (hiLo >>> 32) + (cross >>> 32) + hiHi;
  final lower = (cross << 32) | loLo.toUnsigned(32);
  return PairInt(lower, upper);
}

/// Multiplies [lhs] and [rhs], bitwise, storing the result in a 128-bit
/// integer with [mult64to128], then XORs the resulting pair of 64-bit integers
/// to 'fold' it back into a 64-bit integer.
int mul128Fold64(int lhs, int rhs) {
  final product = mult64to128(lhs, rhs);
  return product.lhs ^ product.rhs;
}

/// Swaps the byte order of a 32-bit integer.
int swap32(int x) {
  return ((x << 24) & 0xff000000) |
      ((x << 8) & 0x00ff0000) |
      ((x >>> 8) & 0x0000ff00) |
      ((x >>> 24) & 0x000000ff);
}

/// Swaps the byte order of a 64-bit integer.
int swap64(int x) {
  return ((x << 56) & 0xff00000000000000) |
      ((x << 40) & 0x00ff000000000000) |
      ((x << 24) & 0x0000ff0000000000) |
      ((x << 8) & 0x000000ff00000000) |
      ((x >>> 8) & 0x00000000ff000000) |
      ((x >>> 24) & 0x0000000000ff0000) |
      ((x >>> 40) & 0x000000000000ff00) |
      ((x >>> 56) & 0x00000000000000ff);
}
