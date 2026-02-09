import 'package:flutter/material.dart';

class OnboardingJourney extends StatefulWidget {
  const OnboardingJourney({super.key});

  @override
  State<OnboardingJourney> createState() => _OnboardingJourneyState();
}

class _OnboardingJourneyState extends State<OnboardingJourney> {
  final PageController _pc = PageController();
  int _step = 0;

  final _cashCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _bankBalCtrl = TextEditingController();

  bool _saving = false;

  void _next() => _pc.nextPage(duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
  void _back() => _pc.previousPage(duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _finish() async {
    final cash = double.tryParse(_cashCtrl.text.trim());
    final bankBal = double.tryParse(_bankBalCtrl.text.trim());
    final bankName = _bankCtrl.text.trim();

    if (cash == null || cash < 0) return _toast("Enter valid cash amount");
    if (bankName.isEmpty) return _toast("Enter bank name");
    if (bankBal == null || bankBal < 0) return _toast("Enter valid bank balance");

    setState(() => _saving = true);

    try {
      // ✅ NEXT STEP: call backend /api/onboarding to store wallets
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _pc.dispose();
    _cashCtrl.dispose();
    _bankCtrl.dispose();
    _bankBalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B12),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (_step + 1) / 3,
                        minHeight: 10,
                        backgroundColor: const Color(0xFF1A2233),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF00E5A8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text("Step ${_step + 1}/3", style: const TextStyle(color: Color(0xFF9FB0C8))),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pc,
                onPageChanged: (i) => setState(() => _step = i),
                children: [
                  _stepCard(
                    title: "Welcome to your journey ✨",
                    subtitle: "Let’s set starting cash + bank so we can track streaks & challenges correctly.",
                    child: const Icon(Icons.auto_awesome, color: Color(0xFF00E5A8), size: 120),
                  ),
                  _stepCard(
                    title: "Cash Wallet",
                    subtitle: "How much cash do you have right now?",
                    child: TextField(
                      controller: _cashCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: _input("e.g. 5000.00", Icons.payments_rounded),
                    ),
                  ),
                  _stepCard(
                    title: "Bank / Card Wallet",
                    subtitle: "We only store bank name + balance (no card numbers).",
                    child: Column(
                      children: [
                        TextField(
                          controller: _bankCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: _input("Bank name (e.g. BOC)", Icons.account_balance_rounded),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _bankBalCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: _input("Starting balance", Icons.credit_card_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : _back,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2B3A55)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("Back", style: TextStyle(color: Color(0xFFB9C6DD))),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : (_step < 2 ? _next : _finish),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5A8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _saving
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(
                        _step < 2 ? "Next" : "Finish",
                        style: const TextStyle(color: Color(0xFF07101A), fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepCard({required String title, required String subtitle, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1422),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF1E2A40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Color(0xFF9FB0C8), height: 1.35, fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            Expanded(child: Center(child: child)),
          ],
        ),
      ),
    );
  }

  InputDecoration _input(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF00E5A8)),
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF556987)),
      filled: true,
      fillColor: const Color(0xFF0A0F1C),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1E2A40))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF1E2A40))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF00E5A8))),
    );
  }
}