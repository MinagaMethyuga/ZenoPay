import "dart:convert";
import "dart:io";
import "dart:math";
import "package:zenopay/services/api_client.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:http/http.dart" as http;
import "package:image_picker/image_picker.dart";
import "package:zenopay/core/config.dart";

// -------------------- Models --------------------

enum TxType { expense, income }
enum WalletType { cash, bank }
enum CategoryType { expense, income, both }

class CategoryItem {
  final String id;
  final String name;
  final String iconKey; // store as string key (backend-safe)
  final int colorValue; // Color.value
  final CategoryType type;
  final bool isFrequent;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.type,
    required this.isFrequent,
  });

  Color get color => Color(colorValue);

  CategoryItem copyWith({
    String? id,
    String? name,
    String? iconKey,
    int? colorValue,
    CategoryType? type,
    bool? isFrequent,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
      isFrequent: isFrequent ?? this.isFrequent,
    );
  }
}

/// In-memory store (UI-first).
/// Later you can replace with API calls to Laravel.
class CategoryStore {
  static final List<CategoryItem> _all = [
    // Expense defaults
    CategoryItem(
      id: "cat_food",
      name: "Food",
      iconKey: "mi:fastfood",
      colorValue: 0xFF10B981,
      type: CategoryType.expense,
      isFrequent: true,
    ),
    CategoryItem(
      id: "cat_transport",
      name: "Transport",
      iconKey: "mi:directions_bus",
      colorValue: 0xFF3B82F6,
      type: CategoryType.expense,
      isFrequent: true,
    ),
    CategoryItem(
      id: "cat_bills",
      name: "Bills",
      iconKey: "mi:receipt_long",
      colorValue: 0xFFF59E0B,
      type: CategoryType.expense,
      isFrequent: true,
    ),
    CategoryItem(
      id: "cat_shopping",
      name: "Shopping",
      iconKey: "mi:shopping_bag",
      colorValue: 0xFF8B5CF6,
      type: CategoryType.expense,
      isFrequent: true,
    ),
    CategoryItem(
      id: "cat_ent",
      name: "Entertainment",
      iconKey: "mi:theaters",
      colorValue: 0xFFEC4899,
      type: CategoryType.expense,
      isFrequent: false,
    ),
    CategoryItem(
      id: "cat_health",
      name: "Health",
      iconKey: "mi:medical_services",
      colorValue: 0xFFEF4444,
      type: CategoryType.expense,
      isFrequent: false,
    ),
    CategoryItem(
      id: "cat_edu",
      name: "Education",
      iconKey: "mi:school",
      colorValue: 0xFF0EA5E9,
      type: CategoryType.expense,
      isFrequent: false,
    ),
    CategoryItem(
      id: "cat_rent",
      name: "Rent",
      iconKey: "mi:home",
      colorValue: 0xFF14B8A6,
      type: CategoryType.expense,
      isFrequent: false,
    ),

    // Income defaults
    CategoryItem(
      id: "cat_salary",
      name: "Salary",
      iconKey: "mi:payments",
      colorValue: 0xFF10B981,
      type: CategoryType.income,
      isFrequent: true,
    ),
    CategoryItem(
      id: "cat_allow",
      name: "Allowance",
      iconKey: "mi:account_balance_wallet",
      colorValue: 0xFF3B82F6,
      type: CategoryType.income,
      isFrequent: true,
    ),
    CategoryItem(
      id: "cat_free",
      name: "Freelance",
      iconKey: "mi:work",
      colorValue: 0xFF8B5CF6,
      type: CategoryType.income,
      isFrequent: false,
    ),
  ];

  static Future<List<CategoryItem>> byTxType(TxType txType) async {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final want = txType == TxType.income ? CategoryType.income : CategoryType.expense;
    return _all.where((c) => c.type == want || c.type == CategoryType.both).toList();
  }

  static Future<List<CategoryItem>> frequentByTxType(TxType txType) async {
    final list = await byTxType(txType);
    return list.where((c) => c.isFrequent).toList();
  }

  static Future<void> addCustom(CategoryItem item) async {
    _all.add(item);
  }
}

// -------------------- Icon registry (curated + searchable) --------------------

class IconOption {
  final String key; // stored string
  final String label; // for search
  final IconData icon;

  const IconOption({required this.key, required this.label, required this.icon});
}

class IconRegistry {
  static const List<Color> palette = [
    Color(0xFF10B981),
    Color(0xFF22C55E),
    Color(0xFF3B82F6),
    Color(0xFF0EA5E9),
    Color(0xFF14B8A6),
    Color(0xFF06B6D4),
    Color(0xFF8B5CF6),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
    Color(0xFFF43F5E),
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFF59E0B),
    Color(0xFFEAB308),
    Color(0xFF64748B),
    Color(0xFF111827),
  ];

  static final Map<String, List<IconOption>> groups = {
    "Food & Drinks": const [
      IconOption(key: "mi:fastfood", label: "Fastfood", icon: Icons.fastfood),
      IconOption(key: "mi:restaurant", label: "Restaurant", icon: Icons.restaurant),
      IconOption(key: "mi:coffee", label: "Coffee", icon: Icons.coffee),
      IconOption(key: "mi:local_pizza", label: "Pizza", icon: Icons.local_pizza),
      IconOption(key: "mi:icecream", label: "Ice Cream", icon: Icons.icecream),
      IconOption(key: "mi:local_bar", label: "Bar", icon: Icons.local_bar),
      IconOption(key: "mi:bakery_dining", label: "Bakery", icon: Icons.bakery_dining),
      IconOption(key: "mi:shopping_basket", label: "Groceries", icon: Icons.shopping_basket),
    ],
    "Transport": const [
      IconOption(key: "mi:directions_bus", label: "Bus", icon: Icons.directions_bus),
      IconOption(key: "mi:directions_car", label: "Car", icon: Icons.directions_car),
      IconOption(key: "mi:two_wheeler", label: "Motorbike", icon: Icons.two_wheeler),
      IconOption(key: "mi:train", label: "Train", icon: Icons.train),
      IconOption(key: "mi:local_taxi", label: "Taxi", icon: Icons.local_taxi),
      IconOption(key: "mi:flight", label: "Flight", icon: Icons.flight),
      IconOption(key: "mi:pedal_bike", label: "Bicycle", icon: Icons.pedal_bike),
      IconOption(key: "mi:local_gas_station", label: "Fuel", icon: Icons.local_gas_station),
    ],
    "Bills & Utilities": const [
      IconOption(key: "mi:receipt_long", label: "Bill", icon: Icons.receipt_long),
      IconOption(key: "mi:bolt", label: "Electricity", icon: Icons.bolt),
      IconOption(key: "mi:water_drop", label: "Water", icon: Icons.water_drop),
      IconOption(key: "mi:wifi", label: "WiFi", icon: Icons.wifi),
      IconOption(key: "mi:phone_iphone", label: "Mobile", icon: Icons.phone_iphone),
      IconOption(key: "mi:subscriptions", label: "Subscriptions", icon: Icons.subscriptions),
      IconOption(key: "mi:credit_card", label: "Card", icon: Icons.credit_card),
      IconOption(key: "mi:account_balance", label: "Bank", icon: Icons.account_balance),
    ],
    "Home": const [
      IconOption(key: "mi:home", label: "Home", icon: Icons.home),
      IconOption(key: "mi:cleaning_services", label: "Cleaning", icon: Icons.cleaning_services),
      IconOption(key: "mi:chair", label: "Furniture", icon: Icons.chair),
      IconOption(key: "mi:kitchen", label: "Kitchen", icon: Icons.kitchen),
      IconOption(key: "mi:construction", label: "Repair", icon: Icons.construction),
      IconOption(key: "mi:local_laundry_service", label: "Laundry", icon: Icons.local_laundry_service),
    ],
    "Shopping": const [
      IconOption(key: "mi:shopping_cart", label: "Cart", icon: Icons.shopping_cart),
      IconOption(key: "mi:shopping_bag", label: "Bag", icon: Icons.shopping_bag),
      IconOption(key: "mi:storefront", label: "Store", icon: Icons.storefront),
      IconOption(key: "mi:local_mall", label: "Mall", icon: Icons.local_mall),
      IconOption(key: "mi:loyalty", label: "Tag", icon: Icons.loyalty),
      IconOption(key: "mi:inventory_2", label: "Package", icon: Icons.inventory_2),
    ],
    "Entertainment": const [
      IconOption(key: "mi:theaters", label: "Movies", icon: Icons.theaters),
      IconOption(key: "mi:music_note", label: "Music", icon: Icons.music_note),
      IconOption(key: "mi:sports_esports", label: "Gaming", icon: Icons.sports_esports),
      IconOption(key: "mi:headphones", label: "Headphones", icon: Icons.headphones),
      IconOption(key: "mi:celebration", label: "Celebration", icon: Icons.celebration),
    ],
    "Health": const [
      IconOption(key: "mi:medical_services", label: "Medical", icon: Icons.medical_services),
      IconOption(key: "mi:local_hospital", label: "Hospital", icon: Icons.local_hospital),
      IconOption(key: "mi:medication", label: "Medication", icon: Icons.medication),
      IconOption(key: "mi:spa", label: "Wellness", icon: Icons.spa),
    ],
    "Fitness & Sports": const [
      IconOption(key: "mi:fitness_center", label: "Gym", icon: Icons.fitness_center),
      IconOption(key: "mi:directions_run", label: "Run", icon: Icons.directions_run),
      IconOption(key: "mi:sports_soccer", label: "Soccer", icon: Icons.sports_soccer),
      IconOption(key: "mi:sports_basketball", label: "Basketball", icon: Icons.sports_basketball),
      IconOption(key: "mi:sports_tennis", label: "Tennis", icon: Icons.sports_tennis),
    ],
    "Work & Income": const [
      IconOption(key: "mi:payments", label: "Salary", icon: Icons.payments),
      IconOption(key: "mi:work", label: "Work", icon: Icons.work),
      IconOption(key: "mi:trending_up", label: "Profit", icon: Icons.trending_up),
      IconOption(key: "mi:account_balance_wallet", label: "Wallet", icon: Icons.account_balance_wallet),
      IconOption(key: "mi:attach_money", label: "Money", icon: Icons.attach_money),
    ],
    "Education": const [
      IconOption(key: "mi:school", label: "School", icon: Icons.school),
      IconOption(key: "mi:menu_book", label: "Book", icon: Icons.menu_book),
      IconOption(key: "mi:edit_note", label: "Notes", icon: Icons.edit_note),
      IconOption(key: "mi:calculate", label: "Calculator", icon: Icons.calculate),
      IconOption(key: "mi:laptop", label: "Laptop", icon: Icons.laptop),
    ],
    "Travel": const [
      IconOption(key: "mi:luggage", label: "Luggage", icon: Icons.luggage),
      IconOption(key: "mi:place", label: "Place", icon: Icons.place),
      IconOption(key: "mi:beach_access", label: "Beach", icon: Icons.beach_access),
      IconOption(key: "mi:hotel", label: "Hotel", icon: Icons.hotel),
      IconOption(key: "mi:map", label: "Map", icon: Icons.map),
    ],
    "Family & Pets": const [
      IconOption(key: "mi:groups", label: "Family", icon: Icons.groups),
      IconOption(key: "mi:child_care", label: "Child", icon: Icons.child_care),
      IconOption(key: "mi:pets", label: "Pets", icon: Icons.pets),
      IconOption(key: "mi:favorite", label: "Love", icon: Icons.favorite),
    ],
    "Donations & Gifts": const [
      IconOption(key: "mi:volunteer_activism", label: "Donation", icon: Icons.volunteer_activism),
      IconOption(key: "mi:redeem", label: "Gift", icon: Icons.redeem),
      IconOption(key: "mi:card_giftcard", label: "Giftcard", icon: Icons.card_giftcard),
      IconOption(key: "mi:emoji_events", label: "Award", icon: Icons.emoji_events),
    ],
    "Tech": const [
      IconOption(key: "mi:devices", label: "Devices", icon: Icons.devices),
      IconOption(key: "mi:phone_android", label: "Android", icon: Icons.phone_android),
      IconOption(key: "mi:router", label: "Router", icon: Icons.router),
      IconOption(key: "mi:memory", label: "Memory", icon: Icons.memory),
    ],
    "Beauty": const [
      IconOption(key: "mi:cut", label: "Salon", icon: Icons.cut),
      IconOption(key: "mi:brush", label: "Brush", icon: Icons.brush),
      IconOption(key: "mi:auto_awesome", label: "Skincare", icon: Icons.auto_awesome),
    ],
    "Misc": const [
      IconOption(key: "mi:category", label: "Category", icon: Icons.category),
      IconOption(key: "mi:more_horiz", label: "More", icon: Icons.more_horiz),
      IconOption(key: "mi:emoji_nature", label: "Nature", icon: Icons.emoji_nature),
      IconOption(key: "mi:attach_file", label: "Attachment", icon: Icons.attach_file),
    ],
  };

  static List<IconOption> get allIcons => groups.values.expand((l) => l).toList(growable: false);

  static IconData byKey(String key) {
    for (final o in allIcons) {
      if (o.key == key) return o.icon;
    }
    return Icons.category;
  }

  static List<IconOption> search(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return allIcons;

    final synonyms = <String, List<String>>{
      "food": ["fastfood", "restaurant", "pizza", "groceries"],
      "rent": ["home", "house"],
      "gym": ["fitness", "run"],
      "netflix": ["subscriptions", "movies"],
      "wifi": ["wifi", "router"],
      "salary": ["payments", "work", "money"],
    };

    final expanded = <String>{query};
    synonyms.forEach((k, vals) {
      if (query.contains(k)) expanded.addAll(vals);
    });

    return allIcons
        .where((o) => expanded.any((t) => o.label.toLowerCase().contains(t) || o.key.toLowerCase().contains(t)))
        .toList();
  }
}

// -------------------- Add Transaction Page --------------------

class AddTransactionPage extends StatefulWidget {
  /// "expense" or "income"
  final String type;

  /// Logged-in user id (wire from auth later)
  final int userId;

  /// Optional: open with a wallet pre-selected.
  /// If null, uses last-used wallet (in-memory) then falls back to Cash.
  final WalletType? initialWallet;

  /// Optional: open with a preset category (Home shortcuts)
  final String? presetCategoryId;
  final String? presetCategoryName;
  final String? presetCategoryIconKey;
  final int? presetCategoryColorValue;
  final CategoryType? presetCategoryType;

  const AddTransactionPage({
    super.key,
    this.type = "expense",
    this.userId = 1,
    this.initialWallet,
    this.presetCategoryId,
    this.presetCategoryName,
    this.presetCategoryIconKey,
    this.presetCategoryColorValue,
    this.presetCategoryType,
  });

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> with TickerProviderStateMixin {
  // "last used wallet" without extra dependencies
  static WalletType? _lastWallet;

  // Stepper
  int step = 0;

  // Tx state
  late TxType txType;
  late WalletType wallet;

  // Inputs
  String amountText = "0";
  final titleCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  DateTime occurredAt = DateTime.now();

  // Categories
  List<CategoryItem> categories = [];
  CategoryItem? selectedCategory;

  // Receipt
  XFile? receipt;

  // Saving
  bool saving = false;

  // Animations
  late final AnimationController _bgCtrl;
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  Color get _accent => txType == TxType.income ? const Color(0xFF10B981) : const Color(0xFFEF4444);
  List<Color> get _headerGradient => txType == TxType.income
      ? const [Color(0xFF10B981), Color(0xFF22C55E), Color(0xFF14B8A6)]
      : const [Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFF59E0B)];

  @override
  void initState() {
    super.initState();

    txType = widget.type.toLowerCase() == "income" ? TxType.income : TxType.expense;
    wallet = widget.initialWallet ?? _lastWallet ?? WalletType.cash;

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));

    _loadCategories();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _shakeCtrl.dispose();
    titleCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final loaded = await CategoryStore.byTxType(txType);
    if (!mounted) return;

    setState(() {
      categories = loaded;
      selectedCategory ??= loaded.isNotEmpty ? loaded.first : null;
    });

    await _applyPresetCategoryIfAny();
  }

  Future<void> _applyPresetCategoryIfAny() async {
    final hasPreset = widget.presetCategoryName != null || widget.presetCategoryId != null;
    if (!hasPreset) return;

    // try match existing
    final match = categories.cast<CategoryItem?>().firstWhere(
          (c) =>
              c != null &&
              ((widget.presetCategoryId != null && c.id == widget.presetCategoryId) ||
                  (widget.presetCategoryName != null && c.name.toLowerCase() == widget.presetCategoryName!.toLowerCase())),
          orElse: () => null,
        );

    if (match != null) {
      if (!mounted) return;
      setState(() => selectedCategory = match);
      return;
    }

    // If not found, create a custom category from preset and add to store.
    final preset = CategoryItem(
      id: widget.presetCategoryId ?? "preset_${DateTime.now().millisecondsSinceEpoch}",
      name: widget.presetCategoryName ?? "Custom",
      iconKey: widget.presetCategoryIconKey ?? "mi:category",
      colorValue: widget.presetCategoryColorValue ?? IconRegistry.palette.first.toARGB32(),
      type: widget.presetCategoryType ??
          (txType == TxType.income ? CategoryType.income : CategoryType.expense),
      isFrequent: true,
    );

    await CategoryStore.addCustom(preset);
    final reloaded = await CategoryStore.byTxType(txType);
    if (!mounted) return;
    setState(() {
      categories = reloaded;
      selectedCategory = reloaded.firstWhere((c) => c.id == preset.id, orElse: () => preset);
    });
  }

  // -------------------- Amount (keypad) --------------------

  double get amount => double.tryParse(amountText) ?? 0;

  void _keypadTap(String key) {
    HapticFeedback.selectionClick();

    if (key == "⌫") {
      if (amountText.length <= 1) {
        setState(() => amountText = "0");
        return;
      }
      setState(() => amountText = amountText.substring(0, amountText.length - 1));
      if (amountText == "-" || amountText.isEmpty) setState(() => amountText = "0");
      return;
    }

    if (key == "CLR") {
      setState(() => amountText = "0");
      return;
    }

    if (key == ".") {
      if (amountText.contains(".")) return;
      setState(() => amountText = "$amountText.");
      return;
    }

    final isDigit = RegExp(r"^\d$").hasMatch(key);
    if (!isDigit) return;

    if (amountText == "0") {
      setState(() => amountText = key);
    } else {
      if (amountText.contains(".")) {
        final parts = amountText.split(".");
        if (parts.length == 2 && parts[1].length >= 2) return;
      }
      if (amountText.length >= 12) return;
      setState(() => amountText = "$amountText$key");
    }
  }

  String _fmtMoney(String raw) {
    final v = double.tryParse(raw) ?? 0;
    final parts = v
        .toStringAsFixed(raw.contains(".") ? min(2, (raw.split(".").last.length)) : 0)
        .split(".");
    final intPart = parts[0];
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final idxFromEnd = intPart.length - i;
      buf.write(intPart[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(",");
    }
    if (parts.length == 2 && raw.contains(".")) return "${buf.toString()}.${parts[1]}";
    return buf.toString();
  }

  // -------------------- Validation --------------------

  bool get _step1Valid => amount > 0;
  bool get _step2Valid => titleCtrl.text.trim().isNotEmpty && selectedCategory != null;

  void _next() {
    if (step == 0 && !_step1Valid) {
      HapticFeedback.heavyImpact();
      _shakeCtrl.forward(from: 0);
      _toast("Enter an amount");
      return;
    }
    if (step == 1 && !_step2Valid) {
      HapticFeedback.heavyImpact();
      _toast("Add a title and select a category");
      return;
    }
    setState(() => step = min(2, step + 1));
  }

  void _back() {
    if (step == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => step = max(0, step - 1));
  }

  // -------------------- Date / Receipt --------------------

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: occurredAt,
    );
    if (!mounted) return;
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(occurredAt),
    );
    if (!mounted) return;
    if (time == null) return;

    if (!mounted) return;
    setState(() => occurredAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
    HapticFeedback.selectionClick();
  }

  String _fmtDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, "0");
    final dd = d.day.toString().padLeft(2, "0");
    final hh = d.hour.toString().padLeft(2, "0");
    final mi = d.minute.toString().padLeft(2, "0");
    return "${d.year}-$mm-$dd • $hh:$mi";
  }

  Future<void> _pickReceipt(ImageSource src) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: src, imageQuality: 85);
      if (file == null) return;
      setState(() => receipt = file);
      HapticFeedback.selectionClick();
    } catch (_) {
      _toast("Image picker not available. Add image_picker dependency.");
    }
  }

  // -------------------- Category picker --------------------

  Future<void> _openCategoryPicker() async {
    final result = await showModalBottomSheet<CategoryItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryPickerSheet(
        txType: txType,
        current: selectedCategory,
        existing: categories,
      ),
    );

    if (result == null) return;

    // If newly created, add to store
    final exists = categories.any((c) => c.id == result.id);
    if (!exists) {
      await CategoryStore.addCustom(result);
      await _loadCategories();
    }

    setState(() => selectedCategory = result);
  }

  // -------------------- Save (Laravel) --------------------

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  Future<void> _save() async {
    if (!_step1Valid) {
      _toast("Enter an amount");
      return;
    }
    if (!_step2Valid) {
      _toast("Add a title and select a category");
      return;
    }

    setState(() => saving = true);
    HapticFeedback.mediumImpact();

    try {
      final isIncome = txType == TxType.income;

      final body = {
        // ✅ DO NOT SEND user_id
        "type": isIncome ? "income" : "expense",
        "amount": amount,
        "category": selectedCategory!.name,
        "icon_key": selectedCategory!.iconKey,
        "note": _buildCombinedNote(titleCtrl.text.trim(), noteCtrl.text.trim()),
        "payment_method": wallet == WalletType.cash ? "cash" : "bank_transfer",
        "occurred_at": occurredAt.toIso8601String(),
        "source": "manual",
      };

      // ✅ Use Dio client (includes session cookies saved at login)
      final dio = await ApiClient.instance(AppConfig.apiBaseUrl);
      final res = await dio.post("/transactions", data: body);

      final decoded = res.data;
      if (decoded is Map && decoded["ok"] != true) {
        throw decoded;
      }

      _lastWallet = wallet;

      if (!mounted) return;
      HapticFeedback.lightImpact();
      _toast("Saved • +5 XP");
      Navigator.pop(context, true);
    } catch (e) {
      _toast("Save failed: $e");
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  
  // Build a single `note` string that satisfies the backend validator (no `title` field).
  // We merge title + note into one, safely.
  String _buildCombinedNote(String title, String note) {
    final t = title.trim();
    final n = note.trim();
    if (t.isEmpty && n.isEmpty) return "";
    if (t.isEmpty) return n;
    if (n.isEmpty) return t;
    return "$t\n$n";
  }

// -------------------- UI --------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          _animatedHeaderBackground(),
          SafeArea(
            child: Column(
              children: [
                _topBar(),
                _stepIndicator(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _buildStep(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedHeaderBackground() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 220,
      child: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (context, _) {
          final t = _bgCtrl.value;
          final begin = Alignment(-1 + (t * 0.6), -1);
          final end = Alignment(1, 1 - (t * 0.6));
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: begin, end: end, colors: _headerGradient),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.08), Colors.transparent],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          _glassIconButton(icon: Icons.arrow_back, onTap: _back),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "New Transaction",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
          _glassIconButton(icon: Icons.calendar_month, onTap: _pickDateTime),
        ],
      ),
    );
  }

  Widget _glassIconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _stepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Column(
        children: [
          _typeToggle(),
          const SizedBox(height: 10),
          Row(
            children: List.generate(3, (i) {
              final active = i <= step;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 6,
                  margin: EdgeInsets.only(right: i == 2 ? 0 : 8),
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white.withValues(alpha: 0.30),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(child: Text("Amount", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
              Expanded(
                  child: Text("Details",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
              Expanded(
                  child: Text("Receipt",
                      textAlign: TextAlign.end,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
            ],
          )
        ],
      ),
    );
  }

  Widget _typeToggle() {
    final isIncome = txType == TxType.income;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _segButton(
              label: "Expense",
              selected: !isIncome,
              icon: Icons.remove_circle_outline,
              color: const Color(0xFFEF4444),
              onTap: () async {
                if (!isIncome) return;
                HapticFeedback.selectionClick();
                setState(() {
                  txType = TxType.expense;
                  selectedCategory = null;
                });
                await _loadCategories();
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _segButton(
              label: "Income",
              selected: isIncome,
              icon: Icons.add_circle_outline,
              color: const Color(0xFF10B981),
              onTap: () async {
                if (isIncome) return;
                HapticFeedback.selectionClick();
                setState(() {
                  txType = TxType.income;
                  selectedCategory = null;
                });
                await _loadCategories();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _segButton({
    required String label,
    required bool selected,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : const Color(0xFF475569)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w900, color: selected ? Colors.white : const Color(0xFF475569)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (step) {
      case 0:
        return _step1Amount(key: const ValueKey("step1"));
      case 1:
        return _step2Details(key: const ValueKey("step2"));
      default:
        return _step3Receipt(key: const ValueKey("step3"));
    }
  }

  // -------------------- Step 1 --------------------
  Widget _step1Amount({Key? key}) {
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        AnimatedBuilder(
          animation: _shakeAnim,
          builder: (_, child) {
            final dx = sin(_shakeAnim.value * pi * 10) * (1 - _shakeAnim.value) * 10;
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _pillIcon(Icons.currency_exchange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Amount",
                        style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w900),
                      ),
                    ),
                    _dateChip(),
                  ],
                ),
                const SizedBox(height: 14),
                _amountDisplay(),
                const SizedBox(height: 12),
                _walletToggle(),
                const SizedBox(height: 14),
                _customKeypad(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _primaryButton(
          label: "Next",
          icon: Icons.arrow_forward,
          enabled: _step1Valid,
          onTap: _next,
        ),
      ],
    );
  }

  Widget _dateChip() {
    return InkWell(
      onTap: _pickDateTime,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: Color(0xFF475569)),
            const SizedBox(width: 6),
            Text(
              _fmtDate(occurredAt),
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF475569), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountDisplay() {
    final display = amountText.contains(".") ? amountText : "$amountText.00";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Text("LKR", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF475569))),
          const SizedBox(width: 10),
          Expanded(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 220),
              tween: Tween(begin: 0.98, end: 1.0),
              curve: Curves.easeOutBack,
              builder: (_, s, child) => Transform.scale(scale: s, child: child),
              child: Text(
                _fmtMoney(display),
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletToggle() {
    final isCash = wallet == WalletType.cash;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segButton(
              label: "Cash",
              selected: isCash,
              icon: Icons.payments_outlined,
              color: const Color(0xFF111827),
              onTap: () => setState(() => wallet = WalletType.cash),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _segButton(
              label: "Bank",
              selected: !isCash,
              icon: Icons.account_balance_outlined,
              color: const Color(0xFF111827),
              onTap: () => setState(() => wallet = WalletType.bank),
            ),
          ),
        ],
      ),
    );
  }

  Widget _customKeypad() {
    final keys = const ["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "⌫"];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (_, i) {
        final k = keys[i];
        final isDelete = k == "⌫";
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _keypadTap(k),
          onLongPress: isDelete ? () => _keypadTap("CLR") : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Text(
                k,
                style: TextStyle(
                  fontSize: isDelete ? 22 : 24,
                  fontWeight: FontWeight.w900,
                  color: isDelete ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // -------------------- Step 2 --------------------
  Widget _step2Details({Key? key}) {
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _pillIcon(Icons.edit_note),
                const SizedBox(width: 10),
                const Text("Details", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF334155))),
              ]),
              const SizedBox(height: 14),

              TextField(
                controller: titleCtrl,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.title),
                  labelText: "Title",
                  hintText: txType == TxType.income ? "e.g. Salary, Allowance" : "e.g. Lunch, Bus fare",
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: _accent, width: 2),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: _openCategoryPicker,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                    decoration: BoxDecoration(
                      color: (selectedCategory?.color ?? const Color(0xFF64748B))
                          .withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                        child: Icon(
                          IconRegistry.byKey(selectedCategory?.iconKey ?? "mi:category"),
                          color: selectedCategory?.color ?? const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedCategory?.name ?? "Select Category",
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  labelText: "Note (optional)",
                  hintText: "Add extra details…",
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: _accent, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _secondaryButton(label: "Back", icon: Icons.arrow_back, onTap: _back),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _primaryButton(
                label: "Next",
                icon: Icons.arrow_forward,
                enabled: _step2Valid,
                onTap: _next,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------- Step 3 --------------------
  Widget _step3Receipt({Key? key}) {
    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _pillIcon(Icons.receipt),
                const SizedBox(width: 10),
                const Text("Receipt (optional)", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF334155))),
              ]),
              const SizedBox(height: 14),
              if (receipt == null)
                Row(
                  children: [
                    Expanded(
                      child: _actionCard(
                        icon: Icons.photo_camera,
                        title: "Camera",
                        onTap: () => _pickReceipt(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionCard(
                        icon: Icons.photo_library,
                        title: "Gallery",
                        onTap: () => _pickReceipt(ImageSource.gallery),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        File(receipt!.path),
                        width: 74,
                        height: 74,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        receipt!.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => receipt = null),
                      icon: const Icon(Icons.close, color: Color(0xFFEF4444)),
                    )
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _pillIcon(Icons.fact_check),
                const SizedBox(width: 10),
                const Text("Review", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF334155))),
              ]),
              const SizedBox(height: 12),
              _reviewRow("Type", txType == TxType.income ? "Income" : "Expense"),
              _reviewRow("Amount", "LKR ${_fmtMoney(amountText.contains('.') ? amountText : '$amountText.00')}"),
              _reviewRow("Wallet", wallet == WalletType.cash ? "Cash" : "Bank"),
              _reviewRow("Title", titleCtrl.text.trim()),
              _reviewRow("Category", selectedCategory?.name ?? "-"),
              if (noteCtrl.text.trim().isNotEmpty) _reviewRow("Note", noteCtrl.text.trim()),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _secondaryButton(label: "Back", icon: Icons.arrow_back, onTap: _back)),
            const SizedBox(width: 10),
            Expanded(
              child: _primaryButton(
                label: saving ? "Saving..." : "Save",
                icon: saving ? Icons.hourglass_top : Icons.check_circle_outline,
                enabled: !saving,
                onTap: saving ? null : _save,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _reviewRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(k, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800))),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- UI helpers --------------------

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }

  Widget _pillIcon(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_accent, _accent.withValues(alpha: 0.65)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          disabledBackgroundColor: _accent.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _secondaryButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
          backgroundColor: Colors.white.withValues(alpha: 0.92),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF0F172A)),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _actionCard({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0F172A)),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }
}

// -------------------- Category Picker Sheet --------------------

class _CategoryPickerSheet extends StatefulWidget {
  final TxType txType;
  final CategoryItem? current;
  final List<CategoryItem> existing;

  const _CategoryPickerSheet({
    required this.txType,
    required this.current,
    required this.existing,
  });

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  String query = "";
  bool allMode = false;
  String group = IconRegistry.groups.keys.first;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final sheetH = min(media.size.height * 0.86, 720.0);

    final filteredIcons = IconRegistry.search(query);
    final groupIcons = IconRegistry.groups[group] ?? const <IconOption>[];

    return Container(
      height: sheetH,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 26,
            offset: const Offset(0, -8),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(999)),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Icons.category_outlined, color: Color(0xFF0F172A)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text("Select Category", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
              TextButton.icon(
                onPressed: _openNewCategory,
                icon: const Icon(Icons.add),
                label: const Text("New"),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: "Search icons…",
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onChanged: (v) => setState(() => query = v),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => setState(() => allMode = !allMode),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(allMode ? Icons.apps : Icons.view_list, color: const Color(0xFF0F172A)),
                      const SizedBox(width: 6),
                      Text(allMode ? "All" : "Groups", style: const TextStyle(fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (!allMode) ...[
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: IconRegistry.groups.keys.map((g) {
                  final sel = g == group;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => setState(() => group = g),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          g,
                          style: TextStyle(
                            color: sel ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
          ],

          Align(
            alignment: Alignment.centerLeft,
            child: Text("Your categories", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey.shade700)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.existing.length,
              separatorBuilder: (context, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final c = widget.existing[i];
                final sel = widget.current?.id == c.id;
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.pop(context, c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 140,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: sel ? c.color.withValues(alpha: 0.16) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: sel ? c.color : const Color(0xFFE2E8F0), width: 2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [c.color.withValues(alpha: 0.95), c.color.withValues(alpha: 0.55)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(IconRegistry.byKey(c.iconKey), color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            c.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          Expanded(child: _iconGrid(allMode ? filteredIcons : groupIcons)),
        ],
      ),
    );
  }

  Widget _iconGrid(List<IconOption> icons) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 6),
      itemCount: icons.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemBuilder: (_, i) {
        final opt = icons[i];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _quickCreateFromIcon(opt),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(opt.icon, color: const Color(0xFF0F172A)),
          ),
        );
      },
    );
  }

  Future<void> _quickCreateFromIcon(IconOption opt) async {
    final created = await showDialog<CategoryItem>(
      context: context,
      builder: (_) => _NewCategoryDialog(
        txType: widget.txType,
        presetIconKey: opt.key,
        presetName: opt.label,
      ),
    );
    if (created == null) return;
    if (!mounted) return;
    Navigator.pop(context, created);
  }

  Future<void> _openNewCategory() async {
    final created = await showDialog<CategoryItem>(
      context: context,
      builder: (_) => _NewCategoryDialog(txType: widget.txType),
    );
    if (created == null) return;
    if (!mounted) return;
    Navigator.pop(context, created);
  }
}

// -------------------- New Category Dialog --------------------

class _NewCategoryDialog extends StatefulWidget {
  final TxType txType;
  final String? presetIconKey;
  final String? presetName;

  const _NewCategoryDialog({
    required this.txType,
    this.presetIconKey,
    this.presetName,
  });

  @override
  State<_NewCategoryDialog> createState() => _NewCategoryDialogState();
}

class _NewCategoryDialogState extends State<_NewCategoryDialog> {
  late final TextEditingController nameCtrl;
  String iconKey = "mi:category";
  Color color = IconRegistry.palette.first;
  late CategoryType type;
  bool frequent = true;

  @override
  void initState() {
    super.initState();
    type = widget.txType == TxType.income ? CategoryType.income : CategoryType.expense;
    iconKey = widget.presetIconKey ?? "mi:category";
    nameCtrl = TextEditingController(text: widget.presetName ?? "");
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create Category", style: TextStyle(fontWeight: FontWeight.w900)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(IconRegistry.byKey(iconKey), color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      nameCtrl.text.trim().isEmpty ? "Category name" : nameCtrl.text.trim(),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Name", hintText: "e.g. Snacks, Gym, Netflix"),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                const Text("Type:", style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(width: 10),
                DropdownButton<CategoryType>(
                  value: type,
                  items: const [
                    DropdownMenuItem(value: CategoryType.expense, child: Text("Expense")),
                    DropdownMenuItem(value: CategoryType.income, child: Text("Income")),
                    DropdownMenuItem(value: CategoryType.both, child: Text("Both")),
                  ],
                  onChanged: (v) => setState(() => type = v ?? type),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerLeft,
              child: Text("Color", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey.shade700)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: IconRegistry.palette.map((c) {
                final sel = c.toARGB32() == color.toARGB32();
                return InkWell(
                  onTap: () => setState(() => color = c),
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(color: sel ? Colors.black : Colors.transparent, width: 2),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerLeft,
              child: Text("Icon", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey.shade700)),
            ),
            const SizedBox(height: 8),
            // IMPORTANT: Avoid GridView/ListView inside AlertDialog (can trigger intrinsic-size errors).
            // Wrap renders eagerly and is safe here.
            SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: IconRegistry.allIcons.take(40).map((opt) {
                    final sel = opt.key == iconKey;
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => iconKey = opt.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: sel ? color.withValues(alpha: 0.16) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: sel ? color : const Color(0xFFE2E8F0), width: 2),
                        ),
                        child: Icon(opt.icon, color: sel ? color : const Color(0xFF64748B)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 10),
            SwitchListTile(
              value: frequent,
              onChanged: (v) => setState(() => frequent = v),
              title: const Text("Show as frequent shortcut"),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;

            final id = "custom_${DateTime.now().millisecondsSinceEpoch}";
            final item = CategoryItem(
              id: id,
              name: name,
              iconKey: iconKey,
              colorValue: color.toARGB32(),
              type: type,
              isFrequent: frequent,
            );
            Navigator.pop(context, item);
          },
          child: const Text("Add", style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}