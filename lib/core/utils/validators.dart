class Validators {
  Validators._();

  static String? required(
    String? value,
    String fieldName,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return '$fieldName is required.';
    }

    return null;
  }

  static String? email(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Email is required.';
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(
      value.trim(),
    )) {
      return 'Enter a valid email.';
    }

    return null;
  }

  static String? password(
    String? value,
  ) {
    if (value == null ||
        value.isEmpty) {
      return 'Password is required.';
    }

    if (value.length < 6) {
      return 'Password must contain at least 6 characters.';
    }

    return null;
  }

  static String? phone(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Phone is required.';
    }

    final cleaned =
        value.replaceAll(RegExp(r'\D'), '');

    if (cleaned.length < 10) {
      return 'Enter a valid phone number.';
    }

    return null;
  }
}