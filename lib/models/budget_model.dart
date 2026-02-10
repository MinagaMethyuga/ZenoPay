/// Single category budget: e.g. "Food" with limit 2000 per month.
class BudgetCategory {
  final String categoryName;
  final double monthlyLimit;

  const BudgetCategory({
    required this.categoryName,
    required this.monthlyLimit,
  });

  Map<String, dynamic> toJson() => {
        'categoryName': categoryName,
        'monthlyLimit': monthlyLimit,
      };

  factory BudgetCategory.fromJson(Map<String, dynamic> j) => BudgetCategory(
        categoryName: (j['categoryName'] ?? '').toString(),
        monthlyLimit: (j['monthlyLimit'] is num)
            ? (j['monthlyLimit'] as num).toDouble()
            : double.tryParse(j['monthlyLimit']?.toString() ?? '') ?? 0,
      );
}

/// Full budget state: monthly income + list of category budgets.
class BudgetState {
  final double monthlyIncome;
  final List<BudgetCategory> categories;

  const BudgetState({
    this.monthlyIncome = 0,
    this.categories = const [],
  });

  BudgetState copyWith({
    double? monthlyIncome,
    List<BudgetCategory>? categories,
  }) =>
      BudgetState(
        monthlyIncome: monthlyIncome ?? this.monthlyIncome,
        categories: categories ?? this.categories,
      );

  Map<String, dynamic> toJson() => {
        'monthlyIncome': monthlyIncome,
        'categories': categories.map((e) => e.toJson()).toList(),
      };

  factory BudgetState.fromJson(Map<String, dynamic> j) {
    final raw = j['categories'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => BudgetCategory.fromJson(e.cast<String, dynamic>()))
            .toList()
        : <BudgetCategory>[];
    return BudgetState(
      monthlyIncome: (j['monthlyIncome'] is num)
          ? (j['monthlyIncome'] as num).toDouble()
          : double.tryParse(j['monthlyIncome']?.toString() ?? '') ?? 0,
      categories: list,
    );
  }
}
