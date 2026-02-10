import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenopay/models/budget_model.dart';

const String _keyBudget = 'zenopay_budget_state';

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
