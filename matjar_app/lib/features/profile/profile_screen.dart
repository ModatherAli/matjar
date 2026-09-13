import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../core/theme.dart";
import "../../core/widgets.dart";
import "../auth/session.dart";
import "profile_repository.dart";

/// Profile: update name/phone, change password, sign out, admin entry.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _hydrate(String? name, String? phone) {
    if (_name.text.isEmpty && name != null) {
      _name.text = name;
    }
    if (_phone.text.isEmpty && phone != null) {
      _phone.text = phone;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateMe(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
          );
      await ref.read(sessionProvider.notifier).reload();
      if (mounted) {
        showError(context, "Profile updated.");
      }
    } catch (e) {
      if (mounted) {
        showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: current,
              obscureText: true,
              decoration: const InputDecoration(hintText: "Current password"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: "New password (min 8 characters)",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Update"),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref.read(profileRepositoryProvider).changePassword(
            currentPassword: current.text,
            newPassword: next.text,
          );
      if (mounted) {
        showError(context, "Password updated.");
      }
    } catch (e) {
      if (mounted) {
        showError(context, e.toString());
      }
    }
  }

  Future<void> _signOut() async {
    await ref.read(sessionProvider.notifier).logout();
    if (mounted) {
      context.go("/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: session.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(sessionProvider),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          _hydrate(user.name, user.phone);
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                "MEMBER",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: MatjarColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                user.name,
                style: theme.textTheme.displaySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(user.email, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              const GoldDivider(),
              const SizedBox(height: 24),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: "Phone"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      )
                    : const Text("Save profile"),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _changePassword,
                icon: const Icon(Icons.lock_outline),
                label: const Text("Change password"),
              ),
              if (user.isAdmin) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push("/admin"),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text("Open Admin Atelier"),
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _signOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
                icon: const Icon(Icons.logout),
                label: const Text("Sign out"),
              ),
            ],
          );
        },
      ),
    );
  }
}