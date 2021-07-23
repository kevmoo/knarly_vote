import 'dart:math';
import 'dart:typed_data';

class TraceContext {
  final String traceId;
  final String parentId;
  final String traceFlags;

  TraceContext._(this.traceId, this.parentId, this.traceFlags);

  factory TraceContext.parse(String input) {
    final sections = input.split('-');
    if (sections.length != 4) {
      throw ArgumentError('Must come in 4 sections separated by "-".');
    }

    if (sections.first != '00') {
      throw ArgumentError('First section must be "00".');
    }

    return TraceContext._(
      _parse('Trace-id', sections[1], 16),
      _parse('Parent-id', sections[2], 8),
      _parse('Trace-flags', sections[3], 1, allowZeros: true),
    );
  }

  /// Returns a new [TraceContext] with a randomized [parentId].
  TraceContext randomize({Random? random}) {
    random ??= Random();

    String newParentId;
    do {
      final words = Uint32List(2);
      for (var i = 0; i < 2; i++) {
        words[i] = random.nextInt(_twoBytes);
      }

      final bytes = Uint8List.view(words.buffer);

      newParentId =
          bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    } while (_allZeros.hasMatch(newParentId));

    return TraceContext._(traceId, newParentId, traceFlags);
  }

  @override
  String toString() => '00-$traceId-$parentId-$traceFlags';
}

final _hexThing = RegExp(r'^(?:[0-9a-f][0-9a-f])+$');
final _allZeros = RegExp(r'^0+$');

String _parse(
  String name,
  String value,
  int byteCount, {
  bool allowZeros = false,
}) {
  if (value.length != byteCount * 2) {
    throw ArgumentError(
      '$name section must be a $byteCount byte hex number.',
    );
  }

  if (!allowZeros && _allZeros.hasMatch(value)) {
    throw ArgumentError('$name cannot be zero.');
  }

  if (!_hexThing.hasMatch(value)) {
    throw ArgumentError('$name section is not a valid hex number.');
  }

  return value;
}

const _twoBytes = 256 * 256 * 256 * 256;
