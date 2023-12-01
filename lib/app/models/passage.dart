import 'dart:convert';

import 'package:bulgarian.orthodox.bible/api/models/passage_response.dart';
import 'package:flutter/foundation.dart';

class Passage {
  final String title;
  final List<String> heads;

  Passage(
    this.title,
    this.heads,
  );

  Passage copyWith({
    String? title,
    List<String>? heads,
  }) {
    return Passage(
      title ?? this.title,
      heads ?? this.heads,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'heads': heads,
    };
  }

  factory Passage.fromMap(Map<String, dynamic> map) {
    return Passage(
      map['title'] ?? '',
      List<String>.from(map['heads']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Passage.fromJson(String source) =>
      Passage.fromMap(json.decode(source));

  @override
  String toString() => 'Passage(title: $title, heads: $heads)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Passage &&
        other.title == title &&
        listEquals(other.heads, heads);
  }

  @override
  int get hashCode => title.hashCode ^ heads.hashCode;

  static Passage fromResponse(PassageRespose resp) {
    return Passage(resp.title, resp.heads);
  }
}
