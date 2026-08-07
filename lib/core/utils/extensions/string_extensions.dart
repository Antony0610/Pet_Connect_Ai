/// Extensions on [String] for validation and formatting.
extension StringExtensions on String {
  /// Whether the string is empty or only whitespace.
  bool get isBlank => trim().isEmpty;

  /// Whether the string is neither null nor blank.
  bool get isNotBlank => !isBlank;

  /// Capitalizes the first letter.
  String get capitalize =>
      isEmpty ? this : this[0].toUpperCase() + substring(1);

  /// Capitalizes the first letter of each word.
  String get titleCase => split(' ').map((word) => word.capitalize).join(' ');

  /// Basic email validation (format only).
  bool get isValidEmail {
    final regex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@"
      r'[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    return regex.hasMatch(this);
  }

  /// Basic phone validation (digits only, 10-15 chars).
  bool get isValidPhone {
    final digitsOnly = replaceAll(RegExp(r'\D'), '');
    return digitsOnly.length >= 10 && digitsOnly.length <= 15;
  }

  /// Truncates to [maxLength] and appends [ellipsis] if needed.
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }
}

/// Extensions on nullable [String].
extension NullableStringExtensions on String? {
  /// Whether the string is null, empty, or only whitespace.
  bool get isNullOrBlank => this?.isBlank ?? true;

  /// The string if not blank, else [fallback].
  String orElse(String fallback) =>
      (this != null && this!.isNotBlank) ? this! : fallback;
}
