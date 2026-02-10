import "package:flutter/material.dart";

import "package:zenopay/Components/CustomBottomNav.dart";
import "package:zenopay/theme/zenopay_colors.dart";
import "package:zenopay/Components/FullPageLoader.dart";
import "package:zenopay/Components/add_transaction_page.dart" hide IconRegistry;

import "package:zenopay/core/config.dart";
import "package:zenopay/core/icon_registry.dart";
import "package:zenopay/models/user_model.dart";
import "package:zenopay/services/api_client.dart";
import "package:zenopay/services/auth_api.dart";
import "package:zenopay/state/current_user.dart";
import "package:zenopay/services/budget_service.dart";
import "package:zenopay/services/budget_notification_service.dart";

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  bool loading = true;
  String? error;

  // Fetched from /auth/me
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _wallets = [];
  ZenoUser? _meUser;

  // Last N transactions
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

    _bannerAnim = CurvedAnimation(
      parent: _bannerController,
      curve: Curves.easeOutCubic,
    );

    _load();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });

    try {
      // 1) Fetch current user + profile + wallets using session cookie
      final auth = AuthApi();
      final me = await auth.me();

      // Safely parse user map
      final dynamic rawUser = me["user"];
      Map<String, dynamic> user;
      if (rawUser is Map<String, dynamic>) {
        user = rawUser;
      } else if (rawUser is Map) {
        user = rawUser.cast<String, dynamic>();
      } else {
        user = <String, dynamic>{};
      }

      if (user.isEmpty) {
        throw Exception("Not authenticated. Please log in again.");
      }

      final parsedUser = ZenoUser.fromJson(user);
      CurrentUser.set(parsedUser);

      // profile
      final dynamic rawProfile = user["profile"];
      final profile = (rawProfile is Map<String, dynamic>)
          ? rawProfile
          : (rawProfile is Map)
          ? rawProfile.cast<String, dynamic>()
          : <String, dynamic>{};

      // wallets
      final dynamic rawWallets = user["wallets"];
      final wallets = (rawWallets is List ? rawWallets : const <dynamic>[])
          .whereType<Map>()
          .map((w) => w.cast<String, dynamic>())
          .toList(growable: false);

      // 2) ✅ Fetch transactions for the logged-in user (Dio sends cookies)
      // IMPORTANT: do NOT send user_id from client. Backend must use session user.
      final dio = await ApiClient.instance(AppConfig.apiBaseUrl);
      final res = await dio.get("/transactions");

      final data = res.data;
      Map<String, dynamic> decoded;
      if (data is Map<String, dynamic>) {
        decoded = data;
      } else if (data is Map) {
        decoded = data.cast<String, dynamic>();
      } else {
        decoded = <String, dynamic>{};
      }

      final list = (decoded["transactions"] as List? ?? const <dynamic>[]);
      final mapped =
      list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();

      if (!mounted) return;
      setState(() {
        _user = user;
        _profile = profile;
        _wallets = wallets;
        transactions = mapped;
        _meUser = parsedUser;
      });

      // Check budgets and send notifications if needed
      try {
        final budget = await BudgetService.load();
        await BudgetNotificationService.checkBudgetsAndNotify(budget, mapped);
      } catch (_) {
        // Silently fail - notification check shouldn't block app loading
      }
    } catch (e) {
      if (!mounted) return;
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

  // ======= Derived user/profile helpers =======
  String get _displayName {
    final name = _user?["name"] as String?;
    if (name == null || name.trim().isEmpty) return "Student";
    return name;
  }

  int get _level => _asInt(_profile?["level"], 1);

  String get _levelLabel {
    final lvl = _meUser?.levelName.trim();
    if (lvl == null || lvl.isEmpty) return "Beginner";
    return lvl;
  }

  String get _displayXp {
    final xp = _meUser?.totalXp ?? 0;
    final s = xp.toString();
    if (s.length <= 3) return s;
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  double _walletBalanceByType(String type) {
    for (final w in _wallets) {
      if (w["type"] == type) {
        final raw = w["balance"];
        if (raw is num) return raw.toDouble();
        return double.tryParse(raw?.toString() ?? "") ?? 0;
      }
    }
    return 0;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ======= UI =======
  @override
  Widget build(BuildContext context) {
    final c = ZenoPayColors.of(context);
    final income = totalIncome;
    final expense = totalExpense;
    final bal = balance;

    if (loading) {
      return Scaffold(
        backgroundColor: c.surface,
        body: const FullPageLoader(accentColor: Color(0xFF4F6DFF)),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              c.surfaceGradientStart,
              c.surface,
              c.surfaceGradientEnd,
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: Stack(
        children: [
          // ✅ FIX: Stack needs a bounded child -> Positioned.fill
          Positioned.fill(
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ====== HEADER ======
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF7C4DFF),
                                    const Color(0xFFB388FF),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.person,
                                  color: Colors.white, size: 24), // gradient avatar
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Hi, $_displayName 👋",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(999),
                                          child: LinearProgressIndicator(
                                            value: 0.5,
                                            minHeight: 8,
                                            backgroundColor: c.progressBg,
                                            color: c.accent,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "LVL $_levelLabel",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: c.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: c.accentMuted,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: c.accent.withValues(alpha: 0.2)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: c.shadow.withValues(alpha: 0.08),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star_rounded,
                                          color: c.accent, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        "$_displayXp XP",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: c.textPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ValueListenableBuilder<ZenoUser?>(
                                  valueListenable: CurrentUser.notifier,
                                  builder: (context, user, _) {
                                    final streak = user?.profile?.currentStreak ??
                                        _asInt(_profile?["current_streak"], 0);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF7ED),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: const Color(0xFFF97316).withValues(alpha: 0.3)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: c.shadow.withValues(alpha: 0.08),
                                            blurRadius: 16,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.local_fire_department,
                                              color: Color(0xFFF97316), size: 18),
                                          const SizedBox(width: 6),
                                          Text(
                                            streak.toString(),
                                            style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: c.textPrimary),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ====== BANNER ======
                      if (showBanner)
                        SizeTransition(
                          sizeFactor: _bannerAnim,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 6),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFFD1FAE5),
                                    const Color(0xFFA7F3D0),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: c.success.withValues(alpha: 0.12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: c.card,
                                    child: const Icon(Icons.auto_awesome,
                                        color: Color(0xFF00C27A)),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Nice! Keep logging 🔥",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w800),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          "Your streak is building",
                                          style: TextStyle(
                                              color: Color(0xFF0B7A57),
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _closeBanner,
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // ====== OVERVIEW ======
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Overview",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _load,
                              child: const Text("Tap to refresh"),
                            ),
                          ],
                        ),
                      ),

                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: c.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: c.error.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    error!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _load,
                                  child: const Text("Retry"),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // ====== CARDS (Income/Expense/Balance) ======
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                        child: Row(
                          children: [
                            _miniCard(context, "Income", Icons.arrow_downward,
                                _money(income), iconBg: const Color(0xFFD1FAE5), iconColor: const Color(0xFF059669)),
                            const SizedBox(width: 12),
                            _miniCard(context, "Expense", Icons.arrow_upward,
                                _money(expense), iconBg: const Color(0xFFFEE2E2), iconColor: const Color(0xFFDC2626)),
                            const SizedBox(width: 12),
                            _miniCard(
                              context,
                              "Balance",
                              Icons.account_balance_wallet_outlined,
                              _money(bal),
                              iconBg: const Color(0xFFE0E7FF),
                              iconColor: const Color(0xFF4F46E5),
                            ),
                          ],
                        ),
                      ),

                      // ====== WALLET OVERVIEW (Cash / Card) ======
                      _walletOverviewRow(),

                      // ====== ACTION BUTTONS ======
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _bigAction(
                                color: const Color(0xFFFF4A3D),
                                icon: Icons.remove,
                                label: "Add Expense",
                                onTap: () async {
                                  final ok = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                      const AddTransactionPage(type: 'expense'),
                                    ),
                                  );
                                  if (ok == true) _load();
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _bigAction(
                                color: const Color(0xFF00C27A),
                                icon: Icons.add,
                                label: "Add Income",
                                onTap: () async {
                                  final ok = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                      const AddTransactionPage(type: 'income'),
                                    ),
                                  );
                                  if (ok == true) _load();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ====== RECENT TRANSACTIONS ======
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                        child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                            color: c.accentMuted.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: c.accent.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.receipt_long,
                                  color: c.accent, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Recent transactions",
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w800,
                                      color: c.textPrimary),
                                ),
                              ),
                              TextButton(
                                  onPressed: _load, child: const Text("Refresh")),
                            ],
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                        child: _recentTransactionsList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom nav overlay (matches other pages)
          const Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: CustomBottomNav(currentIndex: 0),
          ),
        ],
        ),
      ),
    );
  }

  Widget _miniCard(BuildContext context, String title, IconData icon, String amount,
      {Color? iconBg, Color? iconColor}) {
    final c = ZenoPayColors.of(context);
    final bg = iconBg ?? c.accentMuted;
    final fg = iconColor ?? c.accent;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: c.shadow.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8)),
            BoxShadow(color: c.shadow.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: bg,
              child: Icon(icon, color: fg, size: 22),
            ),
            const SizedBox(height: 10),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: c.textSecondary)),
            const SizedBox(height: 6),
            Text("Rs $amount", style: TextStyle(fontWeight: FontWeight.w900, color: c.textPrimary)),
          ],
        ),
      ),
    );
  }

  // ✅ Wallet overview helpers (same card style as your mini cards)
  Widget _walletMiniCard(BuildContext context, String title, IconData icon, String amount,
      {Color? iconBg, Color? iconColor}) {
    final c = ZenoPayColors.of(context);
    final bg = iconBg ?? c.accentMuted;
    final fg = iconColor ?? c.accent;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: c.shadow.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8)),
            BoxShadow(color: c.shadow.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: bg,
              child: Icon(icon, color: fg, size: 22),
            ),
            const SizedBox(height: 10),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: c.textSecondary)),
            const SizedBox(height: 6),
            Text("Rs $amount", style: TextStyle(fontWeight: FontWeight.w900, color: c.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _walletOverviewRow() {
    // If wallets are not loaded yet, don't show anything (keeps UI clean)
    if (_wallets.isEmpty) return const SizedBox.shrink();

    final cash = _walletBalanceByType("cash");

    // backend may store "bank" or "card"
    final bank = _walletBalanceByType("bank");
    final card = _walletBalanceByType("card");
    final cardOrBank = bank != 0 ? bank : card;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          _walletMiniCard(context, "Cash Balance", Icons.payments_outlined, _money(cash),
              iconBg: const Color(0xFFFEF3C7), iconColor: const Color(0xFFD97706)),
          const SizedBox(width: 12),
          _walletMiniCard(context, "Card Balance", Icons.credit_card, _money(cardOrBank),
              iconBg: const Color(0xFFCCFBF1), iconColor: const Color(0xFF0D9488)),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label) {
    final c = ZenoPayColors.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.border),
        ),
        child: Center(
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary)),
        ),
      ),
    );
  }

  Widget _bigAction({
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              Color.lerp(color, Colors.black, 0.15) ?? color,
            ]!,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.28),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 10),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)), // gradient button
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentTransactionsList() {
    final c = ZenoPayColors.of(context);
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          "No transactions yet.",
          style: TextStyle(fontWeight: FontWeight.w700, color: c.textSecondary),
        ),
      );
    }

    final items = transactions.take(6).toList();

    return Column(
      children: items.map((t) {
        final type = (t["type"] ?? "").toString();
        final amount = double.tryParse(t["amount"].toString()) ?? 0;
        final category = (t["category"] ?? "Other").toString();

        final iconKey = (t["icon_key"] ?? "").toString();
        final iconData = IconRegistry.byKey(iconKey);

        final isIncome = type == "income";
        final sign = isIncome ? "+" : "-";

        final iconBg = isIncome ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2);
        final iconFg = isIncome ? const Color(0xFF059669) : const Color(0xFFDC2626);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: iconFg.withValues(alpha: 0.4), width: 3)),
            boxShadow: [
              BoxShadow(color: c.shadow.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 8)),
              BoxShadow(color: c.shadow.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: iconBg,
                child: Icon(iconData, color: iconFg, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category, style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      (t["note"] ?? "").toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: c.textMuted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "$sign Rs ${_money(amount)}",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: isIncome ? c.success : c.error,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}