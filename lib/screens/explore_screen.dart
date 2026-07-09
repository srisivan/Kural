import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/card_content.dart';
import '../models/chapter.dart';
import '../models/kural.dart';
import '../models/aathichudi.dart';
import '../providers/kural_providers.dart';
import '../theme.dart';
import 'chapter_kurals_screen.dart';
import 'content_detail_screen.dart';

/// The (supplementary) knowledgebase browser. Mode-aware: browses chapters for
/// Thirukkural, or a flat list for Aathichudi. Read-only — never touches the
/// daily progress.
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

  void _openKural(List<Kural> kurals, List<Chapter> chapters, int number) {
    final kural = kurals.firstWhere((k) => k.number == number);
    final chapter =
        chapters.firstWhere((c) => number >= c.start && number <= c.end);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          ContentDetailScreen(content: CardContent.fromKural(kural, chapter)),
    ));
  }

  void _openAathi(List<Aathichudi> list, int number) {
    final item = list.firstWhere((a) => a.number == number);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          ContentDetailScreen(content: CardContent.fromAathichudi(item)),
    ));
  }

  int? _parseJump(int total) {
    final n = int.tryParse(_numberController.text.trim());
    if (n == null || n < 1 || n > total) {
      _snack('Enter a number between 1 and $total');
      return null;
    }
    FocusScope.of(context).unfocus();
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(contentModeProvider);
    final isKural = mode == 'kural';

    return Scaffold(
      backgroundColor: kBrandBlue,
      appBar: AppBar(
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(isKural ? 'ஆராய் · திருக்குறள்' : 'ஆராய் · ஆத்திசூடி',
            style: GoogleFonts.anekTamil()),
      ),
      body: isKural ? _buildKural() : _buildAathichudi(),
    );
  }

  // ---- Thirukkural: chapters ----
  Widget _buildKural() {
    final chaptersAsync = ref.watch(chaptersProvider);
    final kuralsAsync = ref.watch(kuralsProvider);

    return chaptersAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (e, st) => _err('$e'),
      data: (chapters) {
        final kurals = kuralsAsync.valueOrNull ?? const [];
        final total = kurals.isEmpty ? 1330 : kurals.length;
        return Column(
          children: [
            _controls(
              jumpHint: 'Go to kural # (1–$total)',
              onSurprise1: kurals.isEmpty
                  ? null
                  : () => _openKural(
                      kurals, chapters, _random.nextInt(total) + 1),
              surprise1Label: 'Random kural',
              surprise1Icon: Icons.casino_outlined,
              onSurprise2: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChapterKuralsScreen(
                    chapter: chapters[_random.nextInt(chapters.length)]),
              )),
              surprise2Label: 'Random chapter',
              surprise2Icon: Icons.shuffle,
              onJump: () {
                final n = _parseJump(total);
                if (n != null && kurals.isNotEmpty) {
                  _openKural(kurals, chapters, n);
                }
              },
              sectionLabel: 'Chapters',
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final c = chapters[index];
                  return _listTile(
                    number: '${c.number}',
                    title: c.name,
                    subtitle:
                        '${c.translation}  ·  குறள் ${c.start}–${c.end}',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ChapterKuralsScreen(chapter: c),
                    )),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ---- Aathichudi: flat list ----
  Widget _buildAathichudi() {
    final listAsync = ref.watch(aathichudiProvider);
    return listAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (e, st) => _err('$e'),
      data: (list) {
        final total = list.length;
        return Column(
          children: [
            _controls(
              jumpHint: 'Go to # (1–$total)',
              onSurprise1: () => _openAathi(list, _random.nextInt(total) + 1),
              surprise1Label: 'Surprise me',
              surprise1Icon: Icons.casino_outlined,
              onSurprise2: null,
              surprise2Label: '',
              surprise2Icon: Icons.shuffle,
              onJump: () {
                final n = _parseJump(total);
                if (n != null) _openAathi(list, n);
              },
              sectionLabel: 'ஆத்திசூடி',
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final a = list[index];
                  return _listTile(
                    number: '${a.number}',
                    title: a.poem,
                    subtitle: a.paraphrase,
                    onTap: () => _openAathi(list, a.number),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _controls({
    required String jumpHint,
    required VoidCallback? onSurprise1,
    required String surprise1Label,
    required IconData surprise1Icon,
    required VoidCallback? onSurprise2,
    required String surprise2Label,
    required IconData surprise2Icon,
    required VoidCallback onJump,
    required String sectionLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: surprise1Icon,
                  label: surprise1Label,
                  onTap: onSurprise1,
                ),
              ),
              if (onSurprise2 != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: surprise2Icon,
                    label: surprise2Label,
                    onTap: onSurprise2,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _numberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  onSubmitted: (_) => onJump(),
                  decoration: InputDecoration(
                    hintText: jumpHint,
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon:
                        Icon(Icons.tag, color: Colors.white.withOpacity(0.7)),
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
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.white, foregroundColor: kBrandBlue),
                  onPressed: onJump,
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
                sectionLabel,
                style: GoogleFonts.anekTamil(
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
    );
  }

  Widget _listTile({
    required String number,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kTileFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kTileBorder),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          foregroundColor: kBrandBlue,
          child: Text(number,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        title: Text(
          title,
          style: GoogleFonts.anekTamil(
              color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.anekTamil(
                      color: Colors.white.withOpacity(0.6), fontSize: 12.5),
                ),
              ),
        trailing:
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5)),
        onTap: onTap,
      ),
    );
  }

  Widget _err(String e) => Center(
        child: Text('Error: $e',
            style: const TextStyle(color: Colors.white70)),
      );
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
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
