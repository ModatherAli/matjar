import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../core/models.dart";
import "../../core/widgets.dart";
import "admin_repository.dart";

/// Admin user management: search, role filter, role change, activate/disable.
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _search = TextEditingController();
  String _searchValue = "";
  String _role = "ALL";

  String get _key => "$_searchValue|$_role|1";

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(adminUsersProvider(_key));
  }

  Future<void> _changeRole(AdminUserAccount account) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text("Role · ${account.email}"),
        children: [
          for (final role in const ["USER", "ADMIN"])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, role),
              child: Text(
                role,
                style: TextStyle(
                  fontWeight:
                      account.role == role ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
        ],
      ),
    );
    if (selected == null || !mounted) {
      return;
    }
    try {
      await ref.read(adminRepositoryProvider).setUserRole(account.id, selected);
      _refresh();
      if (mounted) {
        showError(context, "${account.email} is now $selected.");
      }
    } catch (e) {
      if (mounted) {
        showError(context, e.toString());
      }
    }
  }

  Future<void> _toggleActive(AdminUserAccount account) async {
    try {
      await ref
          .read(adminRepositoryProvider)
          .setUserActive(account.id, !account.isActive);
      _refresh();
    } catch (e) {
      if (mounted) {
        showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(adminUsersProvider(_key));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Users")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              controller: _search,
              onChanged: (value) {
                setState(() => _searchValue = value.trim());
                _refresh();
              },
              decoration: const InputDecoration(
                hintText: "Search users…",
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final value in const ["ALL", "USER", "ADMIN"])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(value.toLowerCase()),
                      selected: _role == value,
                      onSelected: (_) {
                        setState(() => _role = value);
                        _refresh();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: page.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () => _refresh(),
              ),
              data: (result) => ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: result.items.length,
                itemBuilder: (context, index) {
                  final account = result.items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      title: Text(
                        account.email,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "${account.name} · ${account.role.toLowerCase()} · "
                        "${account.isActive ? "active" : "disabled"}",
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == "role") {
                            _changeRole(account);
                          } else if (value == "toggle") {
                            _toggleActive(account);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: "role",
                            child: Text("Change role"),
                          ),
                          PopupMenuItem(
                            value: "toggle",
                            child: Text(
                              account.isActive ? "Disable" : "Enable",
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}