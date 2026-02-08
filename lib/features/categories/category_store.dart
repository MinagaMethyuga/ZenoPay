import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";
import "category.dart";

class CategoryStore {
  static const _kExpense = "custom_categories_expense";
  static const _kIncome = "custom_categories_income";

  // Defaults MUST appear even with no custom categories
  static final List<CategoryItem> defaultExpense = [
    CategoryItem(name: "Food", iconKey: "restaurant", colorValue: const Color(0xFF16A34A).value),
    CategoryItem(name: "Transport", iconKey: "directions_bus", colorValue: const Color(0xFF2563EB).value),
    CategoryItem(name: "Shopping", iconKey: "shopping_cart", colorValue: const Color(0xFF7C3AED).value),
    CategoryItem(name: "Bills", iconKey: "payments", colorValue: const Color(0xFFF59E0B).value),
    CategoryItem(name: "Health", iconKey: "medical_services", colorValue: const Color(0xFFEF4444).value),
    CategoryItem(name: "Education", iconKey: "school", colorValue: const Color(0xFF0EA5E9).value),
    CategoryItem(name: "Entertainment", iconKey: "movie", colorValue: const Color(0xFFEC4899).value),
  ];

  static final List<CategoryItem> defaultIncome = [
    CategoryItem(name: "Allowance", iconKey: "attach_money", colorValue: const Color(0xFF16A34A).value),
    CategoryItem(name: "Salary", iconKey: "work", colorValue: const Color(0xFF2563EB).value),
    CategoryItem(name: "Gift", iconKey: "payments", colorValue: const Color(0xFF7C3AED).value),
    CategoryItem(name: "Savings", iconKey: "savings", colorValue: const Color(0xFFF59E0B).value),
  ];

  static Future<List<CategoryItem>> load({required bool isIncome}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = isIncome ? _kIncome : _kExpense;

    final raw = prefs.getString(key);
    final custom = raw == null ? <CategoryItem>[] : CategoryItem.decodeList(raw);

    final base = isIncome ? defaultIncome : defaultExpense;

    // Merge: defaults + custom (custom at end)
    return [...base, ...custom];
  }

  static Future<void> addCustom({required bool isIncome, required CategoryItem item}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = isIncome ? _kIncome : _kExpense;

    final raw = prefs.getString(key);
    final custom = raw == null ? <CategoryItem>[] : CategoryItem.decodeList(raw);

    final exists = custom.any((c) => c.name.toLowerCase() == item.name.toLowerCase());
    if (!exists) {
      custom.add(item);
      await prefs.setString(key, CategoryItem.encodeList(custom));
    }
  }
}
