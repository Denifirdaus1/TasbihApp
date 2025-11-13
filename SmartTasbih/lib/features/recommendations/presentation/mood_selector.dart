import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mood_repository.dart';

class MoodSelector extends ConsumerWidget {
  const MoodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moods = ref.watch(moodOptionsProvider);
    final selected = ref.watch(selectedMoodProvider);
    final recommendations = ref.watch(zikirRecommendationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: moods.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final mood = moods[index];
              final isSelected = mood.id == selected;
              return ChoiceChip(
                selected: isSelected,
                label: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mood.title),
                    Text(
                      mood.subtitle,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
                onSelected: (_) =>
                    ref.read(selectedMoodProvider.notifier).state = mood.id,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        ...recommendations.map(
          (item) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(item.description),
                  const SizedBox(height: 8),
                  Text(
                    item.translation,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
