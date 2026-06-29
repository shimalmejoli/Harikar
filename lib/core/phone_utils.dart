// lib/core/phone_utils.dart
// ─────────────────────────────────────────────────────────────
// Iraqi mobile-number normalization & validation.
//
// Canonical form stored in DB / sent to backend:
//   10 digits, no leading 0, no country code.
//   Examples: 7504848085, 7711234567
//
// Accepted user input forms:
//   07504848085           ← classic local form (most common)
//   7504848085            ← canonical
//   +9647504848085        ← international
//   00964 750 484 8085    ← international w/ leading 00
//   0750 484 8085         ← spaced
//   0750-484-8085         ← dashed
//
// Iraqi mobile prefixes (after stripping country code & leading 0):
//   75x  → Korek / Asiacell-portability
//   77x  → Asiacell
//   78x  → Zain Iraq
//   79x  → Zain Iraq / Korek
// ─────────────────────────────────────────────────────────────

class IqPhone {
  IqPhone._();

  static const List<String> _validPrefixes = ['75', '77', '78', '79'];

  /// Reduce any user-entered string to the canonical 10-digit form.
  /// Strips spaces, dashes, parentheses, '+', leading '00', country
  /// code '964', and a single leading '0'. Non-digit chars are dropped.
  /// Returns whatever digits remain — caller should validate via [isValid].
  static String normalize(String input) {
    if (input.isEmpty) return '';

    // Keep digits only.
    var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';

    // Strip international prefixes.
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('964')) {
      digits = digits.substring(3);
    }

    // Strip leading 0 (local form).
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    return digits;
  }

  /// True iff [input] normalizes to a valid 10-digit Iraqi mobile.
  static bool isValid(String input) {
    final n = normalize(input);
    if (n.length != 10) return false;
    final prefix = n.substring(0, 2);
    return _validPrefixes.contains(prefix);
  }

  /// Loose check used to decide whether to run [normalize] on login
  /// input — i.e. is the user typing a phone number rather than a
  /// username? Just looks at the character set.
  static bool looksLikePhone(String input) {
    final s = input.trim();
    if (s.isEmpty) return false;
    // Allowed in a phone string: digits, +, -, space, parentheses.
    return RegExp(r'^[0-9+\-\s()]+$').hasMatch(s);
  }

  /// Format the canonical 10-digit number for display:
  ///   '7504848085' → '0750 484 8085'
  /// Returns the raw input untouched if it doesn't look canonical.
  static String pretty(String input) {
    final n = normalize(input);
    if (n.length != 10) return input;
    return '0${n.substring(0, 3)} ${n.substring(3, 6)} ${n.substring(6)}';
  }
}
