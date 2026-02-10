import 'package:flutter/material.dart';
import 'package:zenopay/Components/CustomBottomNav.dart';
import 'package:zenopay/Components/FullPageLoader.dart';
import 'package:zenopay/core/config.dart';
import 'package:zenopay/models/budget_model.dart';
import 'package:zenopay/services/api_client.dart';
import 'package:zenopay/services/budget_service.dart';

/// Expense category options for budget (match names used in transactions).
const List<String> _expenseCategoryNames = [
  'Food',
  'Transport',
  'Bills',
  'Shopping',
  'Entertainment',
  'Health',
  'Education',
  'Rent',
  'Other',
];

class BudgetingPage extends StatefulWidget {
  const BudgetingPage({super.key});

  @override
  State<BudgetingPage> createState() => _BudgetingPageState();
}

class _BudgetingPageState extends State<BudgetingPage> {
  bool _loading = true;
  String? _error;
  BudgetState _budget = const BudgetState();
  List<Map<String, dynamic>> _transactions = [];
  Map<String, double> _spentByCategory = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dio = await ApiClient.instance(AppConfig.apiBaseUrl);
      final res = await dio.get('/transactions');
      final data = res.data;
      Map<String, dynamic> decoded;
      if (data is Map<String, dynamic>) {
        decoded = data;
      } else if (data is Map) {
        decoded = data.cast<String, dynamic>();
      } else {
        decoded = <String, dynamic>{};
      }
      final list = (decoded['transactions'] as List? ?? const <dynamic>[]);
      final mapped = list
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();

      final budget = await BudgetService.load();
      final spent = BudgetService.spentByCategoryThisMonth(mapped);

      if (!mounted) return;
      setState(() {
        _transactions = mapped;
        _budget = budget;
        _spentByCategory = spent;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _saveBudget(BudgetState newState) async {
    await BudgetService.save(newState);
    if (!mounted) return;
    setState(() => _budget = newState);
  }

  void _setIncome() async {
    final c = TextEditingController(
      text: _budget.monthlyIncome > 0 ? _budget.monthlyIncome.toStringAsFixed(0) : '',
    );
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Monthly income',
          style: TextStyle(color: Color(0xFF1E2A3B)),
        ),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: Color(0xFF1E2A3B), fontSize: 18),
          decoration: InputDecoration(
            hintText: 'e.g. 5000',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixText: 'Rs ',
            prefixStyle: const TextStyle(color: Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (_) => Navigator.pop(ctx, c.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4F6DFF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      final value = double.tryParse(result.trim()) ?? 0;
      if (value >= 0) await _saveBudget(_budget.copyWith(monthlyIncome: value));
    }
  }

  void _addCategoryBudget() async {
    final existingNames = _budget.categories.map((e) => e.categoryName).toSet();
    final choices = _expenseCategoryNames.where((n) => !existingNames.contains(n)).toList();
    if (choices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All categories already have a budget.')),
      );
      return;
    }

    String? selected = choices.first;
    final c = TextEditingController(text: '0');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialog) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Add category budget',
              style: TextStyle(color: Color(0xFF1E2A3B)),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Category', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selected,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Color(0xFF1E2A3B)),
                    items: choices.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                    onChanged: (v) {
                      if (v != null) setDialog(() => selected = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Monthly limit (Rs)', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: c,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Color(0xFF1E2A3B), fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'e.g. 2000',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F6DFF),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );

    if (ok == true && selected != null) {
      final limit = double.tryParse(c.text.trim()) ?? 0;
      if (limit >= 0) {
        final updated = _budget.categories.toList()
          ..add(BudgetCategory(categoryName: selected!, monthlyLimit: limit));
        await _saveBudget(_budget.copyWith(categories: updated));
      }
    }
  }

  void _editCategoryBudget(BudgetCategory cat) async {
    final c = TextEditingController(text: cat.monthlyLimit.toStringAsFixed(0));
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit ${cat.categoryName}', style: const TextStyle(color: Color(0xFF1E2A3B))),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Color(0xFF1E2A3B), fontSize: 18),
          decoration: InputDecoration(
            labelText: 'Monthly limit (Rs)',
            labelStyle: const TextStyle(color: Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) => Navigator.pop(ctx, c.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4F6DFF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      final limit = double.tryParse(result.trim()) ?? 0;
      if (limit >= 0) {
        final updated = _budget.categories.map((e) {
          if (e.categoryName == cat.categoryName) {
            return BudgetCategory(categoryName: e.categoryName, monthlyLimit: limit);
          }
          return e;
        }).toList();
        await _saveBudget(_budget.copyWith(categories: updated));
      }
    }
  }

  void _deleteCategoryBudget(BudgetCategory cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove budget?', style: TextStyle(color: Color(0xFF1E2A3B))),
        content: Text(
          'Remove budget for "${cat.categoryName}"?',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final updated = _budget.categories.where((e) => e.categoryName != cat.categoryName).toList();
      await _saveBudget(_budget.copyWith(categories: updated));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: FullPageLoader(accentColor: Color(0xFF4F6DFF)),
      );
    }

    final daysLeft = BudgetService.daysLeftInMonth;
    final totalBudget = _budget.categories.fold<double>(0, (s, c) => s + c.monthlyLimit);
    final totalSpent = _spentByCategory.values.fold<double>(0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFF4F6DFF),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    if (_error != null)
                      _buildError()
                    else ...[
                      _buildIncomeCard(),
                      const SizedBox(height: 20),
                      _buildOverviewCard(totalBudget, totalSpent, daysLeft),
                      const SizedBox(height: 24),
                      _buildCategoryBudgets(daysLeft),
                      const SizedBox(height: 24),
                      _buildDailyTip(daysLeft),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [const Color(0xFFF8FAFC).withValues(alpha: 0), const Color(0xFFF8FAFC)],
                ),
              ),
              child: CustomBottomNav(currentIndex: 3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 8)),
            ],
          ),
          child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF4F6DFF), size: 28),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Budgeting',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2A3B),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Track spending & stay on target',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 8))],
        border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Something went wrong',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeCard() {
    return GestureDetector(
      onTap: _setIncome,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.trending_up_rounded, color: Color(0xFF4F6DFF), size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly income',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _budget.monthlyIncome > 0
                        ? 'Rs ${_budget.monthlyIncome.toStringAsFixed(0)}'
                        : 'Tap to set',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _budget.monthlyIncome > 0 ? const Color(0xFF1E2A3B) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_rounded, color: Color(0xFF64748B), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(double totalBudget, double totalSpent, int daysLeft) {
    final left = totalBudget - totalSpent;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'This month',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$daysLeft days left',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF1E2A3B), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _overviewChip('Budget', totalBudget, const Color(0xFF34D399)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _overviewChip('Spent', totalSpent, const Color(0xFFF59E0B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _overviewChip('Left', left < 0 ? 0 : left, left >= 0 ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewChip(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Rs ${value.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E2A3B)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBudgets(int daysLeft) {
    if (_budget.categories.isEmpty) {
      return GestureDetector(
        onTap: _addCategoryBudget,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 8))],
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Icon(Icons.add_chart_rounded, size: 44, color: const Color(0xFF64748B).withValues(alpha: 0.8)),
              const SizedBox(height: 12),
              const Text(
                'Add a category budget',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              const Text(
                'e.g. Food Rs 2000/month',
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Category budgets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E2A3B),
              ),
            ),
            TextButton.icon(
              onPressed: _addCategoryBudget,
              icon: const Icon(Icons.add_rounded, size: 20, color: Color(0xFF4F6DFF)),
              label: const Text('Add', style: TextStyle(color: Color(0xFF4F6DFF), fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._budget.categories.map((cat) => _buildCategoryCard(cat, daysLeft)),
      ],
    );
  }

  Widget _buildCategoryCard(BudgetCategory cat, int daysLeft) {
    final spent = _spentByCategory[cat.categoryName] ?? 0;
    final left = cat.monthlyLimit - spent;
    final daily = daysLeft > 0 ? (left > 0 ? left / daysLeft : 0.0) : 0.0;
    final progress = cat.monthlyLimit > 0 ? (spent / cat.monthlyLimit).clamp(0.0, 1.0) : 0.0;
    final isOver = spent >= cat.monthlyLimit;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 8))],
        border: Border.all(
          color: isOver ? Colors.red.withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFF2F4FF),
                child: Icon(
                  _iconForCategory(cat.categoryName),
                  color: const Color(0xFF4F6DFF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.categoryName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2A3B),
                      ),
                    ),
                    Text(
                      'Rs ${spent.toStringAsFixed(0)} / Rs ${cat.monthlyLimit.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOver ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                color: Colors.white,
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Color(0xFF1E2A3B)))),
                  const PopupMenuItem(value: 'delete', child: Text('Remove', style: TextStyle(color: Color(0xFFEF4444)))),
                ],
                onSelected: (v) {
                  if (v == 'edit') _editCategoryBudget(cat);
                  if (v == 'delete') _deleteCategoryBudget(cat);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver ? const Color(0xFFEF4444) : const Color(0xFF4F6DFF),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Left: Rs ${left > 0 ? left.toStringAsFixed(0) : "0"}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: left >= 0 ? const Color(0xFF00C27A) : const Color(0xFFEF4444),
                ),
              ),
              Text(
                daysLeft > 0 ? 'Rs ${daily.toStringAsFixed(0)}/day to stay on track' : 'Month ended',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconForCategory(String name) {
    const map = {
      'Food': Icons.fastfood_rounded,
      'Transport': Icons.directions_bus_rounded,
      'Bills': Icons.receipt_long_rounded,
      'Shopping': Icons.shopping_bag_rounded,
      'Entertainment': Icons.theaters_rounded,
      'Health': Icons.medical_services_rounded,
      'Education': Icons.school_rounded,
      'Rent': Icons.home_rounded,
      'Other': Icons.category_rounded,
    };
    return map[name] ?? Icons.category_rounded;
  }

  Widget _buildDailyTip(int daysLeft) {
    final totalBudget = _budget.categories.fold<double>(0, (s, c) => s + c.monthlyLimit);
    final totalSpent = _spentByCategory.values.fold<double>(0, (a, b) => a + b);
    final left = totalBudget - totalSpent;
    final daily = daysLeft > 0 && left > 0 ? left / daysLeft : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 8))],
        border: Border.all(color: const Color(0xFF4F6DFF).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.lightbulb_rounded, color: Color(0xFF4F6DFF), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily budget tip',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E2A3B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  daysLeft > 0 && left > 0
                      ? 'You have Rs ${left.toStringAsFixed(0)} left this month. That\'s about Rs ${daily.toStringAsFixed(0)} per day to stay on budget.'
                      : left <= 0
                          ? 'You\'ve used your budget for this month. Try to avoid extra spending until next month.'
                          : 'Set your income and category budgets to see your daily allowance.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
