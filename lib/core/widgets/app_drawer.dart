import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings/theme_provider.dart';
import '../../features/auth/application/auth_providers.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const ListTile(
                    title: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Divider(),

                  // Theme
                  ListTile(
                    leading: const Icon(Icons.brightness_6),
                    title: const Text('Theme'),
                    subtitle: Text(_label(themeMode)),
                    onTap: () => showModalBottomSheet(
                      context: context,
                      showDragHandle: true,
                      builder: (_) => _ThemeSheet(current: themeMode),
                    ),
                  ),

                  const Divider(),

                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Log out'),
                    onTap: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Log out?'),
                          content: const Text(
                            'You will need to sign in again to access your data.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              child: const Text('Log out'),
                            ),
                          ],
                        ),
                      );

                      if (ok != true) return;

                      Navigator.of(context).pop();

                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Version 1.2.2 (122)',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _label(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}

class _ThemeSheet extends ConsumerWidget {
  const _ThemeSheet({required this.current});
  final ThemeMode current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RadioListTile<ThemeMode>(
          value: ThemeMode.system,
          groupValue: current,
          title: const Text('System'),
          onChanged: (v) => _set(ref, context, v),
        ),
        RadioListTile<ThemeMode>(
          value: ThemeMode.light,
          groupValue: current,
          title: const Text('Light'),
          onChanged: (v) => _set(ref, context, v),
        ),
        RadioListTile<ThemeMode>(
          value: ThemeMode.dark,
          groupValue: current,
          title: const Text('Dark'),
          onChanged: (v) => _set(ref, context, v),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _set(WidgetRef ref, BuildContext context, ThemeMode? v) {
    if (v == null) return;
    ref.read(themeModeProvider.notifier).state = v;
    Navigator.of(context).pop();
  }
}
