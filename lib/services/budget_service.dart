import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenopay/models/budget_model.dart';

const String _keyBudget = 'zenopay_budget_state';

/// Maps each budget category name to transaction category names that count toward it.
/// When user selects "Food & Drinks" then "Coffee", the transaction category is "Coffee"
/// but it should count under a "Food" budget. This set includes main name + all subcategory labels.
const Map<String, Set<String>> _budgetCategoryToTransactionNames = {
  'Food': {
    'Food',
    'Food & Drinks',
    'Fastfood',
    'Restaurant',
    'Coffee',
    'Pizza',
    'Ice Cream',
    'Bar',
    'Bakery',
    'Groceries',
  },
  'Transport': {
    'Transport',
    'Bus',
    'Car',
    'Motorbike',
    'Train',
    'Taxi',
    'Flight',
    'Bicycle',
    'Fuel',
  },
  'Bills': {
    'Bills',
    'Bills & Utilities',
    'Bill',
    'Electricity',
    'Water',
    'WiFi',
    'Mobile',
    'Subscriptions',
    'Card',
    'Bank',
  },
  'Shopping': {
    'Shopping',
    'Cart',
    'Bag',
    'Store',
    'Mall',
    'Tag',
    'Package',
  },
  'Entertainment': {
    'Entertainment',
    'Movies',
    'Music',
    'Gaming',
    'Headphones',
    'Celebration',
  },
  'Health': {
    'Health',
    'Medical',
    'Hospital',
    'Medication',
    'Wellness',
    'Gym',
    'Run',
    'Soccer',
    'Basketball',
    'Tennis',
    'Fitness & Sports',
  },
  'Education': {
    'Education',
    'School',
    'Book',
    'Notes',
    'Calculator',
    'Laptop',
  },
  'Rent': {
    'Rent',
    'Home',
    'Cleaning',
    'Furniture',
    'Kitchen',
    'Repair',
    'Laundry',
  },
  'Other': {
    'Other',
    'Category',
    'More',
    'Nature',
    'Attachment',
    'Misc',
    'Donation',
    'Gift',
    'Giftcard',
    'Award',
    'Family',
    'Child',
    'Pets',
    'Love',
    'Devices',
    'Android',
    'Router',
    'Memory',
    'Salon',
    'Brush',
    'Skincare',
    'Luggage',
    'Place',
    'Beach',
    'Hotel',
    'Map',
    'Salary',
    'Work',
    'Profit',
    'Wallet',
    'Money',
    'Freelance',
    'Allowance',
  },
  // Aliases so "Food & Drinks" / "Bills & Utilities" etc. also roll up subcategories
  'Food & Drinks': {
    'Food',
    'Food & Drinks',
    'Fastfood',
    'Restaurant',
    'Coffee',
    'Pizza',
    'Ice Cream',
    'Bar',
    'Bakery',
    'Groceries',
  },
  'Bills & Utilities': {
    'Bills',
    'Bills & Utilities',
    'Bill',
    'Electricity',
    'Water',
    'WiFi',
    'Mobile',
    'Subscriptions',
    'Card',
    'Bank',
  },
  'Home': {
    'Rent',
    'Home',
    'Cleaning',
    'Furniture',
    'Kitchen',
    'Repair',
    'Laundry',
  },
  'Fitness & Sports': {
    'Gym',
    'Run',
    'Soccer',
    'Basketball',
    'Tennis',
    'Fitness & Sports',
  },
};

class BudgetService {
  static Future<BudgetState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyBudget);
    if (raw == null || raw.isEmpty) return const BudgetState();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return BudgetState.fromJson(j);
    } catch (_) {
      return const BudgetState();
    }
  }

  static Future<void> save(BudgetState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBudget, jsonEncode(state.toJson()));
  }

  /// Sum expense amount per category for the current month from transactions.
  /// Transactions: list of maps with "type", "category", "amount", "occurred_at".
  static Map<String, double> spentByCategoryThisMonth(
    List<Map<String, dynamic>> transactions,
  ) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final Map<String, double> spent = {};
    for (final t in transactions) {
      if ((t['type'] ?? '').toString() != 'expense') continue;
      final cat = (t['category'] ?? 'Other').toString().trim();
      if (cat.isEmpty) continue;

      final occurred = t['occurred_at']?.toString();
      if (occurred != null && occurred.isNotEmpty) {
        final dt = DateTime.tryParse(occurred);
        if (dt != null && (dt.isBefore(startOfMonth) || dt.isAfter(endOfMonth))) {
          continue;
        }
      }

      final amount = double.tryParse(t['amount']?.toString() ?? '') ?? 0;
      spent[cat] = (spent[cat] ?? 0) + amount;
    }
    return spent;
  }

  /// Total spent for a budget category this month, including all subcategories.
  /// E.g. budget "Food" includes transactions categorized as Food, Coffee, Restaurant, etc.
  static double spentForBudgetCategory(
    Map<String, double> spentByCategory,
    String budgetCategoryName,
  ) {
    final names = _budgetCategoryToTransactionNames[budgetCategoryName];
    if (names == null) {
      return spentByCategory[budgetCategoryName] ?? 0;
    }
    double total = 0;
    for (final name in names) {
      total += spentByCategory[name] ?? 0;
    }
    return total;
  }

  /// Days left in current month (at least 1).
  static int get daysLeftInMonth {
    final now = DateTime.now();
    final last = DateTime(now.year, now.month + 1, 0);
    final diff = last.difference(now).inDays;
    return diff < 0 ? 0 : (diff + 1);
  }

  /// Days elapsed in current month (including today).
  static int get daysElapsedInMonth {
    final now = DateTime.now();
    return now.day;
  }
}
