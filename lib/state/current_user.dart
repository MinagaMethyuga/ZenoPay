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

  static void set(ZenoUser? user) {
    notifier.value = user;
  }

  /// Refreshes `/auth/me` and updates [notifier]. Call after login, transaction, or challenge completion.
  static Future<ZenoUser?> refresh() async {
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

    final user = ZenoUser.fromJson(userJson);
    set(user);
    return user;
  }

  /// Alias for refresh(); use after XP-affecting actions (transaction, challenge complete).
  static Future<ZenoUser?> refreshCurrentUser() => refresh();
}

