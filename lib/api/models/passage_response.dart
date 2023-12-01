import 'dart:convert';

import 'package:flutter/foundation.dart';

class PassageRespose {
  String title;
  List<String> heads;
  int num;

  PassageRespose({
    required this.title,
    required this.heads,
    required this.num,
  });

  PassageRespose copyWith({
    String? title,
    List<String>? heads,
    int? num,
  }) {
    return PassageRespose(
      title: title ?? this.title,
      heads: heads ?? this.heads,
      num: num ?? this.num,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'heads': heads,
      'num': num,
    };
  }

  factory PassageRespose.fromMap(Map<String, dynamic> map) {
    return PassageRespose(
      title: map['title'] ?? '',
      heads: List<String>.from(map['heads']),
      num: map['num']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory PassageRespose.fromJson(String source) =>
      PassageRespose.fromMap(json.decode(source));

  @override
  String toString() =>
      'PassageRespose(title: $title, heads: $heads, num: $num)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PassageRespose &&
        other.title == title &&
        listEquals(other.heads, heads) &&
        other.num == num;
  }

  @override
  int get hashCode => title.hashCode ^ heads.hashCode ^ num.hashCode;
}
