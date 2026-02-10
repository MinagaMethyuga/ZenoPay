import "package:flutter/material.dart";

import "package:zenopay/Components/CustomBottomNav.dart";
import "package:zenopay/Components/add_transaction_page.dart" hide IconRegistry;

import "package:zenopay/core/config.dart";
import "package:zenopay/core/icon_registry.dart";
import "package:zenopay/models/user_model.dart";
import "package:zenopay/services/api_client.dart";
import "package:zenopay/services/auth_api.dart";
import "package:zenopay/state/current_user.dart";

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

  int get _currentStreak => _asInt(_profile?["current_streak"], 0);

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
    final income = totalIncome;
    final expense = totalExpense;
    final bal = balance;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
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
                                border: Border.all(
                                    color: const Color(0xFF7C4DFF), width: 2),
                              ),
                              child: const Icon(Icons.person,
                                  color: Color(0xFF7C4DFF)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Hi, $_displayName 👋",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E2A3B),
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
                                            backgroundColor:
                                            const Color(0xFFE6E9F0),
                                            color: const Color(0xFF4F6DFF),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "LVL $_levelLabel",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF4F6DFF),
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
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x11000000),
                                        blurRadius: 16,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          color: Color(0xFF4F6DFF), size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        "$_displayXp XP",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x11000000),
                                        blurRadius: 16,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.local_fire_department,
                                          color: Color(0xFFFF7A00), size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        _currentStreak.toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
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
                                color: const Color(0xFFD9FFF0),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Colors.white,
                                    child: Icon(Icons.auto_awesome,
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
                            const Expanded(
                              child: Text(
                                "Overview",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E2A3B),
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
                              color: const Color(0xFFFFE8E8),
                              borderRadius: BorderRadius.circular(16),
                              border:
                              Border.all(color: const Color(0xFFFFB3B3)),
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
                            _miniCard("Income", Icons.arrow_downward,
                                _money(income)),
                            const SizedBox(width: 12),
                            _miniCard("Expense", Icons.arrow_upward,
                                _money(expense)),
                            const SizedBox(width: 12),
                            _miniCard(
                              "Balance",
                              Icons.account_balance_wallet_outlined,
                              _money(bal),
                            ),
                          ],
                        ),
                      ),

                      // ====== WALLET OVERVIEW (Cash / Card) ======
                      _walletOverviewRow(),

                      // ====== QUICK SHORTCUTS ======
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Quick shortcuts",
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E2A3B)),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _chip("Food"),
                                const SizedBox(width: 10),
                                _chip("Transport"),
                                const SizedBox(width: 10),
                                _chip("Bills"),
                              ],
                            ),
                          ],
                        ),
                      ),

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
                                      const AddTransactionPage(),
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
                                      const AddTransactionPage(),
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
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_long,
                                color: Color(0xFF4F6DFF)),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                "Recent transactions",
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                            ),
                            TextButton(
                                onPressed: _load, child: const Text("Refresh")),
                          ],
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
    );
  }

  Widget _miniCard(String title, IconData icon, String amount) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x11000000), blurRadius: 16, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFF2F4FF),
              child: Icon(icon, color: const Color(0xFF4F6DFF)),
            ),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Color(0xFF56657A))),
            const SizedBox(height: 6),
            Text("Rs $amount", style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  // ✅ Wallet overview helpers (same card style as your mini cards)
  Widget _walletMiniCard(String title, IconData icon, String amount) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x11000000), blurRadius: 16, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFF2F4FF),
              child: Icon(icon, color: const Color(0xFF4F6DFF)),
            ),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Color(0xFF56657A))),
            const SizedBox(height: 6),
            Text("Rs $amount", style: const TextStyle(fontWeight: FontWeight.w900)),
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
          _walletMiniCard("Cash Balance", Icons.payments_outlined, _money(cash)),
          const SizedBox(width: 12),
          _walletMiniCard("Card Balance", Icons.credit_card, _money(cardOrBank)),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE6E9F0)),
        ),
        child: Center(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
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
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.25),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentTransactionsList() {
    if (loading) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator()));
    }

    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          "No transactions yet.",
          style:
          TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF56657A)),
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

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFF2F4FF),
                child: Icon(iconData, color: const Color(0xFF4F6DFF)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      (t["note"] ?? "").toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFF7B8799), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "$sign Rs ${_money(amount)}",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: isIncome ? const Color(0xFF00C27A) : const Color(0xFFFF4A3D),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}