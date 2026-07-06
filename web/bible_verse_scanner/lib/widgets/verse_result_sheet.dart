import 'package:flutter/material.dart';

import '../models/verse_reference.dart';

/// Bottom sheet listing every verse reference recognized in the last scan,
/// along with its looked-up text from the bundled KJV data.
class VerseResultSheet extends StatelessWidget {
  const VerseResultSheet({super.key, required this.results});

  final List<ScannedVerse> results;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: results.length,
          separatorBuilder: (_, _) => const Divider(height: 32),
          itemBuilder: (context, index) {
            final result = results[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.reference.display,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  result.combinedText,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
