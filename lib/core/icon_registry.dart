import "package:flutter/material.dart";

class IconRegistry {
  static const Map<String, IconData> icons = {
    // ---- Keys used by AddTransactionPage (mi:*) + also support without prefix ----
    "mi:fastfood": Icons.fastfood,
    "fastfood": Icons.fastfood,

    "mi:restaurant": Icons.restaurant,
    "restaurant": Icons.restaurant,

    "mi:coffee": Icons.coffee,
    "coffee": Icons.coffee,

    "mi:local_pizza": Icons.local_pizza,
    "local_pizza": Icons.local_pizza,

    "mi:icecream": Icons.icecream,
    "icecream": Icons.icecream,

    "mi:local_bar": Icons.local_bar,
    "local_bar": Icons.local_bar,

    "mi:bakery_dining": Icons.bakery_dining,
    "bakery_dining": Icons.bakery_dining,

    "mi:shopping_basket": Icons.shopping_basket,
    "shopping_basket": Icons.shopping_basket,

    "mi:directions_bus": Icons.directions_bus,
    "directions_bus": Icons.directions_bus,

    "mi:directions_car": Icons.directions_car,
    "directions_car": Icons.directions_car,

    "mi:two_wheeler": Icons.two_wheeler,
    "two_wheeler": Icons.two_wheeler,

    "mi:train": Icons.train,
    "train": Icons.train,

    "mi:local_taxi": Icons.local_taxi,
    "local_taxi": Icons.local_taxi,

    "mi:flight": Icons.flight,
    "flight": Icons.flight,

    "mi:pedal_bike": Icons.pedal_bike,
    "pedal_bike": Icons.pedal_bike,

    "mi:local_gas_station": Icons.local_gas_station,
    "local_gas_station": Icons.local_gas_station,

    "mi:receipt_long": Icons.receipt_long,
    "receipt_long": Icons.receipt_long,

    "mi:bolt": Icons.bolt,
    "bolt": Icons.bolt,

    "mi:water_drop": Icons.water_drop,
    "water_drop": Icons.water_drop,

    "mi:wifi": Icons.wifi,
    "wifi": Icons.wifi,

    "mi:phone_iphone": Icons.phone_iphone,
    "phone_iphone": Icons.phone_iphone,

    "mi:subscriptions": Icons.subscriptions,
    "subscriptions": Icons.subscriptions,

    "mi:credit_card": Icons.credit_card,
    "credit_card": Icons.credit_card,
    "card": Icons.credit_card, // your old key

    "mi:account_balance": Icons.account_balance,
    "account_balance": Icons.account_balance,

    "mi:home": Icons.home,
    "home": Icons.home,

    "mi:cleaning_services": Icons.cleaning_services,
    "cleaning_services": Icons.cleaning_services,

    "mi:chair": Icons.chair,
    "chair": Icons.chair,

    "mi:kitchen": Icons.kitchen,
    "kitchen": Icons.kitchen,

    "mi:construction": Icons.construction,
    "construction": Icons.construction,

    "mi:local_laundry_service": Icons.local_laundry_service,
    "local_laundry_service": Icons.local_laundry_service,

    "mi:shopping_cart": Icons.shopping_cart,
    "shopping_cart": Icons.shopping_cart,

    "mi:shopping_bag": Icons.shopping_bag,
    "shopping_bag": Icons.shopping_bag,

    "mi:storefront": Icons.storefront,
    "storefront": Icons.storefront,

    "mi:local_mall": Icons.local_mall,
    "local_mall": Icons.local_mall,

    "mi:loyalty": Icons.loyalty,
    "loyalty": Icons.loyalty,

    "mi:inventory_2": Icons.inventory_2,
    "inventory_2": Icons.inventory_2,

    "mi:theaters": Icons.theaters,
    "theaters": Icons.theaters,

    "mi:music_note": Icons.music_note,
    "music_note": Icons.music_note,

    "mi:sports_esports": Icons.sports_esports,
    "sports_esports": Icons.sports_esports,

    "mi:headphones": Icons.headphones,
    "headphones": Icons.headphones,

    "mi:celebration": Icons.celebration,
    "celebration": Icons.celebration,

    "mi:medical_services": Icons.medical_services,
    "medical_services": Icons.medical_services,

    "mi:local_hospital": Icons.local_hospital,
    "local_hospital": Icons.local_hospital,

    "mi:medication": Icons.medication,
    "medication": Icons.medication,

    "mi:spa": Icons.spa,
    "spa": Icons.spa,

    "mi:fitness_center": Icons.fitness_center,
    "fitness_center": Icons.fitness_center,

    "mi:directions_run": Icons.directions_run,
    "directions_run": Icons.directions_run,

    "mi:sports_soccer": Icons.sports_soccer,
    "sports_soccer": Icons.sports_soccer,

    "mi:sports_basketball": Icons.sports_basketball,
    "sports_basketball": Icons.sports_basketball,

    "mi:sports_tennis": Icons.sports_tennis,
    "sports_tennis": Icons.sports_tennis,

    "mi:sports_mma": Icons.sports_mma,
    "sports_mma": Icons.sports_mma,

    "mi:person": Icons.person,
    "person": Icons.person,

    "mi:group": Icons.group,
    "group": Icons.group,

    "mi:favorite": Icons.favorite,
    "favorite": Icons.favorite,

    "mi:gift": Icons.card_giftcard,
    "gift": Icons.card_giftcard,

    "mi:attach_money": Icons.attach_money,
    "attach_money": Icons.attach_money,

    "mi:payments": Icons.payments,
    "payments": Icons.payments,

    "mi:work": Icons.work,
    "work": Icons.work,

    "mi:savings": Icons.savings,
    "savings": Icons.savings,

    // Default
    "mi:category": Icons.category,
    "category": Icons.category,
  };

  static String _normalize(String? key) {
    if (key == null) return "";
    var k = key.trim();
    if (k.isEmpty) return "";
    // allow accidental formats
    k = k.replaceAll("Icons.", "");
    // do NOT force lower-case because your keys already match exactly.
    return k;
  }

  static IconData byKey(String? key) {
    final k = _normalize(key);
    if (k.isEmpty) return Icons.category;

    // direct match (mi:wifi)
    final direct = icons[k];
    if (direct != null) return direct;

    // fallback: try without prefix if it comes like mi:wifi
    if (k.startsWith("mi:")) {
      final noPrefix = k.substring(3);
      return icons[noPrefix] ?? Icons.category;
    }

    return Icons.category;
  }

  static List<String> keys() => icons.keys.toList();
}