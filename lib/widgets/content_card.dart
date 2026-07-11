import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/card_content.dart';
import '../theme.dart';

/// The verse tile: poem + (optional chapter name) + meta line.
class PoemTile extends StatelessWidget {
  final CardContent content;
  final ContentPalette palette;
  const PoemTile({super.key, required this.content, required this.palette});

  @override
  Widget build(BuildContext context) {
    return _Tile(
      palette: palette,
      child: Column(
        children: [
          Text(
            content.poem,
            textAlign: TextAlign.center,
            style: GoogleFonts.anekTamil(
              fontSize: 22,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 22),
          Divider(color: palette.inkA(0.18), height: 1),
          const SizedBox(height: 16),
          if (content.chapterName != null) ...[
            Text(
              content.chapterName!,
              textAlign: TextAlign.center,
              style: GoogleFonts.anekTamil(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: palette.inkA(0.9),
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            content.metaLine,
            textAlign: TextAlign.center,
            style: GoogleFonts.anekTamil(
              fontSize: 13,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: palette.inkA(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single interpretation panel (header + text + optional author). When
/// [dotCount] > 1, a page indicator is drawn inside the tile.
class InterpretationTile extends StatelessWidget {
  final InterpretationEntry entry;
  final ContentPalette palette;
  final int? dotCount;
  final int dotIndex;

  const InterpretationTile({
    super.key,
    required this.entry,
    required this.palette,
    this.dotCount,
    this.dotIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return _Tile(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.header,
            style: GoogleFonts.anekTamil(
              fontSize: 15,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w700,
              color: palette.inkA(0.9),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            entry.text,
            style: GoogleFonts.anekTamil(
              fontSize: 17,
              height: 1.7,
              color: palette.inkA(0.85),
            ),
          ),
          if (entry.author != null) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '— ${entry.author}',
                style: GoogleFonts.anekTamil(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: palette.inkA(0.65),
                ),
              ),
            ),
          ],
          if (dotCount != null && dotCount! > 1) ...[
            const SizedBox(height: 20),
            Center(
                child: _Dots(
                    count: dotCount!, active: dotIndex, palette: palette)),
          ],
        ],
      ),
    );
  }
}

/// Page indicator: highlights the active interpretation.
class _Dots extends StatelessWidget {
  final int count;
  final int active;
  final ContentPalette palette;
  const _Dots(
      {required this.count, required this.active, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final on = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: on ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: on ? palette.ink : palette.inkA(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// The clean, single-interpretation card rendered off-screen to produce the
/// shared/downloaded image.
class ContentCard extends StatelessWidget {
  final CardContent content;
  final ContentPalette palette;
  const ContentCard({super.key, required this.content, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: palette.background,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            content.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.anekTamil(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 30),
          PoemTile(content: content, palette: palette),
          const SizedBox(height: 18),
          InterpretationTile(entry: content.selected, palette: palette),
        ],
      ),
    );
  }
}

/// A single distinct tile: translucent fill + border, rounded corners.
class _Tile extends StatelessWidget {
  final Widget child;
  final ContentPalette palette;
  const _Tile({required this.child, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
      decoration: BoxDecoration(
        color: palette.tileFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.tileBorder),
      ),
      child: child,
    );
  }
}
