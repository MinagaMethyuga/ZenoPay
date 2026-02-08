import "dart:convert";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;

import "package:zenopay/Components/CustomBottomNav.dart";
import "package:zenopay/Components/add_transaction_page.dart";

// If you created these (recommended):
// lib/core/config.dart
// lib/core/icon_registry.dart
import "package:zenopay/core/config.dart" hide AppConfig;
import "package:zenopay/core/icon_registry.dart" hide IconRegistry;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  // TEMP until auth comes: use your logged user id later
  final int userId = 1;

  bool loading = true;
  String? error;

  List<Map<String, dynamic>> transactions = [];

  // banner animation (optional)
  bool showBanner = true;
  late AnimationController _bannerController;
  late Animation<double> _bannerAnim;

  @override
  void initState() {
    super.initState();

    _bannerController = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
      value: 1.0,
    );
    _bannerAnim = CurvedAnimation(parent: _bannerController, curve: Curves.easeInOut);

    _load();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final uri = Uri.parse("${AppConfig.apiBaseUrl}/transactions")
          .replace(queryParameters: {"user_id": userId.toString()});

      final res = await http.get(uri, headers: const {"Accept": "application/json"});
      final decoded = jsonDecode(res.body);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw decoded;
      }

      final list = (decoded["transactions"] as List).cast<dynamic>();
      final mapped = list.map((e) => (e as Map).cast<String, dynamic>()).toList();

      setState(() {
        transactions = mapped;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _closeBanner() {
    _bannerController.reverse().then((_) {
      if (!mounted) return;
      setState(() => showBanner = false);
    });
  }

  // ======= Helpers: totals =======
  double get totalIncome {
    double sum = 0;
    for (final t in transactions) {
      if ((t["type"] ?? "") == "income") {
        sum += double.tryParse(t["amount"].toString()) ?? 0;
      }
    }
    return sum;
  }

  double get totalExpense {
    double sum = 0;
    for (final t in transactions) {
      if ((t["type"] ?? "") == "expense") {
        sum += double.tryParse(t["amount"].toString()) ?? 0;
      }
    }
    return sum;
  }

  double get balance => totalIncome - totalExpense;

  String _money(double v) => v.toStringAsFixed(2);

  // ======= UI =======
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // background gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 380,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFE0E7FF).withOpacity(0.6),
                    const Color(0xFFF5F3FF).withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  _header(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),

                        if (showBanner) _successBanner(),
                        if (showBanner) const SizedBox(height: 16),

                        _summaryCards(),
                        const SizedBox(height: 14),

                        _frequentShortcuts(),
                        const SizedBox(height: 16),

                        _quickActions(),
                        const SizedBox(height: 16),

                        _recentTransactions(),
                        const SizedBox(height: 18),

                        _activeQuestsMock(), // keep for now (later connect challenges API)
                        const SizedBox(height: 18),

                        _badgeCaseMock(),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: CustomBottomNav(currentIndex: 0),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.25)),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF8B5CF6), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.25),
                  blurRadius: 16,
                ),
              ],
              image: const DecorationImage(
                image: AssetImage("assets/avatar.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Hi, Minaga 👋",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      height: 10,
                      width: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.6,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "LVL 5",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6366F1),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Streak pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
            ),
            child: const Row(
              children: [
                Icon(Icons.local_fire_department, color: Color(0xFFF97316), size: 18),
                SizedBox(width: 6),
                Text(
                  "12",
                  style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _successBanner() {
    return SizeTransition(
      sizeFactor: _bannerAnim,
      child: FadeTransition(
        opacity: _bannerAnim,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFECFDF5), Color(0xFFCCFBF1)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD1FAE5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFD1FAE5)),
                ),
                child: const Icon(Icons.celebration, color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Nice! Keep logging 🔥",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Your streak is building",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _closeBanner,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(Icons.close, size: 16, color: Color(0xFF10B981)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCards() {
    final income = totalIncome;
    final expense = totalExpense;
    final bal = balance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF334155)),
            ),
            const Spacer(),
            if (loading)
              const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            if (!loading)
              Text(
                "Tap to refresh",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w700),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (error != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    error!,
                    style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                TextButton(onPressed: _load, child: const Text("Retry")),
              ],
            ),
          ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _statCard(
                title: "Income",
                value: _money(income),
                icon: Icons.arrow_downward_rounded,
                color: const Color(0xFF10B981),
                bg: const Color(0xFFECFDF5),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                title: "Expense",
                value: _money(expense),
                icon: Icons.arrow_upward_rounded,
                color: const Color(0xFFEF4444),
                bg: const Color(0xFFFEF2F2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                title: "Balance",
                value: _money(bal),
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF6366F1),
                bg: const Color(0xFFEEF2FF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            "Rs $value",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }


  Widget _frequentShortcuts() {
    // These are the “frequent transaction types” shortcut buttons on Home.
    // Tap -> opens AddTransactionPage with category pre-selected.
    final shortcuts = <Map<String, dynamic>>[
      {"name": "Food", "iconKey": "mi:fastfood", "color": const Color(0xFF10B981)},
      {"name": "Transport", "iconKey": "mi:directions_bus", "color": const Color(0xFF3B82F6)},
      {"name": "Bills", "iconKey": "mi:receipt_long", "color": const Color(0xFFF59E0B)},
      {"name": "Shopping", "iconKey": "mi:shopping_bag", "color": const Color(0xFF8B5CF6)},
      {"name": "Health", "iconKey": "mi:medical_services", "color": const Color(0xFFEF4444)},
      {"name": "Entertainment", "iconKey": "mi:theaters", "color": const Color(0xFFEC4899)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick shortcuts",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: shortcuts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final s = shortcuts[i];
              final Color c = s["color"] as Color;
              final String name = s["name"] as String;
              final String iconKey = s["iconKey"] as String;

              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  final changed = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddTransactionPage(
                        type: "expense",
                        userId: userId,
                        presetCategoryName: name,
                        presetCategoryIconKey: iconKey,
                        presetCategoryColorValue: c.value,
                        presetCategoryType: CategoryType.expense,
                      ),
                    ),
                  );
                  if (changed == true) _load();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: c.withOpacity(0.16),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          // If you use your own IconRegistry in core/, ensure it has byKey().
                          IconRegistry.byKey(iconKey),
                          color: c,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _quickActions() {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            title: "Add Expense",
            icon: Icons.remove_circle_outline,
            colors: const [Color(0xFFEF4444), Color(0xFFF97316)],
            onTap: () async {
              final changed = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTransactionPage()),
              );
              if (changed == true) _load();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionCard(
            title: "Add Income",
            icon: Icons.add_circle_outline,
            colors: const [Color(0xFF10B981), Color(0xFF22C55E)],
            onTap: () async {
              final changed = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddTransactionPage()),
              );
              if (changed == true) _load();
            },
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required String title,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: colors.first.withOpacity(0.25), blurRadius: 18)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentTransactions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Color(0xFF6366F1)),
              const SizedBox(width: 8),
              const Text(
                "Recent transactions",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF334155)),
              ),
              const Spacer(),
              TextButton(
                onPressed: _load,
                child: const Text("Refresh"),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (transactions.isEmpty)
            _emptyTransactions()
          else
            Column(
              children: transactions.take(8).map((t) => _txnTile(t)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _emptyTransactions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF64748B)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "No transactions yet. Add your first one!",
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _txnTile(Map<String, dynamic> t) {
    final type = (t["type"] ?? "").toString();
    final isIncome = type == "income";

    final amount = double.tryParse(t["amount"].toString()) ?? 0;
    final category = (t["category"] ?? "Other").toString();
    final iconKey = (t["icon_key"] ?? "").toString();
    final note = (t["note"] ?? "").toString();

    final color = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final bg = color.withOpacity(0.10);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(IconRegistry.byKey(iconKey), color: color),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF334155)),
                ),
                if (note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),
          Text(
            "${isIncome ? "+" : "-"}Rs ${_money(amount)}",
            style: TextStyle(fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  // ======= Mock sections (keep your gamified feel) =======
  Widget _activeQuestsMock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.explore, color: Color(0xFF8B5CF6), size: 20),
            SizedBox(width: 8),
            Text(
              "Active Quests",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF334155)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _questCard(
          title: "Coffee Saver",
          subtitle: "Skip coffee for 3 days",
          progress: 0.33,
          xp: "+500 XP",
          icon: Icons.local_cafe,
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(height: 10),
        _questCard(
          title: "Categorize It",
          subtitle: "Tag last 5 items",
          progress: 0.8,
          xp: "+200 XP",
          icon: Icons.category,
          color: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  Widget _questCard({
    required String title,
    required String subtitle,
    required double progress,
    required String xp,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF334155))),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(999)),
                child: Text(xp, style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: progress, minHeight: 10),
          ),
        ],
      ),
    );
  }

  Widget _badgeCaseMock() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.workspace_premium, color: Color(0xFFF59E0B)),
              SizedBox(width: 8),
              Text(
                "Badge Case",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF334155)),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "You’ll unlock badges as you log transactions and complete challenges.",
            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
