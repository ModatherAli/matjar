import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/network.dart";
import "auth_repository.dart";
import "user.dart";

/// Global session state. Null user means logged out.
final sessionProvider =
    AsyncNotifierProvider<SessionNotifier, AppUser?>(SessionNotifier.new);

class SessionNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    return ref.watch(authRepositoryProvider).restoreSession();
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final payload = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      ref.invalidate(sessionSignalProvider);
      return payload.user;
    });
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final payload = await ref
          .read(authRepositoryProvider)
          .register(email: email, password: password, name: name);
      ref.invalidate(sessionSignalProvider);
      return payload.user;
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
    ref.invalidate(sessionSignalProvider);
  }

  /// Refresh profile after edits (name/phone/role changes).
  Future<void> reload() async {
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).restoreSession(),
    );
  }
}

