import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chapter.dart';
import '../providers/kural_providers.dart';
import '../theme.dart';
import 'kural_detail_screen.dart';

/// Lists every kural within a chapter (scrollable). Tapping one opens its
/// detail page. Read-only — does not affect daily progress.
class ChapterKuralsScreen extends ConsumerWidget {
  final Chapter chapter;
  const ChapterKuralsScreen({super.key, required this.chapter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kuralsAsync = ref.watch(kuralsProvider);

    return Scaffold(
      backgroundColor: kBrandBlue,
      appBar: AppBar(
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(chapter.name, style: GoogleFonts.anekTamil()),
      ),
      body: kuralsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, st) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Colors.white70)),
        ),
        data: (kurals) {
          final inChapter = kurals
              .where((k) => k.number >= chapter.start && k.number <= chapter.end)
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: inChapter.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // Chapter header.
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${chapter.translation}  ·  அதிகாரம் ${chapter.number}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${chapter.sectionName} / ${chapter.chapterGroupName}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              final k = inChapter[index - 1];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: kTileFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kTileBorder),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.white,
                    foregroundColor: kBrandBlue,
                    child: Text('${k.number}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  title: Text(
                    '${k.line1}\n${k.line2}',
                    style: GoogleFonts.anekTamil(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => KuralDetailScreen(kuralNumber: k.number),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
