import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/global_providers.dart';
import '../../../core/widgets/async_value_widget.dart';
import 'profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileFutureProvider);
    final badges = ref.watch(badgeListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: AsyncValueWidget(
        value: profile,
        builder: (data) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage:
                        data.avatarUrl != null ? NetworkImage(data.avatarUrl!) : null,
                    child: data.avatarUrl == null
                        ? Text(data.username?.substring(0, 1) ?? '?')
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.username ?? 'Tanpa Nama',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text('Pohon level ${data.currentTreeLevel}'),
                      Text('${data.totalPoints} poin'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Badge',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              AsyncValueWidget(
                value: badges,
                builder: (items) {
                  if (items.isEmpty) {
                    return const Text('Belum ada badge.');
                  }
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: items
                        .map(
                          (badge) => Chip(
                            avatar: const Icon(Icons.emoji_events, size: 18),
                            label: Text(badge.badgeName),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
