// Central validation & sanitization utilities for MessKhojo forms.
//
// Indian phone number rules:
//  - Exactly 10 digits
//  - Must start with 6, 7, 8, or 9

/// Validates and sanitizes an Indian mobile number.
/// Returns null on success, or an error string on failure.
String? validateIndianPhone(String? value, {String fieldName = 'Phone number'}) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  final digits = value.trim().replaceAll(RegExp(r'\D'), '');
  if (digits.length != 10) {
    return '$fieldName must be exactly 10 digits';
  }
  final firstDigit = int.parse(digits[0]);
  if (firstDigit < 6) {
    return 'Enter a valid Indian mobile number';
  }
  return null;
}

/// Sanitizes a phone string — strips all non-digit characters.
String sanitizePhone(String value) => value.replaceAll(RegExp(r'\D'), '');

/// Validates a required name field.
String? validateName(String? value, {String fieldName = 'Name', int minLength = 2}) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  if (value.trim().length < minLength) {
    return '$fieldName must be at least $minLength characters';
  }
  // Reject names that are all numbers
  if (RegExp(r'^\d+$').hasMatch(value.trim())) {
    return 'Please enter a valid $fieldName';
  }
  return null;
}

/// Validates a required field is not empty.
String? validateRequired(String? value, {String fieldName = 'This field'}) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  return null;
}

/// Validates a numeric amount (price, budget, etc.) with optional min/max.
String? validateAmount(String? value, {
  String fieldName = 'Amount',
  double? min,
  double? max,
}) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  final parsed = double.tryParse(value.trim());
  if (parsed == null) {
    return '$fieldName must be a valid number';
  }
  if (min != null && parsed < min) {
    return '$fieldName must be at least ₹${min.toStringAsFixed(0)}';
  }
  if (max != null && parsed > max) {
    return '$fieldName must not exceed ₹${max.toStringAsFixed(0)}';
  }
  return null;
}
