import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/kural_providers.dart';
import '../theme.dart';

/// The visual card shown on screen AND captured for sharing.
/// Keeping it a standalone widget means the on-screen view and the
/// screenshot are guaranteed to look identical.
class KuralCard extends StatelessWidget {
  final TodaysKural data;

  const KuralCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // The kural itself — the biggest, most emphasized text.
    final kuralStyle = GoogleFonts.tiroTamil(
      fontSize: 27,
      height: 1.7,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    );
    // The interpretation — clearly secondary to the kural.
    final interpretationStyle = GoogleFonts.tiroTamil(
      fontSize: 17,
      height: 1.7,
      color: Colors.white.withOpacity(0.82),
    );
    final labelStyle = GoogleFonts.tiroTamil(
      fontSize: 13,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w600,
      color: Colors.white.withOpacity(0.55),
    );

    return Container(
      color: kDeepBlue,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
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
                  style: GoogleFonts.tiroTamil(
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
                Text('விளக்கம்', style: labelStyle),
                const SizedBox(height: 12),
                Text(
                  data.interpretationText,
                  style: interpretationStyle,
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
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: kTileFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kTileBorder),
      ),
      child: child,
    );
  }
}
