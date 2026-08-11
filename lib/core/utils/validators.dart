import 'package:petconnect_ai/core/utils/extensions/string_extensions.dart';

/// Reusable form-field validators.
///
/// Each returns `null` when valid or an error string when invalid, matching
/// the signature Flutter's [FormField.validator] expects.
abstract final class Validators {
  const Validators._();

  static String? required(String? value, {String field = 'This field'}) {
    if (value.isNullOrBlank) return '$field is required';
    return null;
  }

  static String? email(String? value) {
    if (value.isNullOrBlank) return 'Email is required';
    if (!value!.isValidEmail) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value, {int minLength = 8}) {
    if (value.isNullOrBlank) return 'Password is required';
    if (value!.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Include at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Include at least one number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value.isNullOrBlank) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? phone(String? value) {
    if (value.isNullOrBlank) return 'Phone number is required';
    if (!value!.isValidPhone) return 'Enter a valid phone number';
    return null;
  }

  static String? minLength(
    String? value,
    int min, {
    String field = 'This field',
  }) {
    if (value.isNullOrBlank) return '$field is required';
    if (value!.length < min) return '$field must be at least $min characters';
    return null;
  }

  /// Combines multiple validators, returning the first error found.
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
