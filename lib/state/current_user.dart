import "package:flutter/foundation.dart";
import "package:zenopay/models/user_model.dart";
import "package:zenopay/services/auth_api.dart";

/// Minimal global store for the currently authenticated user.
///
/// This keeps the app's existing "pages fetch /auth/me themselves" approach,
/// while also exposing XP/level globally and enabling refresh hooks after actions.
class CurrentUser {
  static final ValueNotifier<ZenoUser?> notifier = ValueNotifier<ZenoUser?>(null);

  static ZenoUser? get value => notifier.value;

  /// True when the last refresh() saw streak increase (for transaction/challenge flows to show overlay after pop).
  static bool get streakJustIncreased => _streakJustIncreased;
  static bool _streakJustIncreased = false;
  static void clearStreakJustIncreased() {
    _streakJustIncreased = false;
  }

  static void set(ZenoUser? user) {
    notifier.value = user;
  }

  /// Refreshes `/auth/me` and updates [notifier]. Call after login, transaction, or challenge completion.
  /// Sets [streakJustIncreased] if streak increased (caller can show overlay after navigator pop).
  static Future<ZenoUser?> refresh() async {
    _streakJustIncreased = false;

    final auth = AuthApi();
    final me = await auth.me();

    final dynamic rawUser = me["user"];
    Map<String, dynamic> userJson;
    if (rawUser is Map<String, dynamic>) {
      userJson = rawUser;
    } else if (rawUser is Map) {
      userJson = rawUser.cast<String, dynamic>();
    } else {
      userJson = <String, dynamic>{};
    }

    if (userJson.isEmpty) {
      set(null);
      return null;
    }

    final hadPreviousUser = value != null;
    final oldStreak = value?.profile?.currentStreak ?? 0;
    final user = ZenoUser.fromJson(userJson);
    final newStreak = user.profile?.currentStreak ?? 0;

    set(user);

    if (kDebugMode) {
      if (!hadPreviousUser) {
        debugPrint('Streak: skip overlay (no previous user / first load)');
      } else if (newStreak <= oldStreak) {
        debugPrint('Streak: skip overlay (newStreak=$newStreak <= oldStreak=$oldStreak)');
      } else if (newStreak <= 0) {
        debugPrint('Streak: skip overlay (newStreak=$newStreak)');
      }
    }

    // Only signal when streak actually increased (caller shows overlay after pop so it’s visible)
    if (hadPreviousUser && newStreak > oldStreak && newStreak > 0) {
      _streakJustIncreased = true;
    }

    return user;
  }

  /// Alias for refresh(); use after XP-affecting actions (transaction, challenge complete).
  static Future<ZenoUser?> refreshCurrentUser() => refresh();
}

