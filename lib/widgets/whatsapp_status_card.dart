import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/kural_providers.dart';
import '../theme.dart';
import 'kural_card.dart' show kInterpretationAuthors;

/// A self-contained, rectangular kural card sized for a WhatsApp status
/// (4:5 portrait). Rendered off-screen and captured to an image — it is
/// never shown in the app's widget tree, so its sizes are tuned for the
/// fixed [canvasSize] canvas rather than the device screen.
class WhatsAppStatusCard extends StatelessWidget {
  final TodaysKural data;

  const WhatsAppStatusCard({super.key, required this.data});

  /// Logical canvas size; captured at pixelRatio to get the final image.
  static const Size canvasSize = Size(1080, 1350);

  @override
  Widget build(BuildContext context) {
    final kuralStyle = GoogleFonts.anekTamil(
      fontSize: 56,
      height: 1.55,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );
    final chapterStyle = GoogleFonts.anekTamil(
      fontSize: 40,
      fontWeight: FontWeight.w600,
      color: Colors.white.withOpacity(0.9),
    );
    final metaStyle = GoogleFonts.anekTamil(
      fontSize: 30,
      letterSpacing: 1.5,
      fontWeight: FontWeight.w600,
      color: Colors.white.withOpacity(0.6),
    );
    final headerStyle = GoogleFonts.anekTamil(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: Colors.white.withOpacity(0.9),
    );
    final interpretationStyle = GoogleFonts.anekTamil(
      fontSize: 34,
      height: 1.6,
      color: Colors.white.withOpacity(0.85),
    );
    final attributionStyle = GoogleFonts.anekTamil(
      fontSize: 30,
      fontStyle: FontStyle.italic,
      color: Colors.white.withOpacity(0.6),
    );

    return SizedBox.fromSize(
      size: canvasSize,
      child: Container(
        color: kBrandBlue,
        padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 72),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                'திருக்குறள்',
                style: GoogleFonts.anekTamil(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
            // Kural tile.
            _Tile(
              child: Column(
                children: [
                  Text(
                    data.kural.combinedLines,
                    textAlign: TextAlign.center,
                    style: kuralStyle,
                  ),
                  const SizedBox(height: 32),
                  Divider(color: Colors.white.withOpacity(0.15), height: 1),
                  const SizedBox(height: 24),
                  Text(data.chapter.name,
                      textAlign: TextAlign.center, style: chapterStyle),
                  const SizedBox(height: 10),
                  Text(
                    'அதிகாரம் ${data.chapter.number}   ·   குறள் ${data.kural.number}',
                    textAlign: TextAlign.center,
                    style: metaStyle,
                  ),
                ],
              ),
            ),
            // Interpretation tile (capped so a long commentary can't overflow
            // the fixed card; the full text lives on the home screen).
            _Tile(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('பொருள்', style: headerStyle),
                  const SizedBox(height: 20),
                  Text(
                    data.interpretationText,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: interpretationStyle,
                  ),
                  const SizedBox(height: 22),
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
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final Widget child;
  const _Tile({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 48),
      decoration: BoxDecoration(
        color: kTileFill,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: kTileBorder, width: 1.5),
      ),
      child: child,
    );
  }
}
