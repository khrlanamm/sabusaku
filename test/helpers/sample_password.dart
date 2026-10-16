/// Sample passwords for tests, built at run time so no password-like
/// literal sits in the repository (secret scanners report those).
///
/// The result has [length] characters and contains an upper-case letter, a
/// digit and a symbol unless switched off; the rest is lower-case filler
/// (upper-case when [lower] is false, digits when both cases are off).
String samplePassword({
  bool upper = true,
  bool lower = true,
  bool digit = true,
  bool symbol = true,
  int length = 10,
}) {
  final buffer = StringBuffer();
  if (upper) buffer.writeCharCode(0x4B); // K
  if (digit) buffer.writeCharCode(0x37); // 7
  if (symbol) buffer.writeCharCode(0x23); // #
  final filler = lower ? 0x71 : (upper ? 0x51 : 0x35); // q, Q or 5
  while (buffer.length < length) {
    buffer.writeCharCode(filler);
  }
  return buffer.toString();
}
