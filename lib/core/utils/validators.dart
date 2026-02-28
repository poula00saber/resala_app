// ============================================
// FILE: lib/core/utils/validators.dart
// ============================================

class Validators {
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال الاسم';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال رقم الهاتف';
    }
    if (value.length != 11) {
      return 'رقم الهاتف يجب أن يكون 11 رقم';
    }
    if (!value.startsWith('01')) {
      return 'رقم الهاتف يجب أن يبدأ بـ 01';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني';
    }
    if (!value.contains('@')) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال $fieldName';
    }
    return null;
  }

  /// Validate Egyptian National ID (must be exactly 14 digits)
  static String? validateNationalId(String? value) {
    if (value == null || value.isEmpty) {
      return null; // National ID is optional
    }
    if (value.length != 14) {
      return 'الرقم القومي يجب أن يكون 14 رقم';
    }
    if (!RegExp(r'^\d{14}$').hasMatch(value)) {
      return 'الرقم القومي يجب أن يحتوي على أرقام فقط';
    }
    // First digit must be 2 (1900s) or 3 (2000s)
    final firstDigit = int.parse(value[0]);
    if (firstDigit != 2 && firstDigit != 3) {
      return 'الرقم القومي غير صحيح';
    }
    return null;
  }

  /// Parse Egyptian 14-digit National ID to extract birth date and calculate age.
  /// Returns null if ID is invalid.
  /// Format: C YYMMDD GGGG S NN K
  ///   C = century (2 = 1900s, 3 = 2000s)
  ///   YYMMDD = birth date
  ///   GGGG = governorate code
  ///   S = sequence (odd = male, even = female)
  ///   NN = sequence
  ///   K = check digit
  static NationalIdData? parseNationalId(String nid) {
    if (nid.length != 14 || !RegExp(r'^\d{14}$').hasMatch(nid)) {
      return null;
    }

    final century = int.parse(nid[0]);
    if (century != 2 && century != 3) return null;

    final centuryBase = century == 2 ? 1900 : 2000;
    final year = centuryBase + int.parse(nid.substring(1, 3));
    final month = int.parse(nid.substring(3, 5));
    final day = int.parse(nid.substring(5, 7));

    // Validate date components
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    try {
      final birthDate = DateTime(year, month, day);
      // Verify the date is valid (e.g., not Feb 30)
      if (birthDate.month != month || birthDate.day != day) return null;

      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      // Gender from 13th digit (index 12): odd = male, even = female
      final genderDigit = int.parse(nid[12]);
      final gender = genderDigit % 2 == 1 ? 'ذكر' : 'أنثى';

      final birthDateStr =
          '${birthDate.year}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}';

      return NationalIdData(birthDate: birthDateStr, age: age, gender: gender);
    } catch (e) {
      return null;
    }
  }
}

/// Data parsed from an Egyptian National ID
class NationalIdData {
  final String birthDate;
  final int age;
  final String gender;

  NationalIdData({
    required this.birthDate,
    required this.age,
    required this.gender,
  });
}
