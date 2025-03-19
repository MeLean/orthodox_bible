import 'package:shared_preferences/shared_preferences.dart';

mixin AppCache {
  static const _darkKey = 'dark_mode_key';
  static const _fileNumKey = 'file_num';
  static const _headIndexKey = 'head_index_num';
  static const _textSizeKey = 'text_size';
  static const _languageCode = 'cached_language_code';

  /// ✅ Save file number
  Future<void> saveFileNum(int num) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_fileNumKey, num);
  }

  /// ✅ Save head index
  Future<void> saveHeadIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_headIndexKey, index);
  }

  /// ✅ Save text size difference
  Future<void> saveDiffSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textSizeKey, size);
  }

  /// ✅ Save language code
  Future<void> saveLanguageCode(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCode, languageCode);
  }

  /// ✅ Save dark mode preference
  Future<void> saveLightMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_darkKey, mode);
  }

  /// ✅ Load file number (default if missing)
  Future<int> loadFileNum(int defaultValue) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_fileNumKey) ?? defaultValue;
  }

  /// ✅ Load head index (default if missing)
  Future<int> loadHeadIndex(int defaultValue) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_headIndexKey) ?? defaultValue;
  }

  /// ✅ Load text size difference (default if missing)
  Future<double> loadTextSizeDiff(double defaultValue) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_textSizeKey) ?? defaultValue;
  }

  /// ✅ Load cached language code
  Future<String?> loadCachedLanguageCodeOrNull() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageCode);
  }

  /// ✅ Load dark mode preference
  Future<String?> loadLightMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_darkKey);
  }
}
