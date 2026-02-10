import 'package:flutter/material.dart';
import 'package:zenopay/services/auth_api.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> with TickerProviderStateMixin {
  final AuthApi api = AuthApi();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  late AnimationController _animController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  static const _accent = Color(0xFF4F6DFF);
  static const _surface = Color(0xFFF8FAFC);
  static const _cardBg = Colors.white;
  static const _textPrimary = Color(0xFF1E2A3B);
  static const _textSecondary = Color(0xFF64748B);

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _doRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      _toast("Fill all fields");
      return;
    }

    setState(() => _loading = true);
    try {
      await api.register(name, email, pass).timeout(const Duration(seconds: 22));
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (r) => false);
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();

    const curve = Curves.easeOutCubic;
    _fadeAnimations = List.generate(7, (i) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(i * 0.1 + 0.05, 0.95, curve: curve),
        ),
      );
    });

    _slideAnimations = List.generate(7, (i) {
      return Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(i * 0.1 + 0.05, 0.95, curve: curve),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _animatedSection(int index, Widget child) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) => FadeTransition(
        opacity: _fadeAnimations[index],
        child: SlideTransition(
          position: _slideAnimations[index],
          child: child,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _textSecondary, fontWeight: FontWeight.w600),
      prefixIcon: Icon(icon, color: _accent.withValues(alpha: 0.8), size: 22),
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              _animatedSection(
                0,
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_accent.withValues(alpha: 0.15), _accent.withValues(alpha: 0.06)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _accent.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.person_add_rounded, size: 48, color: _accent),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Create your account",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Start your money journey with streaks & challenges",
                      style: TextStyle(fontSize: 14, color: _textSecondary, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              _animatedSection(
                1,
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: _textPrimary),
                        decoration: _inputDecoration("Full name", Icons.person_outline_rounded),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: _textPrimary),
                        decoration: _inputDecoration("Email", Icons.email_outlined),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: _textPrimary),
                        decoration: _inputDecoration("Password", Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: _textSecondary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              _animatedSection(
                2,
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _doRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Create account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              _animatedSection(
                3,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? ", style: TextStyle(color: _textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(4),
                      child: const Text("Sign in", style: TextStyle(color: _accent, fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
