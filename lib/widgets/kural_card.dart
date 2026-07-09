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

/// The kural itself + chapter title + numbers. Shared by the on-screen view
/// and the shareable card so they always look identical.
class KuralTile extends StatelessWidget {
  final TodaysKural view;
  const KuralTile({super.key, required this.view});

  @override
  Widget build(BuildContext context) {
    return _Tile(
      child: Column(
        children: [
          Text(
            view.kural.combinedLines,
            textAlign: TextAlign.center,
            style: GoogleFonts.anekTamil(
              fontSize: 22,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 22),
          Divider(color: Colors.white.withOpacity(0.15), height: 1),
          const SizedBox(height: 16),
          Text(
            view.chapter.name,
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
            'அதிகாரம் ${view.chapter.number}   ·   குறள் ${view.kural.number}',
            textAlign: TextAlign.center,
            style: GoogleFonts.anekTamil(
              fontSize: 13,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single interpretation ("பொருள்" + text + author). Used both as a
/// carousel page on screen and inside the shareable card.
class InterpretationTile extends StatelessWidget {
  final String interpretationKey;
  final String text;
  const InterpretationTile({
    super.key,
    required this.interpretationKey,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return _Tile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'பொருள்',
            style: GoogleFonts.anekTamil(
              fontSize: 15,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: GoogleFonts.anekTamil(
              fontSize: 17,
              height: 1.7,
              color: Colors.white.withOpacity(0.82),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— ${kInterpretationAuthors[interpretationKey] ?? ''}',
              style: GoogleFonts.anekTamil(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The clean, single-interpretation card rendered off-screen to produce the
/// shared/downloaded image. Uses `data.interpretationKey`, so callers pass a
/// [TodaysKural] carrying the interpretation the user landed on.
class KuralCard extends StatelessWidget {
  final TodaysKural data;
  const KuralCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBrandBlue,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KuralTile(view: data),
          const SizedBox(height: 18),
          InterpretationTile(
            interpretationKey: data.interpretationKey,
            text: data.interpretationText,
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
