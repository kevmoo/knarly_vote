import 'package:knarly_server/src/trace_context.dart';
import 'package:test/test.dart';

void main() {
  group('bad inputs', () {
    for (var input in {
      '': 'Must come in 4 sections separated by "-".',
      'bad': 'Must come in 4 sections separated by "-".',
      '01-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01':
          'First section must be "00".',
      // trace-id
      '00-00000000000000000000000000000000-b7ad6b7169203331-01':
          'Trace-id cannot be zero.',
      '00-z-b7ad6b7169203331-01':
          // not hex
          'Trace-id section must be a 16 byte hex number.',
      '00-1-b7ad6b7169203331-01':
          // short
          'Trace-id section must be a 16 byte hex number.',
      '00-1000000000000000000000000000000000-b7ad6b7169203331-01':
          // long
          'Trace-id section must be a 16 byte hex number.',
      // parent-id
      '00-0af7651916cd43dd8448eb211c80319c-0000000000000000-01':
          'Parent-id cannot be zero.',
      '00-0af7651916cd43dd8448eb211c80319c-z-01':
          // not hex
          'Parent-id section must be a 8 byte hex number.',
      '00-0af7651916cd43dd8448eb211c80319c-0-01': // not hex
          // short
          'Parent-id section must be a 8 byte hex number.',
      '00-0af7651916cd43dd8448eb211c80319c-100000000000000000-01':
          // long
          'Parent-id section must be a 8 byte hex number.',
      // trace-flags
      '00-00000000000000000000000000000001-b7ad6b7169203331-z':
          // not hex
          'Trace-flags section must be a 1 byte hex number.',
      '00-00000000000000000000000000000001-b7ad6b7169203331-1234':
          // too long
          'Trace-flags section must be a 1 byte hex number.',
      '00-00000000000000000000000000000001-b7ad6b7169203331-0':
          // too short
          'Trace-flags section must be a 1 byte hex number.',
      '00-00000000000000000000000000000001-b7ad6b7169203331-zz':
          // too short
          'Trace-flags section is not a valid hex number.',
    }.entries) {
      test('"${input.key}" (${input.value})', () {
        expect(
          () => TraceContext.parse(input.key),
          throwsA(
            isA<ArgumentError>()
                .having((p0) => p0.message, 'message', input.value),
          ),
        );
      });
    }
  });

  group('good values', () {
    for (var input in {
      '00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01',
      '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01',
      '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-00',
    }) {
      test('"$input"', () {
        final value = TraceContext.parse(input);
        expect(value.toString(), input);
        expect(
          TraceContext.parse(value.toString()).toString(),
          input,
          reason: 'should round-trip fine',
        );

        final randomized = value.randomize();
        expect(randomized.traceId, value.traceId);
        expect(randomized.traceFlags, value.traceFlags);
        expect(randomized.parentId, isNot(value.parentId));
        expect(
          TraceContext.parse(randomized.toString()).toString(),
          randomized.toString(),
          reason: 'should round-trip fine',
        );
      });
    }
  });
}
