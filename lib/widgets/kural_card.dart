import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/kural_providers.dart';
import '../theme.dart';

/// Author/commentator behind each interpretation key.
const Map<String, String> kInterpretationAuthors = {
  'mv': 'மு. வரதராசன்',
  'mk': 'கலைஞர் மு. கருணாநிதி',
  'sp': 'சாலமன் பாப்பையா',
};

/// The visual card shown on screen AND captured for sharing.
/// Keeping it a standalone widget means the on-screen view and the
/// screenshot are guaranteed to look identical.
class KuralCard extends StatelessWidget {
  final TodaysKural data;

  const KuralCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // The kural itself — the biggest, most emphasized text. Sized so each
    // of the two Tamil lines fits on a single line in the wide tile.
    final kuralStyle = GoogleFonts.anekTamil(
      fontSize: 22,
      height: 1.6,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    );
    // The interpretation — clearly secondary to the kural.
    final interpretationStyle = GoogleFonts.anekTamil(
      fontSize: 17,
      height: 1.7,
      color: Colors.white.withOpacity(0.82),
    );
    final labelStyle = GoogleFonts.anekTamil(
      fontSize: 13,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w600,
      color: Colors.white.withOpacity(0.55),
    );
    // Bold header for the interpretation ("பொருள்").
    final headerStyle = GoogleFonts.anekTamil(
      fontSize: 15,
      letterSpacing: 0.5,
      fontWeight: FontWeight.w700,
      color: Colors.white.withOpacity(0.9),
    );
    // Attribution — who the interpretation is by.
    final attributionStyle = GoogleFonts.anekTamil(
      fontSize: 13,
      fontStyle: FontStyle.italic,
      color: Colors.white.withOpacity(0.6),
    );

    return Container(
      color: kBrandBlue,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------- Kural tile (emphasized) ----------
          _Tile(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  data.kural.combinedLines,
                  textAlign: TextAlign.center,
                  style: kuralStyle,
                ),
                const SizedBox(height: 22),
                Divider(color: Colors.white.withOpacity(0.15), height: 1),
                const SizedBox(height: 16),
                // Chapter title, then chapter number + kural number.
                Text(
                  data.chapter.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.anekTamil(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'அதிகாரம் ${data.chapter.number}   ·   குறள் ${data.kural.number}',
                  textAlign: TextAlign.center,
                  style: labelStyle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // ---------- Interpretation tile ----------
          _Tile(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('பொருள்', style: headerStyle),
                const SizedBox(height: 12),
                Text(
                  data.interpretationText,
                  style: interpretationStyle,
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '— ${kInterpretationAuthors[data.interpretationKey] ?? ''}',
                    style: attributionStyle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single distinct tile: translucent-white fill + border, rounded corners.
class _Tile extends StatelessWidget {
  final Widget child;
  const _Tile({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
      decoration: BoxDecoration(
        color: kTileFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kTileBorder),
      ),
      child: child,
    );
  }
}
