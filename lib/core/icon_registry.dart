import "package:flutter/material.dart";

class IconRegistry {
  static const Map<String, IconData> icons = {
    "restaurant": Icons.restaurant,
    "local_cafe": Icons.local_cafe,
    "directions_bus": Icons.directions_bus,
    "shopping_cart": Icons.shopping_cart,
    "school": Icons.school,
    "phone_android": Icons.phone_android,
    "sports_esports": Icons.sports_esports,
    "movie": Icons.movie,
    "home": Icons.home,
    "medical_services": Icons.medical_services,
    "payments": Icons.payments,
    "attach_money": Icons.attach_money,
    "work": Icons.work,
    "savings": Icons.savings,
    "card": Icons.credit_card,
  };

  static IconData byKey(String? key) => icons[key] ?? Icons.category;

  static List<String> keys() => icons.keys.toList();
}
