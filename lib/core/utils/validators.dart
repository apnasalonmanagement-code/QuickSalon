
/// Shared client-side validation rules for registration and account security.
class AppValidators {
  AppValidators._();

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
    final email = (value ?? '').trim();

    if (email.isEmpty) {
      return 'Email is required.';
    }

    final emailRegex = RegExp(
      r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)+$",
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address, for example name@example.com.';
    }

    return null;
  }

  static String? password(
    String? value,
  ) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Password is required.';
    }

    final missing = <String>[];

    if (password.length < 8) {
      missing.add('at least 8 characters');
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      missing.add('one uppercase letter (A–Z)');
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      missing.add('one lowercase letter (a–z)');
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      missing.add('one number (0–9)');
    }

    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      missing.add(r'one special character (e.g. !@#$%)');
    }

    if (missing.isNotEmpty) {
      return 'Password needs: ${missing.join(', ')}.';
    }

    return null;
  }

  static String? phone(
    String? value, {
    bool required = true,
  }) {
    final phone = (value ?? '').trim();

    if (phone.isEmpty) {
      return required ? 'Mobile number is required.' : null;
    }

    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      return 'Mobile number must contain exactly 10 digits (0–9), without +91 or spaces.';
    }

    return null;
  }
}

/// Backward compatibility for existing code using Validators.
class Validators {
  Validators._();

  static String? required(
    String? value,
    String fieldName,
  ) {
    return AppValidators.required(value, fieldName);
  }

  static String? email(
    String? value,
  ) {
    return AppValidators.email(value);
  }

  static String? password(
    String? value,
  ) {
    return AppValidators.password(value);
  }

  static String? phone(
    String? value, {
    bool required = true,
  }) {
    return AppValidators.phone(
      value,
      required: required,
    );
  }
}
