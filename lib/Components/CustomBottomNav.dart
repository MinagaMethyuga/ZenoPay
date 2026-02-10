import 'package:flutter/material.dart';
import 'package:zenopay/Components/add_transaction_page.dart';
import 'package:zenopay/theme/zenopay_colors.dart';

class CustomBottomNav extends StatefulWidget {
  final int currentIndex;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(CustomBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animController.forward(from: 0).then((_) => _animController.reset());
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onItemTapped(BuildContext context, int index) {
    if (widget.currentIndex == index) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/ZenoChallenge');
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddTransactionPage(
              type: 'expense',
              userId: 1,
            ),
          ),
        );
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/Budgeting');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/Leaderboards');
        break;
      case 5:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ZenoPayColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: c.navBar,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: c.borderLight.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: c.shadow.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, icon: Icons.home_rounded, label: 'Home', index: 0),
            _buildNavItem(context, icon: Icons.emoji_events_rounded, label: 'Challenges', index: 1),
            _buildNavItem(context, icon: Icons.add_rounded, label: 'Add', index: 2),
            _buildNavItem(context, icon: Icons.account_balance_wallet_rounded, label: 'Budget', index: 3),
            _buildNavItem(context, icon: Icons.leaderboard_rounded, label: 'Board', index: 4),
            _buildNavItem(context, icon: Icons.person_rounded, label: 'Profile', index: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
  }) {
    final c = ZenoPayColors.of(context);
    final isActive = widget.currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(context, index),
          borderRadius: BorderRadius.circular(20),
          splashColor: c.accent.withValues(alpha: 0.2),
          highlightColor: c.accent.withValues(alpha: 0.08),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(isActive ? 6 : 0),
                  decoration: isActive
                      ? BoxDecoration(
                          color: c.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        )
                      : null,
                  child: Icon(
                    icon,
                    size: 24,
                    color: isActive ? c.accent : c.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? c.accent : c.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
