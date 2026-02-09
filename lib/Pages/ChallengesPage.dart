import 'package:flutter/material.dart';
import 'package:zenopay/Components/CustomBottomNav.dart';
import '../models/challenge_model.dart';
import '../services/challenge_service.dart';


class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  String selectedTab = 'Active';
  final ChallengeService _challengeService = ChallengeService();

  List<Challenge> allChallenges = [];
  List<Challenge> dailyChallenges = [];
  List<Challenge> activeChallenges = [];
  /// challengeId -> status + progress + target (from /api/my-challenges)
  Map<int, MyChallengeStatus> acceptedMap = {};
  bool isLoading = true;
  int totalXP = 0;
  int streakDays = 12;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final catalog = await _challengeService.getActiveChallenges();
      List<UserChallengeItem> myActive = [];
      List<UserChallengeItem> myCompleted = [];
      try {
        myActive = (await _challengeService.getMyChallenges('active')).cast<UserChallengeItem>();
      } catch (_) {}
      try {
        myCompleted = (await _challengeService.getMyChallenges('completed')).cast<UserChallengeItem>();
      } catch (_) {}

      final Map<int, MyChallengeStatus> merged = {};
      for (final item in myActive) {
        merged[item.challenge.id] = item.toMyChallengeStatus();
      }
      for (final item in myCompleted) {
        merged[item.challenge.id] = item.toMyChallengeStatus();
      }

      if (!mounted) return;
      setState(() {
        allChallenges = catalog.cast<Challenge>();
        dailyChallenges = catalog.where((c) => c.frequency == 'Daily').cast<Challenge>().toList();
        activeChallenges = catalog.where((c) => c.frequency != 'Daily').cast<Challenge>().toList();
        acceptedMap = merged;
        totalXP = catalog.fold(0, (sum, c) => sum + c.xpReward);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading challenges: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: isLoading
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF8B5CF6),
                    ),
                  )
                      : RefreshIndicator(
                    onRefresh: _loadChallenges,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatsCards(),
                            const SizedBox(height: 24),
                            _buildWelcomeMessage(),
                            const SizedBox(height: 24),
                            _buildDailyQuestsHeader(),
                            const SizedBox(height: 16),
                            _buildDailyQuestsList(),
                            const SizedBox(height: 24),
                            _buildTabSelector(),
                            const SizedBox(height: 16),
                            _buildActiveChallengesList(),
                            const SizedBox(height: 24),
                            _buildAdaptiveChallengesSection(),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 100,
            right: 24,
            child: FloatingActionButton(
              onPressed: _loadChallenges,
              backgroundColor: const Color(0xFF8B5CF6),
              child: const Icon(Icons.refresh, size: 32),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: CustomBottomNav(currentIndex: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Challenges',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'Complete quests & earn rewards',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFF97316),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '$streakDays',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.star_rounded, color: Colors.white, size: 24),
                SizedBox(height: 8),
                Text(
                  'Total XP',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  'Earn More!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
                const SizedBox(height: 8),
                const Text(
                  'Rewards',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalXP XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.tips_and_updates_rounded, color: Color(0xFF6366F1)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Complete daily quests to maintain your streak and earn bonus rewards!',
              style: TextStyle(color: Color(0xFF334155), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyQuestsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Daily Quests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Refreshes Daily',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF92400E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyQuestsList() {
    if (dailyChallenges.isEmpty) {
      return const Center(
        child: Text(
          'No daily quests available right now.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }

    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dailyChallenges.length,
        itemBuilder: (context, index) {
          final challenge = dailyChallenges[index];
          return _buildDailyQuestCard(challenge: challenge);
        },
      ),
    );
  }

  Widget _buildDailyQuestCard({required Challenge challenge}) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            challenge.icon ?? "🎯",
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 10),
          Text(
            challenge.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            challenge.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '+${challenge.xpReward} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                challenge.unlockBadge ? Icons.workspace_premium_rounded : Icons.star_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    final tabs = ['Active', 'Daily', 'All'];

    return Row(
      children: tabs.map((tab) {
        final isSelected = selectedTab == tab;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedTab = tab),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Center(
                child: Text(
                  tab,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActiveChallengesList() {
    List<Challenge> challenges;

    if (selectedTab == 'Daily') {
      challenges = dailyChallenges;
    } else if (selectedTab == 'All') {
      challenges = allChallenges;
    } else {
      challenges = activeChallenges;
    }

    if (challenges.isEmpty) {
      return const Center(
        child: Text(
          'No challenges available.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }

    return Column(
      children: challenges.map((challenge) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildChallengeCard(challenge: challenge),
        );
      }).toList(),
    );
  }

  Widget _buildAdaptiveChallengesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: Color(0xFF8B5CF6)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'More adaptive challenges coming soon based on your spending patterns.',
              style: TextStyle(color: Color(0xFF334155), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard({required Challenge challenge}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54, // Reduced from 56
                height: 54, // Reduced from 56
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    challenge.icon ?? "🎯",
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 12), // Reduced from 14
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.name,
                      style: const TextStyle(
                        fontSize: 15, // Reduced from 16
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildBadge(
                          challenge.difficulty,
                          _getDifficultyColor(challenge.difficulty),
                        ),
                        const SizedBox(width: 6), // Reduced from 8
                        _buildBadge(
                          '+${challenge.xpReward} XP',
                          const Color(0xFF10B981),
                        ),
                        if (challenge.unlockBadge) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.workspace_premium_rounded,
                            color: Color(0xFFF59E0B),
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Reduced from 14
          Text(
            challenge.description,
            style: const TextStyle(
              fontSize: 13, // Reduced from 14
              color: Color(0xFF64748B),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (acceptedMap[challenge.id] != null) ...[
            const SizedBox(height: 10),
            _buildProgressSection(acceptedMap[challenge.id]!),
          ],
          const SizedBox(height: 8), // Reduced from 10
          SizedBox(
            width: double.infinity,
            child: _buildChallengeCardButton(challenge),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(MyChallengeStatus s) {
    final target = s.targetValue;
    final hasTarget = target != null && target > 0;
    final fraction = hasTarget ? (s.progress / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    s.status == 'completed'
                        ? Icons.check_circle_rounded
                        : Icons.trending_up_rounded,
                    size: 16,
                    color: s.status == 'completed'
                        ? const Color(0xFF10B981)
                        : const Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    s.status == 'completed' ? 'Completed' : 'In progress',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: s.status == 'completed'
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
              Text(
                hasTarget ? '${s.progress} / $target' : '${s.progress}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          if (hasTarget) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  s.status == 'completed'
                      ? const Color(0xFF10B981)
                      : const Color(0xFF6366F1),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChallengeCardButton(Challenge challenge) {
    final my = acceptedMap[challenge.id];
    final isActive = my?.status == 'active';
    final isCompleted = my?.status == 'completed';
    final isAccepted = isActive || isCompleted;

    String label;
    if (isCompleted) {
      label = 'Completed';
    } else if (isActive) {
      label = 'Accepted';
    } else {
      label = 'Accept Quest';
    }

    return ElevatedButton(
      onPressed: isAccepted
          ? null
          : () async {
              try {
                await _challengeService.acceptQuest(challenge.id);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Challenge "${challenge.name}" accepted!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
                await _loadChallenges();
              } catch (e) {
                debugPrint("Accept quest error: $e");
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Failed to accept quest."),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE2E8F0),
        disabledForegroundColor: const Color(0xFF64748B),
        padding: const EdgeInsets.symmetric(vertical: 9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Reduced from 6
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF10B981);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'hard':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }
}