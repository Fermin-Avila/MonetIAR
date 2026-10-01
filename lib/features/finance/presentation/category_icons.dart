// lib/features/finance/presentation/category_icons.dart
import 'package:flutter/material.dart';

IconData categoryIcon(String key) => switch (key) {
      'home' => Icons.home_rounded,
      'receipt' => Icons.receipt_long_rounded,
      'restaurant' => Icons.restaurant_rounded,
      'health' => Icons.favorite_rounded,
      'car' => Icons.directions_car_rounded,
      'leisure' => Icons.celebration_rounded,
      'subs' => Icons.subscriptions_rounded,
      'person' => Icons.person_rounded,
      'card' => Icons.credit_card_rounded,
      'income' => Icons.south_west_rounded,
      _ => Icons.category_rounded,
    };