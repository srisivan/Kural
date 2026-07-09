import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/card_content.dart';
import '../theme.dart';

/// The verse tile: poem + (optional chapter name) + meta line. Shared by the
/// on-screen view and the shareable card so they look identical.
class PoemTile extends StatelessWidget {
  final CardContent content;
  const PoemTile({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return _Tile(
      child: Column(
        children: [
          Text(
            content.poem,
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
          if (content.chapterName != null) ...[
            Text(
              content.chapterName!,
              textAlign: TextAlign.center,
              style: GoogleFonts.anekTamil(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: Colors.white.withOpacity(0.9),
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
              color: Colors.white.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single interpretation panel (header + text + optional author).
class InterpretationTile extends StatelessWidget {
  final InterpretationEntry entry;
  const InterpretationTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return _Tile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.header,
            style: GoogleFonts.anekTamil(
              fontSize: 15,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            entry.text,
            style: GoogleFonts.anekTamil(
              fontSize: 17,
              height: 1.7,
              color: Colors.white.withOpacity(0.82),
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
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The clean, single-interpretation card rendered off-screen to produce the
/// shared/downloaded image. Uniform for Thirukkural and Aathichudi.
class ContentCard extends StatelessWidget {
  final CardContent content;
  const ContentCard({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBrandBlue,
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
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30),
          PoemTile(content: content),
          const SizedBox(height: 18),
          InterpretationTile(entry: content.selected),
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
