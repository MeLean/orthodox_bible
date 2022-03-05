import 'package:flutter_secure_storage/flutter_secure_storage.dart';

mixin AppCache {
  static const _encrStorage = FlutterSecureStorage();
  static const _fileNumKey = 'file_num';
  static const _headIndexKey = 'head_index_num';
  static const _textSizeKey = 'text_size';
  static const _localeKey = 'cached_locale';

  Future<void> saveFileNum(int num) async {
    return _saveString(_fileNumKey, num.toString());
  }

  Future<void> saveHeadIndex(int index) async {
    return _saveString(_headIndexKey, index.toString());
  }

  Future<void> saveTextSize(double size) async {
    return _saveString(_textSizeKey, size.toString());
  }

  Future<void> saveLocale(String locale) async {
    return _saveString(_localeKey, locale);
  }

  Future<int> loadFileNum(int defaultValue) async {
    return await _loadInt(_fileNumKey) ?? defaultValue;
  }

  Future<int> loadHeadIndex(int defaultValue) async {
    return await _loadInt(_headIndexKey) ?? defaultValue;
  }

  Future<double> loadTextSize(double defaultValue) async {
    final strValue = await _loadString(_textSizeKey);
    double result = defaultValue;

    try {
      if (strValue != null) {
        result = double.parse(strValue);
      }
    } on Exception {
      //do nothing
    }

    return result;
  }

  Future<String> loadCachedLocale(String defaultLocaleName) async {
    return await _loadString(_localeKey) ?? defaultLocaleName;
  }

  Future<void> _saveString(String key, String value) async {
    return _encrStorage.write(key: key, value: value);
  }

  Future<int?> _loadInt(String key) async {
    final str = await _loadString(key);
    int? result;
    try {
      if (str != null) {
        result = int.parse(str);
      }
    } on Exception {
      result = null;
    }

    return result;
  }

  Future<String?> _loadString(String key) async {
    return _encrStorage.read(key: key);
  }
}
