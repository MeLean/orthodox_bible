class Constants {
  static const double maxTextSize = 36;
  static const double minTextSize = 12;

  static const double defaultTextSize = 16.0;
  static const double defaultTitleSize = 18.0;

  static const double defaultTextDiff = 0.0;

  // Calculation helpers (shared by all screens)
  static double calcTitleSize(double diff) => (defaultTitleSize + diff).clamp(minTextSize, maxTextSize);

  static double calcTextSize(double diff) => (defaultTextSize + diff).clamp(minTextSize, maxTextSize);
}
