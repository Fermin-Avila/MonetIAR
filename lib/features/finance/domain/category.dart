// lib/features/finance/domain/category.dart
import 'package:flutter/foundation.dart';

@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
  });

  final String id;
  final String name;
  final String iconKey;
  final int colorValue; // ARGB

  Category copyWith({String? name, String? iconKey, int? colorValue}) => Category(
        id: id,
        name: name ?? this.name,
        iconKey: iconKey ?? this.iconKey,
        colorValue: colorValue ?? this.colorValue,
      );

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String,
        name: j['name'] as String,
        iconKey: j['icon_key'] as String,
        colorValue: j['color_value'] as int,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'icon_key': iconKey, 'color_value': colorValue};
}