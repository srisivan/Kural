import 'package:flutter/material.dart';

/// Brand blue used across the app — Thirukkural screens and app chrome.
const Color kBrandBlue = Color(0xFF0A7FA8);

/// Subtle translucent-white fill/border for the tiles on the brand-blue bg.
/// (Still used by the kural-only chapter screens.)
final Color kTileFill = Colors.white.withOpacity(0.12);
final Color kTileBorder = Colors.white.withOpacity(0.28);

// Aathichudi "manuscript" palette.
const Color kCream = Color(0xFFF1E6CB);
const Color kBrownInk = Color(0xFF4A3418);

/// A per-text colour scheme so Thirukkural (blue/white) and Aathichudi
/// (cream/brown, manuscript-like) look clearly distinct.
class ContentPalette {
  final Color background;
  final Color ink; // primary foreground / text colour
  final Color tileFill;
  final Color tileBorder;
  final Color accent; // filled buttons, avatars
  final Color onAccent; // text/icons on [accent]

  const ContentPalette({
    required this.background,
    required this.ink,
    required this.tileFill,
    required this.tileBorder,
    required this.accent,
    required this.onAccent,
  });

  Color inkA(double opacity) => ink.withOpacity(opacity);
}

const ContentPalette kuralPalette = ContentPalette(
  background: kBrandBlue,
  ink: Colors.white,
  tileFill: Color(0x1FFFFFFF), // white @ ~0.12
  tileBorder: Color(0x47FFFFFF), // white @ ~0.28
  accent: Colors.white,
  onAccent: kBrandBlue,
);

const ContentPalette aathiPalette = ContentPalette(
  background: kCream,
  ink: kBrownInk,
  tileFill: Color(0x0F4A3418), // brown @ ~0.06
  tileBorder: Color(0x334A3418), // brown @ ~0.20
  accent: kBrownInk,
  onAccent: kCream,
);

ContentPalette paletteFor(bool aathichudi) =>
    aathichudi ? aathiPalette : kuralPalette;
