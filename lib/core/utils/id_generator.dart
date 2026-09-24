import 'dart:math';

/// Generates short random identifiers without pulling in a uuid package.
class IdGenerator {
  IdGenerator([Random? random]) : _random = random ?? Random.secure();

  final Random _random;

  String next([String prefix = '']) {
    final buffer = StringBuffer(prefix);
    for (var i = 0; i < 16; i++) {
      buffer.write(_random.nextInt(16).toRadixString(16));
    }
    return buffer.toString();
  }
}
