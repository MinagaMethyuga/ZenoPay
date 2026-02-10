import 'package:flutter/material.dart';
import 'package:zenopay/Components/CustomBottomNav.dart';
import 'package:zenopay/Components/FullPageLoader.dart';
import 'package:zenopay/models/challenge_model.dart';
import 'package:zenopay/models/user_model.dart';
import 'package:zenopay/services/auth_api.dart';
import 'package:zenopay/services/challenge_service.dart';
import 'package:zenopay/state/current_user.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  String? _error;
  ZenoUser? _user;
  int _streak = 0;
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

      final rawProfile = userMap['profile'];
      int streak = 0;
      if (rawProfile is Map<String, dynamic>) {
        streak = _asInt(rawProfile['current_streak'], 0);
      } else if (rawProfile is Map) {
        final map = rawProfile.cast<String, dynamic>();
        streak = _asInt(map['current_streak'], 0);
      }

      final challengeService = ChallengeService();
      final forYou = await challengeService.getChallengesForYou();
      final completed = forYou.accepted.where((a) => a.status == 'completed').toList();

      if (!mounted) return;
      setState(() {
        _user = user;
        _streak = streak;
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
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: FullPageLoader(accentColor: Color(0xFF4F6DFF)),
      );
    }

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
                  colors: [const Color(0xFFF8FAFC).withValues(alpha: 0), const Color(0xFFF8FAFC)],
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 8))],
          ),
          child: const Icon(Icons.person_rounded, color: Color(0xFF4F6DFF), size: 28),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2A3B),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Your level, XP & badges',
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

  Widget _buildProfileCard() {
    final user = _user ?? CurrentUser.value;
    final name = user?.name.trim().isEmpty ?? true ? 'Student' : user!.name;
    final totalXp = user?.totalXp ?? 0;
    final levelName = user?.levelName.trim().isEmpty ?? true ? 'Beginner' : user!.levelName;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 8))],
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
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E2A3B),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  levelName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ),
              if (_streak > 0) ...[
                const SizedBox(width: 10),
                Container(
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
                        '$_streak day streak',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E2A3B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard() {
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 8))],
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
                  const Text(
                    'Level progress',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    levelName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2A3B),
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
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F6DFF)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalXp XP total',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (xpToNext > 0)
                Text(
                  '$xpToNext XP to next level',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4F6DFF),
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                const Text(
                  'Max level reached!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF10B981),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.workspace_premium_rounded, color: Color(0xFF4F6DFF), size: 22),
            const SizedBox(width: 8),
            const Text(
              'Badges earned',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E2A3B),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 8))],
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: const Color(0xFF94A3B8).withValues(alpha: 0.7),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No badges yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Complete challenges to earn badges',
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
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
    final color = _colorFromString(item.color) ?? const Color(0xFF6366F1);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 8))],
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
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E2A3B),
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
