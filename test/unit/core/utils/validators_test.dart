import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect_ai/core/utils/validators.dart';

void main() {
  group('Validators.required', () {
    test('returns error when value is null', () {
      expect(Validators.required(null), 'This field is required');
    });

    test('returns error when value is empty', () {
      expect(Validators.required(''), 'This field is required');
    });

    test('returns error when value is whitespace', () {
      expect(Validators.required('   '), 'This field is required');
    });

    test('returns null when value is valid', () {
      expect(Validators.required('valid'), null);
    });

    test('uses custom field name', () {
      expect(Validators.required(null, field: 'Username'), 'Username is required');
    });
  });

  group('Validators.email', () {
    test('returns error when email is null', () {
      expect(Validators.email(null), 'Email is required');
    });

    test('returns error when email is empty', () {
      expect(Validators.email(''), 'Email is required');
    });

    test('returns error for invalid format', () {
      expect(Validators.email('notanemail'), 'Enter a valid email address');
      expect(Validators.email('missing@domain'), 'Enter a valid email address');
      expect(Validators.email('@example.com'), 'Enter a valid email address');
    });

    test('returns null for valid email', () {
      expect(Validators.email('user@example.com'), null);
      expect(Validators.email('test.user@domain.co.uk'), null);
    });
  });

  group('Validators.password', () {
    test('returns error when password is null', () {
      expect(Validators.password(null), 'Password is required');
    });

    test('returns error when too short', () {
      expect(Validators.password('Short1'), 'Password must be at least 8 characters');
    });

    test('returns error when missing uppercase', () {
      expect(Validators.password('lowercase123'), 'Include at least one uppercase letter');
    });

    test('returns error when missing number', () {
      expect(Validators.password('NoNumbers'), 'Include at least one number');
    });

    test('returns null for valid password', () {
      expect(Validators.password('Valid123'), null);
      expect(Validators.password('Strong1Password'), null);
    });

    test('respects custom minLength', () {
      expect(Validators.password('Ab1', minLength: 3), null);
      expect(Validators.password('Ab1', minLength: 4), 'Password must be at least 4 characters');
    });
  });

  group('Validators.confirmPassword', () {
    test('returns error when value is null', () {
      expect(Validators.confirmPassword(null, 'original'), 'Please confirm your password');
    });

    test('returns error when passwords do not match', () {
      expect(Validators.confirmPassword('different', 'original'), 'Passwords do not match');
    });

    test('returns null when passwords match', () {
      expect(Validators.confirmPassword('same', 'same'), null);
    });
  });

  group('Validators.phone', () {
    test('returns error when phone is null', () {
      expect(Validators.phone(null), 'Phone number is required');
    });

    test('returns error when too short', () {
      expect(Validators.phone('123'), 'Enter a valid phone number');
    });

    test('returns error when too long', () {
      expect(Validators.phone('12345678901234567890'), 'Enter a valid phone number');
    });

    test('returns null for valid phone numbers', () {
      expect(Validators.phone('1234567890'), null);
      expect(Validators.phone('+1 (555) 123-4567'), null); // formats with 10-15 digits
      expect(Validators.phone('555-1234-5678'), null);
    });
  });

  group('Validators.minLength', () {
    test('returns error when value is null', () {
      expect(Validators.minLength(null, 5), 'This field is required');
    });

    test('returns error when value is too short', () {
      expect(Validators.minLength('abc', 5), 'This field must be at least 5 characters');
    });

    test('returns null when value meets minimum', () {
      expect(Validators.minLength('hello', 5), null);
      expect(Validators.minLength('hello world', 5), null);
    });

    test('uses custom field name', () {
      expect(Validators.minLength('ab', 3, field: 'Username'), 'Username must be at least 3 characters');
    });
  });

  group('Validators.compose', () {
    test('returns first error when multiple validators fail', () {
      final validator = Validators.compose([
        Validators.required,
        (v) => Validators.minLength(v, 5),
      ]);
      expect(validator(null), 'This field is required');
      expect(validator('ab'), 'This field must be at least 5 characters');
    });

    test('returns null when all validators pass', () {
      final validator = Validators.compose([
        Validators.required,
        (v) => Validators.minLength(v, 3),
      ]);
      expect(validator('hello'), null);
    });

    test('works with empty validator list', () {
      final validator = Validators.compose([]);
      expect(validator('anything'), null);
    });
  });
}
