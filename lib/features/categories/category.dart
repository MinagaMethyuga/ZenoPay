import "dart:convert";
import "package:flutter/material.dart";

class CategoryItem {
  final String name;
  final String iconKey;
  final int colorValue;

  const CategoryItem({
    required this.name,
    required this.iconKey,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
    "name": name,
    "iconKey": iconKey,
    "colorValue": colorValue,
  };

  factory CategoryItem.fromJson(Map<String, dynamic> j) => CategoryItem(
    name: (j["name"] ?? "").toString(),
    iconKey: (j["iconKey"] ?? "").toString(),
    colorValue: (j["colorValue"] as num).toInt(),
  );

  static String encodeList(List<CategoryItem> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<CategoryItem> decodeList(String raw) {
    final arr = jsonDecode(raw) as List<dynamic>;
    return arr
        .map((e) => CategoryItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}
