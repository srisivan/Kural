import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/kural.dart';
import '../models/chapter.dart';
import '../models/aathichudi.dart';

class DataService {
  List<Kural>? _kurals;
  List<Chapter>? _chapters;
  List<Aathichudi>? _aathichudi;

  Future<List<Kural>> loadKurals() async {
    if (_kurals != null) return _kurals!;
    final raw = await rootBundle.loadString('assets/data/thirukkural.json');
    final decoded = json.decode(raw);
    // File is either a bare list or wrapped as {"kural": [...]}.
    final List<dynamic> jsonList =
        decoded is Map ? decoded['kural'] as List<dynamic> : decoded as List<dynamic>;
    _kurals = jsonList
        .map((e) => Kural.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    return _kurals!;
  }

  Future<List<Chapter>> loadChapters() async {
    if (_chapters != null) return _chapters!;
    final raw = await rootBundle.loadString('assets/data/detail.json');
    final decoded = json.decode(raw);
    // Root JSON is a list containing one object with "tamil" + "section".
    final Map<String, dynamic> root =
        decoded is List ? decoded.first as Map<String, dynamic> : decoded;
    _chapters = Chapter.parseNested(root);
    return _chapters!;
  }

  Future<List<Aathichudi>> loadAathichudi() async {
    if (_aathichudi != null) return _aathichudi!;
    final raw = await rootBundle.loadString('assets/data/aathicudi.json');
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final List<dynamic> list = decoded['athisudi'] as List<dynamic>;
    _aathichudi = list
        .map((e) => Aathichudi.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    return _aathichudi!;
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
