import 'dart:convert';

class SearchResult {
  String passageTitle;
  int headIndex;
  int rowNum;
  String text;

  SearchResult({
    required this.passageTitle,
    required this.headIndex,
    required this.rowNum,
    required this.text,
  });

  SearchResult copyWith({
    String? passageTitle,
    int? headIndex,
    int? rowNum,
    String? text,
  }) {
    return SearchResult(
      passageTitle: passageTitle ?? this.passageTitle,
      headIndex: headIndex ?? this.headIndex,
      rowNum: rowNum ?? this.rowNum,
      text: text ?? this.text,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'passageTitle': passageTitle,
      'headIndex': headIndex,
      'rowNum': rowNum,
      'text': text,
    };
  }

  factory SearchResult.fromMap(Map<String, dynamic> map) {
    return SearchResult(
      passageTitle: map['passageTitle'] ?? '',
      headIndex: map['headIndex']?.toInt() ?? 0,
      rowNum: map['rowNum']?.toInt() ?? 0,
      text: map['text'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory SearchResult.fromJson(String source) =>
      SearchResult.fromMap(json.decode(source));

  @override
  String toString() {
    return 'SearchResult(passageTitle: $passageTitle, headIndex: $headIndex, rowNum: $rowNum, text: $text)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SearchResult &&
        other.passageTitle == passageTitle &&
        other.headIndex == headIndex &&
        other.rowNum == rowNum &&
        other.text == text;
  }

  @override
  int get hashCode {
    return passageTitle.hashCode ^
        headIndex.hashCode ^
        rowNum.hashCode ^
        text.hashCode;
  }

  String prityPrint() => '"$text"\n$passageTitle [${headIndex + 1} : $rowNum]';
}
