import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chapter.dart';
import '../providers/kural_providers.dart';
import '../theme.dart';
import 'chapter_kurals_screen.dart';
import 'kural_detail_screen.dart';

/// The (supplementary) knowledgebase browser: browse chapters, open any
/// kural, jump to a kural by number, or get a random one. Read-only — never
/// touches the daily progress.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _numberController = TextEditingController();
  final Random _random = Random();

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openKural(int number) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => KuralDetailScreen(kuralNumber: number),
    ));
  }

  void _openChapter(Chapter chapter) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChapterKuralsScreen(chapter: chapter),
    ));
  }

  void _jumpToNumber(int total) {
    final text = _numberController.text.trim();
    final n = int.tryParse(text);
    if (n == null || n < 1 || n > total) {
      _snack('Enter a kural number between 1 and $total');
      return;
    }
    FocusScope.of(context).unfocus();
    _openKural(n);
  }

  @override
  Widget build(BuildContext context) {
    final chaptersAsync = ref.watch(chaptersProvider);
    final kuralsAsync = ref.watch(kuralsProvider);
    final total = kuralsAsync.valueOrNull?.length ?? 1330;

    return Scaffold(
      backgroundColor: kBrandBlue,
      appBar: AppBar(
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('ஆராய்', style: GoogleFonts.anekTamil()),
      ),
      body: chaptersAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (e, st) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: Colors.white70)),
        ),
        data: (chapters) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  children: [
                    // Surprise me.
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.casino_outlined,
                            label: 'Random kural',
                            onTap: () => _openKural(_random.nextInt(total) + 1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.shuffle,
                            label: 'Random chapter',
                            onTap: () => _openChapter(
                                chapters[_random.nextInt(chapters.length)]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Jump to a kural number.
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _numberController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            style: const TextStyle(color: Colors.white),
                            cursorColor: Colors.white,
                            onSubmitted: (_) => _jumpToNumber(total),
                            decoration: InputDecoration(
                              hintText: 'Go to kural # (1–$total)',
                              hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5)),
                              prefixIcon: Icon(Icons.tag,
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
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.5)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: kBrandBlue,
                            ),
                            onPressed: () => _jumpToNumber(total),
                            child: const Text('Go'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          'Chapters',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  itemCount: chapters.length,
                  itemBuilder: (context, index) {
                    final c = chapters[index];
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
                          child: Text('${c.number}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                        title: Text(
                          c.name,
                          style: GoogleFonts.anekTamil(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${c.translation}  ·  குறள் ${c.start}–${c.end}',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12.5),
                          ),
                        ),
                        trailing: Icon(Icons.chevron_right,
                            color: Colors.white.withOpacity(0.5)),
                        onTap: () => _openChapter(c),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kTileFill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kTileBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
