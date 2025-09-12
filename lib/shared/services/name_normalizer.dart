/// Name normalization and comparison utilities used across Vault/Folder/Note.
///
/// Goals
/// - Provide a consistent, cross-platform safe display name policy.
/// - Normalize whitespace, strip control/forbidden characters, and cap length.
/// - Offer a stable comparison key for case-insensitive uniqueness checks.
class NameNormalizer {
  NameNormalizer._();

  /// Maximum safe length for names (UI and filesystem friendly).
  static const int defaultMaxLength = 120;

  /// Windows reserved device names (case-insensitive).
  static const Set<String> _reservedBaseNames = {
    '.',
    '..',
    'con',
    'prn',
    'aux',
    'nul',
    'com1',
    'com2',
    'com3',
    'com4',
    'com5',
    'com6',
    'com7',
    'com8',
    'com9',
    'lpt1',
    'lpt2',
    'lpt3',
    'lpt4',
    'lpt5',
    'lpt6',
    'lpt7',
    'lpt8',
    'lpt9',
  };

  /// Normalizes a name with a conservative, dependency-free policy.
  ///
  /// Steps:
  /// - Trim leading/trailing whitespace
  /// - Collapse inner whitespace to a single space
  /// - Remove control chars (U+0000–U+001F)
  /// - Remove forbidden characters: / \ : * ? " < > |
  /// - Disallow base reserved names (., .., CON, PRN, ...)
  /// - Trim again and enforce max length
  ///
  /// Throws [FormatException] if the name becomes empty or reserved.
  static String normalize(
    String input, {
    int maxLength = defaultMaxLength,
  }) {
    var s = input.trim();

    // Collapse any whitespace to a single ASCII space.
    s = s.replaceAll(RegExp(r'\s+'), ' ');

    // Strip control characters.
    s = s.replaceAll(RegExp(r'[\x00-\x1F]'), '');

    // Remove common forbidden filesystem characters.
    s = s.replaceAll(RegExp(r'[/:*?"<>|\\]'), '');

    // Remove trailing periods/spaces (Windows quirk) and re-trim.
    s = s.replaceAll(RegExp(r'[ .]+$'), '');
    s = s.trim();

    if (s.isEmpty) {
      throw const FormatException('Name becomes empty after normalization');
    }

    // Reserved device/base names (case-insensitive) without extension.
    final lower = s.toLowerCase();
    final base = lower.split('.').first;
    if (_reservedBaseNames.contains(base)) {
      throw const FormatException('Reserved name is not allowed');
    }

    if (s.length > maxLength) {
      s = s.substring(0, maxLength);
    }
    return s;
  }

  /// Returns a stable, case-insensitive comparison key for uniqueness checks.
  ///
  /// Note: This is a best-effort fold using `toLowerCase()`; when a proper
  /// Unicode casefold/NFKC is introduced, this can be swapped without callers
  /// changing behavior.
  static String compareKey(String input) {
    final trimmed = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    return trimmed.toLowerCase();
  }
}
