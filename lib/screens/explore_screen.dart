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

/// Mode-aware knowledgebase browser. Chapters for Thirukkural, a flat list for
/// Aathichudi. The palette follows the active text. Read-only.
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
    final palette = paletteFor(!isKural);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        foregroundColor: palette.ink,
        elevation: 0,
        title: Text(isKural ? 'ஆராய் · திருக்குறள்' : 'ஆராய் · ஆத்திசூடி',
            style: GoogleFonts.anekTamil()),
      ),
      body: isKural ? _buildKural(palette) : _buildAathichudi(palette),
    );
  }

  // ---- Thirukkural: chapters ----
  Widget _buildKural(ContentPalette palette) {
    final chaptersAsync = ref.watch(chaptersProvider);
    final kuralsAsync = ref.watch(kuralsProvider);

    return chaptersAsync.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: palette.ink)),
      error: (e, st) => _err('$e', palette),
      data: (chapters) {
        final kurals = kuralsAsync.valueOrNull ?? const [];
        final total = kurals.isEmpty ? 1330 : kurals.length;
        return Column(
          children: [
            _controls(
              palette: palette,
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
                    palette: palette,
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
  Widget _buildAathichudi(ContentPalette palette) {
    final listAsync = ref.watch(aathichudiProvider);
    return listAsync.when(
      loading: () =>
          Center(child: CircularProgressIndicator(color: palette.ink)),
      error: (e, st) => _err('$e', palette),
      data: (list) {
        final total = list.length;
        return Column(
          children: [
            _controls(
              palette: palette,
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
                    palette: palette,
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
    required ContentPalette palette,
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
                  palette: palette,
                  icon: surprise1Icon,
                  label: surprise1Label,
                  onTap: onSurprise1,
                ),
              ),
              if (onSurprise2 != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    palette: palette,
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
                  style: TextStyle(color: palette.ink),
                  cursorColor: palette.ink,
                  onSubmitted: (_) => onJump(),
                  decoration: InputDecoration(
                    hintText: jumpHint,
                    hintStyle: TextStyle(color: palette.inkA(0.5)),
                    prefixIcon: Icon(Icons.tag, color: palette.inkA(0.7)),
                    filled: true,
                    fillColor: palette.tileFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: palette.tileBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: palette.tileBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: palette.inkA(0.5)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: palette.onAccent),
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
                  color: palette.inkA(0.6),
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
    required ContentPalette palette,
    required String number,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: palette.tileFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.tileBorder),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: palette.accent,
          foregroundColor: palette.onAccent,
          child: Text(number,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        title: Text(
          title,
          style: GoogleFonts.anekTamil(
              color: palette.ink, fontSize: 17, fontWeight: FontWeight.w600),
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
                      color: palette.inkA(0.6), fontSize: 12.5),
                ),
              ),
        trailing: Icon(Icons.chevron_right, color: palette.inkA(0.5)),
        onTap: onTap,
      ),
    );
  }

  Widget _err(String e, ContentPalette palette) => Center(
        child: Text('Error: $e', style: TextStyle(color: palette.inkA(0.7))),
      );
}

class _ActionButton extends StatelessWidget {
  final ContentPalette palette;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ActionButton(
      {required this.palette,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.tileFill,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.tileBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: palette.ink, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: palette.ink,
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
