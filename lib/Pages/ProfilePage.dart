import 'package:flutter/material.dart';
import 'package:zenopay/Components/CustomBottomNav.dart';
import 'package:zenopay/Components/FullPageLoader.dart';
import 'package:zenopay/Components/StreakCelebrationOverlay.dart';
import 'package:zenopay/core/app_nav_key.dart';
import 'package:zenopay/models/challenge_model.dart';
import 'package:zenopay/models/user_model.dart';
import 'package:zenopay/services/auth_api.dart';
import 'package:zenopay/services/challenge_service.dart';
import 'package:zenopay/state/app_theme.dart';
import 'package:zenopay/state/current_user.dart';
import 'package:zenopay/theme/zenopay_colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  String? _error;
  ZenoUser? _user;
  List<ForYouAcceptedItem> _completedChallenges = [];

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
      final auth = AuthApi();
      final me = await auth.me();
      final rawUser = me['user'];
      Map<String, dynamic> userMap;
      if (rawUser is Map<String, dynamic>) {
        userMap = rawUser;
      } else if (rawUser is Map) {
        userMap = rawUser.cast<String, dynamic>();
      } else {
        userMap = <String, dynamic>{};
      }

      if (userMap.isEmpty) {
        throw Exception('Not authenticated');
      }

      final user = ZenoUser.fromJson(userMap);
      CurrentUser.set(user);

      final challengeService = ChallengeService();
      final forYou = await challengeService.getChallengesForYou();
      final completed = forYou.accepted.where((a) => a.status == 'completed').toList();

      if (!mounted) return;
      setState(() {
        _user = user;
        _completedChallenges = completed;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _user = CurrentUser.value;
        _loading = false;
      });
    }
  }

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final c = ZenoPayColors.of(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: c.surface,
        body: const FullPageLoader(accentColor: Color(0xFF4F6DFF)),
      );
    }

    return Scaffold(
      backgroundColor: c.surface,
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
                    if (_error != null && _user == null)
                      _buildError()
                    else ...[
                      _buildProfileCard(),
                      const SizedBox(height: 20),
                      _buildLevelCard(),
                      const SizedBox(height: 24),
                      _buildBadgesSection(),
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
                  colors: [c.surface.withValues(alpha: 0), c.surface],
                ),
              ),
              child: CustomBottomNav(currentIndex: 5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final c = ZenoPayColors.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: c.shadow.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 8))],
          ),
          child: Icon(Icons.person_rounded, color: c.accent, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: c.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Your level, XP & badges',
                style: TextStyle(
                  fontSize: 13,
                  color: c.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: c.shadow.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 8))],
          ),
          child: IconButton(
            onPressed: () => _showSettingsSheet(context),
            icon: const Icon(Icons.settings_rounded, color: Color(0xFF4F6DFF), size: 26),
            tooltip: 'Settings',
          ),
        ),
      ],
    );
  }

  void _showSettingsSheet(BuildContext context) {
    final c = ZenoPayColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: c.shadow.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.textSecondary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: AppTheme.notifier,
              builder: (context, themeMode, _) {
                final darkOn = themeMode == ThemeMode.dark;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          darkOn ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          color: c.accent,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Dark mode',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: darkOn,
                      onChanged: (_) async {
                        await AppTheme.toggle();
                      },
                      activeTrackColor: const Color(0xFF4F6DFF).withValues(alpha: 0.5),
                      activeThumbColor: const Color(0xFF4F6DFF),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _logout();
                },
                icon: const Icon(Icons.logout_rounded, size: 22),
                label: const Text('Log out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      final auth = AuthApi();
      await auth.logout();
      if (!mounted) return;
      navKey.currentState?.pushNamedAndRemoveUntil('/login', (r) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildError() {
    final c = ZenoPayColors.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: c.shadow.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 8))],
        border: Border.all(color: c.error.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: c.error, size: 40),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Something went wrong',
            style: TextStyle(color: c.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final c = ZenoPayColors.of(context);
    final user = _user ?? CurrentUser.value;
    final name = user?.name.trim().isEmpty ?? true ? 'Student' : user!.name;
    final totalXp = user?.totalXp ?? 0;
    final levelName = user?.levelName.trim().isEmpty ?? true ? 'Beginner' : user!.levelName;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: c.shadow.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: const Color(0xFFF2F4FF),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4F6DFF),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onLongPress: () {
              // Test streak celebration animation (long-press to preview)
              StreakCelebrationOverlay.show();
            },
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 6,
              children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFF4F6DFF), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '$totalXp XP',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2A3B),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: c.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  levelName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: c.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              ValueListenableBuilder<ZenoUser?>(
                valueListenable: CurrentUser.notifier,
                builder: (context, globalUser, _) {
                  final streak = globalUser?.profile?.currentStreak ??
                      _user?.profile?.currentStreak ?? 0;
                  if (streak <= 0) return const SizedBox.shrink();
                  return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF97316), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '$streak day streak',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF9A3412),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                  );
                },
              ),
            ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard() {
    final c = ZenoPayColors.of(context);
    final user = _user ?? CurrentUser.value;
    final totalXp = user?.totalXp ?? 0;
    final xpToNext = user?.xpToNextLevel ?? 0;
    final levelName = user?.levelName.trim().isEmpty ?? true ? 'Beginner' : user!.levelName;

    double progress = 0.5;
    if (xpToNext > 0 && (totalXp + xpToNext) > 0) {
      progress = 1.0 - (xpToNext / (totalXp + xpToNext));
      progress = progress.clamp(0.0, 1.0);
    } else if (xpToNext <= 0) {
      progress = 1.0;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: c.shadow.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level progress',
                    style: TextStyle(
                      fontSize: 13,
                      color: c.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    levelName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
            backgroundColor: c.progressBg,
            valueColor: AlwaysStoppedAnimation<Color>(c.accent),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalXp XP total',
                style: TextStyle(
                  fontSize: 12,
                  color: c.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (xpToNext > 0)
                Text(
                  '$xpToNext XP to next level',
                  style: TextStyle(
                    fontSize: 12,
                    color: c.accent,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Text(
                  'Max level reached!',
                  style: TextStyle(
                    fontSize: 12,
                    color: c.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection() {
    final c = ZenoPayColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: c.accent, size: 22),
            const SizedBox(width: 8),
            Text(
              'Badges earned',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_completedChallenges.length}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4F6DFF),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_completedChallenges.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: c.shadow.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 8))],
              border: Border.all(color: c.border),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: c.textMuted.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 12),
                Text(
                  'No badges yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete challenges to earn badges',
                  style: TextStyle(fontSize: 13, color: c.textMuted),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: _completedChallenges.length,
            itemBuilder: (context, index) {
              return _buildBadgeCard(_completedChallenges[index]);
            },
          ),
      ],
    );
  }

  Widget _buildBadgeCard(ForYouAcceptedItem item) {
    final c = ZenoPayColors.of(context);
    final color = _colorFromString(item.color) ?? const Color(0xFF6366F1);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: c.shadow.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 8))],
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                item.icon ?? '🏆',
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '+${item.rewardPoints} XP',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF059669),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color? _colorFromString(String? s) {
    if (s == null || s.isEmpty) return null;
    final hex = s.replaceFirst('#', '');
    if (hex.length == 6) {
      final v = int.tryParse(hex, radix: 16);
      if (v != null) return Color(0xFF000000 + v);
    }
    const names = {
      'purple': Color(0xFF8B5CF6),
      'indigo': Color(0xFF6366F1),
      'blue': Color(0xFF3B82F6),
      'green': Color(0xFF10B981),
      'amber': Color(0xFFF59E0B),
    };
    return names[s.toLowerCase()];
  }
}
