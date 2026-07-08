import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/kural_providers.dart';
import '../theme.dart';

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
      backgroundColor: kBrandBlue,
      appBar: AppBar(
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Choose a chapter'),
      ),
      body: chaptersAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, st) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Colors.white70)),
        ),
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
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: 'Search chapters...',
                    hintStyle:
                        TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.search,
                        color: Colors.white.withOpacity(0.7)),
                    filled: true,
                    fillColor: kTileFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: kTileBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: kTileBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: Colors.white.withOpacity(0.5)),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: kTileFill,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kTileBorder),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: Colors.white,
                          foregroundColor: kBrandBlue,
                          child: Text(
                            '${c.number}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        title: Text(
                          c.name,
                          style: GoogleFonts.tiroTamil(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${c.translation}  •  ${c.sectionName} / ${c.chapterGroupName}',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12.5),
                          ),
                        ),
                        trailing: Text(
                          '${c.start}–${c.end}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12),
                        ),
                        onTap: () async {
                          await ref
                              .read(todaysKuralProvider.notifier)
                              .selectChapter(c.number);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      ),
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
