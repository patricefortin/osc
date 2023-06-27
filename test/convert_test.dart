// Copyright (c) 2021, Google LLC. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:osc/src/convert.dart';
import 'package:osc/src/message.dart';
import 'package:test/test.dart';

void main() {
  group('codecs', () {
    group('forType', () {
      test('unknown', () {
        expect(() => DataCodec.forType('x'),
            throwsA(const TypeMatcher<ArgumentError>()));
      });
      test('blob', () {
        expect(DataCodec.forType('b'), blobCodec);
      });
      test('float', () {
        expect(DataCodec.forType('f'), floatCodec);
      });
      test('string', () {
        expect(DataCodec.forType('s'), stringCodec);
      });
      test('h (64bits integer)', () {
        expect(DataCodec.forType('h'), int64Codec);
      });
      test('true (boolean)', () {
        expect(DataCodec.forType('T'), boolTrueCodec);
      });
      test('false (boolean)', () {
        expect(DataCodec.forType('F'), boolFalseCodec);
      });
    });

    group('messages', () {
      group('encode', () {
        test('empty', () {
          final message = OSCMessage('/empty', arguments: []);
          expect(oscMessageCodec.encode(message),
              [47, 101, 109, 112, 116, 121, 0, 0, 44, 0, 0, 0]);
        });
        test('int', () {
          final message = OSCMessage('/int', arguments: [99]);
          expect(oscMessageCodec.encode(message),
              [47, 105, 110, 116, 0, 0, 0, 0, 44, 105, 0, 0, 0, 0, 0, 99]);
        });
      });
      group('decode', () {
        test('empty', () {
          final message = oscMessageCodec
              .decode([47, 101, 109, 112, 116, 121, 0, 0, 44, 0, 0, 0]);
          expect(message.address, '/empty');
          expect(message.arguments, isEmpty);
        });
        test('int', () {
          final message = oscMessageCodec.decode(
              [47, 105, 110, 116, 0, 0, 0, 0, 44, 105, 0, 0, 0, 0, 0, 99]);
          expect(message.address, '/int');
          expect(message.arguments, <Object>[99]);
        });
      });
    });

    group('equality', () {
      test('==', () {
        final message1 = OSCMessage('/baz', arguments: ['foo', 'bar', 1, 2, 3]);
        final message2 = OSCMessage('/baz', arguments: ['foo', 'bar', 1, 2, 3]);
        expect(message1, message2);
      });
      test('hash', () {
        final message1 = OSCMessage('/baz', arguments: ['foo', 'bar', 1, 2, 3]);
        final message2 =
            OSCMessage('/baz', arguments: ['foo', 'bar', 1, 2, 3, 4]);
        expect(message1.hashCode, isNot(equals(message2.hashCode)));
      });
    });

    group('ints', () {
      test('decode', () {
        expect(intCodec.decoder.convert([0, 0, 0, 13]), 13);
      });

      test('encode', () {
        expect(intCodec.encoder.convert(13), [0, 0, 0, 13]);
      });
    });

    group('floats', () {
      test('decode', () {
        expect(floatCodec.decoder.convert([66, 246, 230, 102]),
            closeTo(123.45, 1e-5));
      });

      test('encode', () {
        expect(floatCodec.encoder.convert(123.45), [66, 246, 230, 102]);
      });
    });

    group('strings', () {
      test('decode', () {
        expect(stringCodec.decoder.convert([102, 111, 111]), 'foo');
      });

      test('encode', () {
        expect(stringCodec.encoder.convert('foo'), [102, 111, 111, 0]);
      });
    });

    group('int64s', () {
      test('decode', () {
        var dec = int64Codec.decoder;
        expect(dec.convert([0, 0, 0, 0, 0, 0, 0, 9]), BigInt.from(9));
        expect(dec.convert([0, 0, 0, 0, 0, 0, 0, 0xff]), (BigInt.from(255)));
        expect(dec.convert([0, 0, 0, 0, 0xff, 0xff, 0xff, 0xff]),
            (BigInt.from(1) << 32) - BigInt.from(1));
        expect(dec.convert([0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]),
            (BigInt.from(1) << 64) - BigInt.from(1));
      });

      test('encode', () {
        var enc = int64Codec.encoder;
        expect(enc.convert(BigInt.from(9)), [0, 0, 0, 0, 0, 0, 0, 9]);
        expect(enc.convert(BigInt.from(255)), [0, 0, 0, 0, 0, 0, 0, 0xff]);
        expect(enc.convert((BigInt.from(1) << 32) - BigInt.from(1)),
            [0, 0, 0, 0, 0xff, 0xff, 0xff, 0xff]);
        expect(enc.convert((BigInt.from(1) << 64) - BigInt.from(1)),
            [0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]);
      });

      test('appliesTo', () {
        expect(int64Codec.appliesTo(BigInt.one), true);
        expect(int64Codec.appliesTo(1), false);
      });
    });

    group('true (boolean)', () {
      test('decode', () {
        expect(boolTrueCodec.decoder.convert([]), true);
      });

      test('encode', () {
        expect(boolTrueCodec.encoder.convert(true), []);
      });

      test('appliesTo', () {
        expect(boolTrueCodec.appliesTo(true), true);
        expect(boolTrueCodec.appliesTo(false), false);
      });
    });

    group('false (boolean)', () {
      test('decode', () {
        expect(boolFalseCodec.decoder.convert([]), false);
      });

      test('encode', () {
        expect(boolFalseCodec.encoder.convert(false), []);
      });

      test('appliesTo', () {
        expect(boolFalseCodec.appliesTo(false), true);
        expect(boolFalseCodec.appliesTo(true), false);
      });
    });
  });
}
