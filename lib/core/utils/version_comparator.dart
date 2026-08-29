class VersionComparator {
  /// Compares two version strings (e.g., "1.7.14" vs "1.8.0").
  /// Returns:
  ///   < 0 if [v1] < [v2]
  ///     0 if [v1] == [v2]
  ///   > 0 if [v1] > [v2]
  static int compare(String v1, String v2) {
    final clean1 = _cleanVersion(v1);
    final clean2 = _cleanVersion(v2);

    final parts1 = clean1.split('.');
    final parts2 = clean2.split('.');

    final maxLength = parts1.length > parts2.length ? parts1.length : parts2.length;

    for (int i = 0; i < maxLength; i++) {
      final p1 = i < parts1.length ? (int.tryParse(parts1[i]) ?? 0) : 0;
      final p2 = i < parts2.length ? (int.tryParse(parts2[i]) ?? 0) : 0;

      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }

    return 0;
  }

  static String _cleanVersion(String v) {
    // Strip build numbers after '+' or hyphens
    var s = v.trim();
    if (s.contains('+')) {
      s = s.split('+').first;
    }
    if (s.contains('-')) {
      s = s.split('-').first;
    }
    return s;
  }
}
