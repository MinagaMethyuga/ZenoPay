import 'package:flutter/material.dart';
import 'package:zenopay/Components/CustomBottomNav.dart';
import 'package:zenopay/models/challenge_model.dart';
import 'package:zenopay/services/challenge_service.dart';


class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  final ChallengeService _challengeService = ChallengeService();

  /// From GET /api/challenges/for-you
  List<ForYouAcceptedItem> acceptedChallenges = [];
  List<ForYouAvailableItem> availableChallenges = [];
  List<ForYouAvailableItem> dailyChallenges = [];
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
      final response = await _challengeService.getChallengesForYou();
      if (!mounted) return;
      setState(() {
        acceptedChallenges = response.accepted;
        availableChallenges = response.available;
        dailyChallenges = response.available.where((c) => c.frequency == 'daily').toList();
        totalXP = response.accepted.fold(0, (sum, c) => sum + c.rewardPoints);
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
                            _buildSectionHeader('Your challenges', Icons.emoji_events_rounded),
                            const SizedBox(height: 12),
                            _buildAcceptedChallengesList(),
                            const SizedBox(height: 24),
                            _buildSectionHeader('Available to accept', Icons.add_task_rounded),
                            const SizedBox(height: 12),
                            _buildAvailableChallengesList(),
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
          final item = dailyChallenges[index];
          return _buildDailyQuestCard(item: item);
        },
      ),
    );
  }

  Widget _buildDailyQuestCard({required ForYouAvailableItem item}) {
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
            item.icon ?? "🎯",
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
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
            item.description,
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
                  '+${item.rewardPoints} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.star_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 22, color: const Color(0xFF6366F1)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildAcceptedChallengesList() {
    if (acceptedChallenges.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'No accepted challenges yet. Accept one from below!',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: acceptedChallenges.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildForYouAcceptedCard(item),
        );
      }).toList(),
    );
  }

  Widget _buildAvailableChallengesList() {
    if (availableChallenges.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'No more challenges to accept. Great progress!',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: availableChallenges.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildForYouAvailableCard(item),
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

  Widget _buildForYouAcceptedCard(ForYouAcceptedItem item) {
    final status = MyChallengeStatus(
      status: item.status,
      progress: item.progress,
      targetValue: item.target?.toInt(),
    );
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
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    item.icon ?? "🎯",
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 15,
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
                          item.frequency,
                          const Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 6),
                        _buildBadge(
                          '+${item.rewardPoints} XP',
                          const Color(0xFF10B981),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          _buildProgressSection(status),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: _buildForYouCardButton(
              challengeId: item.id,
              title: item.title,
              isAccepted: true,
              status: item.status,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForYouAvailableCard(ForYouAvailableItem item) {
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
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    item.icon ?? "🎯",
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 15,
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
                          item.frequency,
                          const Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 6),
                        _buildBadge(
                          '+${item.rewardPoints} XP',
                          const Color(0xFF10B981),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: _buildForYouCardButton(
              challengeId: item.id,
              title: item.title,
              isAccepted: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForYouCardButton({
    required int challengeId,
    required String title,
    required bool isAccepted,
    String? status,
  }) {
    String label;
    if (isAccepted) {
      label = status == 'completed' ? 'Completed' : 'Accepted';
    } else {
      label = 'Accept Quest';
    }

    return ElevatedButton(
      onPressed: isAccepted
          ? null
          : () async {
              try {
                await _challengeService.acceptQuest(challengeId);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Challenge "$title" accepted!'),
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

  Widget _buildProgressSection(MyChallengeStatus s) {
    final target = s.targetValue;
    final hasTarget = target != null && target > 0;
    final fraction = hasTarget ? (s.progress / target).clamp(0.0, 1.0) : 0.0;
    final isCompleted = s.status == 'completed';

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
                    isCompleted ? Icons.check_circle_rounded : Icons.trending_up_rounded,
                    size: 16,
                    color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isCompleted ? 'Completed' : 'In progress',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF6366F1),
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
                  isCompleted ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                ),
              ),
            ),
          ],
        ],
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