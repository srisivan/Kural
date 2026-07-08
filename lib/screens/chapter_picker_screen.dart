import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chapter.dart';
import '../providers/kural_providers.dart';

class ChapterPickerScreen extends ConsumerStatefulWidget {
  const ChapterPickerScreen({super.key});

  @override
  ConsumerState<ChapterPickerScreen> createState() =>
      _ChapterPickerScreenState();
}

class _ChapterPickerScreenState extends ConsumerState<ChapterPickerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final chaptersAsync = ref.watch(chaptersProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('Choose a chapter'),
      ),
      body: chaptersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (chapters) {
          final filtered = chapters.where((c) {
            final q = _query.toLowerCase();
            return q.isEmpty ||
                c.name.toLowerCase().contains(q) ||
                c.translation.toLowerCase().contains(q) ||
                c.transliteration.toLowerCase().contains(q);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search chapters...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        child: Text('${c.number}'),
                      ),
                      title: Text(c.translation),
                      subtitle: Text(
                        '${c.name}  •  ${c.sectionName} / ${c.chapterGroupName}',
                      ),
                      trailing: Text('${c.start}–${c.end}'),
                      onTap: () async {
                        await ref
                            .read(todaysKuralProvider.notifier)
                            .selectChapter(c.number);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
