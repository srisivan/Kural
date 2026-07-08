import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/kural.dart';
import '../models/chapter.dart';

class DataService {
  List<Kural>? _kurals;
  List<Chapter>? _chapters;

  Future<List<Kural>> loadKurals() async {
    if (_kurals != null) return _kurals!;
    final raw = await rootBundle.loadString('assets/data/kurals.json');
    final List<dynamic> jsonList = json.decode(raw);
    _kurals = jsonList
        .map((e) => Kural.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    return _kurals!;
  }

  Future<List<Chapter>> loadChapters() async {
    if (_chapters != null) return _chapters!;
    final raw = await rootBundle.loadString('assets/data/chapters.json');
    final decoded = json.decode(raw);
    // Root JSON is a list containing one object with "tamil" + "section".
    final Map<String, dynamic> root =
        decoded is List ? decoded.first as Map<String, dynamic> : decoded;
    _chapters = Chapter.parseNested(root);
    return _chapters!;
  }

  Kural? kuralByNumber(int number) {
    if (_kurals == null) return null;
    try {
      return _kurals!.firstWhere((k) => k.number == number);
    } catch (_) {
      return null;
    }
  }
}
