import 'package:flutter/material.dart';
import 'package:zenopay/services/auth_api.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with TickerProviderStateMixin {
  final AuthApi api = AuthApi();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

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

  Future<void> _doLogin() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text;

    if (email.isEmpty || pass.isEmpty) {
      _toast("Enter email and password");
      return;
    }

    setState(() => _loading = true);
    try {
      await api.login(email, pass);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
    } catch (e) {
      _toast("Login failed: $e");
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
    _fadeAnimations = List.generate(8, (i) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(i * 0.08 + 0.05, 0.9, curve: curve),
        ),
      );
    });

    _slideAnimations = List.generate(8, (i) {
      return Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(i * 0.08 + 0.05, 0.9, curve: curve),
        ),
      );
    });
  }

  @override
  void dispose() {
    _animController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

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
                      child: const Icon(Icons.account_balance_wallet_rounded, size: 48, color: _accent),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Welcome Back",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sign in to continue your financial journey",
                      style: TextStyle(fontSize: 15, color: _textSecondary, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

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
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: _textPrimary),
                        decoration: InputDecoration(
                          labelText: "Email",
                          labelStyle: TextStyle(color: _textSecondary, fontWeight: FontWeight.w600),
                          prefixIcon: Icon(Icons.email_outlined, color: _accent.withValues(alpha: 0.8), size: 22),
                          filled: true,
                          fillColor: _surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _accent, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: _textPrimary),
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: TextStyle(color: _textSecondary, fontWeight: FontWeight.w600),
                          prefixIcon: Icon(Icons.lock_outline, color: _accent.withValues(alpha: 0.8), size: 22),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: _textSecondary,
                              size: 22,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: _surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _accent, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text("Forgot Password?", style: TextStyle(color: _accent, fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _animatedSection(
                2,
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _doLogin,
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
                        : const Text("Sign In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              _animatedSection(
                3,
                Row(
                  children: [
                    Expanded(child: Divider(thickness: 1, color: Colors.black.withValues(alpha: 0.12))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text("or continue with", style: TextStyle(color: _textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    Expanded(child: Divider(thickness: 1, color: Colors.black.withValues(alpha: 0.12))),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _animatedSection(
                4,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialButton(
                      icon: "https://img.icons8.com/color/48/google-logo.png",
                      label: "Google",
                      isImage: true,
                    ),
                    const SizedBox(width: 16),
                    _socialButton(
                      icon: Icons.apple,
                      label: "Apple",
                      isImage: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              _animatedSection(
                5,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account? ", style: TextStyle(color: _textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
                    InkWell(
                      onTap: () => Navigator.pushNamed(context, '/register'),
                      borderRadius: BorderRadius.circular(4),
                      child: const Text("Sign up", style: TextStyle(color: _accent, fontSize: 15, fontWeight: FontWeight.w700)),
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

  Widget _socialButton({dynamic icon, required String label, required bool isImage}) {
    return Container(
      width: 140,
      height: 50,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isImage)
                Image.network(icon as String, height: 22, width: 22)
              else
                Icon(icon as IconData, color: _textPrimary, size: 22),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontSize: 15, color: _textPrimary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
