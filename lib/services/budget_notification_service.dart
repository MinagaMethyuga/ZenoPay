import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zenopay/models/budget_model.dart';
import 'package:zenopay/services/budget_service.dart';

/// Service to handle budget warning notifications.
/// Sends notifications when budgets are close to being exceeded.
class BudgetNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  
  // Cooldown: Only send notification once per category per day
  static const Duration _notificationCooldown = Duration(hours: 12);
  // Max notifications per day across all categories
  static const int _maxNotificationsPerDay = 3;

  /// Initialize the notification service.
  /// Call this once when the app starts.
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );

    // Request permissions for Android 13+
    if (androidSettings is AndroidInitializationSettings) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  /// Check budgets and send notifications if needed.
  /// Call this after transactions are added or when the app opens.
  /// Only checks expenses, not income transactions.
  static Future<void> checkBudgetsAndNotify(
    BudgetState budget,
    List<Map<String, dynamic>> transactions,
  ) async {
    if (!_initialized) {
      await initialize();
    }

    final daysLeft = BudgetService.daysLeftInMonth;
    if (daysLeft <= 0) return; // Month ended, no need to notify

    // Only check expense transactions
    final expenseTransactions = transactions
        .where((t) => (t['type'] ?? '').toString() == 'expense')
        .toList();
    
    if (expenseTransactions.isEmpty) return; // No expenses, no need to check

    final spentByCategory = BudgetService.spentByCategoryThisMonth(expenseTransactions);
    
    // Check how many notifications we've sent today
    int notificationsSent = await _getNotificationsSentToday();
    if (notificationsSent >= _maxNotificationsPerDay) {
      return; // Already sent max notifications today
    }

    // Check each budget category
    for (final category in budget.categories) {
      // Stop if we've reached max notifications
      if (notificationsSent >= _maxNotificationsPerDay) {
        break;
      }

      // Check if we've already notified for this category recently
      if (await _hasRecentNotification(category.categoryName)) {
        continue; // Skip if notified recently
      }

      final spent = BudgetService.spentForBudgetCategory(
        spentByCategory,
        category.categoryName,
      );
      final remaining = category.monthlyLimit - spent;
      final double dailyAllowance = daysLeft > 0 ? remaining / daysLeft : 0.0;

      // Calculate if we're in a warning state
      // Warning triggers when:
      // 1. User is spending too fast - remaining budget is less than what they need
      //    for the remaining days based on their current spending rate
      // 2. Example: 5000 budget, 500 remaining, 5 days left = spending too fast
      // 3. OR budget is exceeded
      
      final isOverBudget = remaining < 0;
      
      // Calculate expected daily spending rate (monthly limit / 30 days)
      final expectedDailySpending = category.monthlyLimit / 30;
      
      // Calculate if remaining budget is insufficient for remaining days
      // If daily allowance is less than expected daily spending, we're spending too fast
      final isSpendingTooFast = remaining > 0 && 
          daysLeft > 0 && 
          dailyAllowance < expectedDailySpending * 0.7; // 70% threshold for warning
      
      // Also warn if remaining is very low relative to monthly limit
      final isLowRemaining = remaining > 0 && 
          remaining < category.monthlyLimit * 0.15 && 
          daysLeft > 0;

      if (isOverBudget) {
        final sent = await _sendBudgetWarning(
          categoryName: category.categoryName,
          remaining: remaining.abs(),
          daysLeft: daysLeft,
          dailyAllowance: 0,
          isOverBudget: true,
        );
        if (sent) {
          notificationsSent++;
        }
      } else if (isSpendingTooFast || isLowRemaining) {
        final sent = await _sendBudgetWarning(
          categoryName: category.categoryName,
          remaining: remaining,
          daysLeft: daysLeft,
          dailyAllowance: dailyAllowance,
          isOverBudget: false,
        );
        if (sent) {
          notificationsSent++;
        }
      }
    }
  }

  /// Check if we've sent a notification for this category recently (within cooldown period).
  static Future<bool> _hasRecentNotification(String categoryName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'budget_notif_${categoryName}_last_sent';
    final lastSentMillis = prefs.getInt(key);
    
    if (lastSentMillis == null) return false;
    
    final lastSent = DateTime.fromMillisecondsSinceEpoch(lastSentMillis);
    final now = DateTime.now();
    final timeSinceLastNotification = now.difference(lastSent);
    
    return timeSinceLastNotification < _notificationCooldown;
  }

  /// Get count of notifications sent today.
  static Future<int> _getNotificationsSentToday() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = 'budget_notif_count_${_getTodayKey()}';
    return prefs.getInt(todayKey) ?? 0;
  }

  /// Increment notification count for today.
  static Future<void> _incrementNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = 'budget_notif_count_${_getTodayKey()}';
    final current = await _getNotificationsSentToday();
    await prefs.setInt(todayKey, current + 1);
  }

  /// Get a unique key for today (YYYY-MM-DD format).
  static String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Send a budget warning notification.
  /// Returns true if notification was sent, false if it was skipped.
  static Future<bool> _sendBudgetWarning({
    required String categoryName,
    required double remaining,
    required int daysLeft,
    required double dailyAllowance,
    required bool isOverBudget,
  }) async {
    // Check cooldown
    if (await _hasRecentNotification(categoryName)) {
      return false; // Skip if notified recently
    }

    final title = isOverBudget
        ? '⚠️ Budget Exceeded: $categoryName'
        : '💰 Budget Alert: $categoryName';

    final body = isOverBudget
        ? 'You\'ve exceeded your $categoryName budget by Rs ${remaining.toStringAsFixed(0)}. Be careful with spending!'
        : 'You have Rs ${remaining.toStringAsFixed(0)} left for $categoryName with $daysLeft days remaining. That\'s about Rs ${dailyAllowance.toStringAsFixed(0)} per day.';

    const androidDetails = AndroidNotificationDetails(
      'budget_warnings',
      'Budget Warnings',
      channelDescription: 'Notifications when budgets are close to being exceeded',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use category name hash as ID to avoid duplicate notifications for same category
    final notificationId = categoryName.hashCode.abs() % 2147483647;

    await _notifications.show(
      notificationId,
      title,
      body,
      details,
    );

    // Record that we sent this notification
    final prefs = await SharedPreferences.getInstance();
    final key = 'budget_notif_${categoryName}_last_sent';
    await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
    await _incrementNotificationCount();

    return true;
  }

  /// Cancel all budget notifications.
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
