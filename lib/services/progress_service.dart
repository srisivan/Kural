import 'package:hive_flutter/hive_flutter.dart';

/// Wraps a single Hive box that tracks reading progress.
/// Keys:
///   selectedChapter      -> int   (global chapter number)
///   lastServedKuralNum   -> int
///   lastServedDate       -> String 'yyyy-MM-dd'
///   lastInterpretation   -> String 'mv' | 'sp' | 'mk'
class ProgressService {
  static const String boxName = 'progress';
  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(boxName);
  }

  int? get selectedChapter => _box.get('selectedChapter') as int?;
  Future<void> setSelectedChapter(int chapterNumber) async {
    await _box.put('selectedChapter', chapterNumber);
    // Starting a new chapter resets progress within it.
    await _box.delete('lastServedKuralNum');
    await _box.delete('lastServedDate');
  }

  /// Updates which chapter we're currently in WITHOUT resetting progress.
  /// Used when the daily flow crosses from one chapter into the next.
  Future<void> syncCurrentChapter(int chapterNumber) async {
    await _box.put('selectedChapter', chapterNumber);
  }

  int? get lastServedKuralNumber => _box.get('lastServedKuralNum') as int?;
  String? get lastServedDate => _box.get('lastServedDate') as String?;
  String? get lastInterpretation => _box.get('lastInterpretation') as String?;

  Future<void> saveServed({
    required int kuralNumber,
    required String date,
    required String interpretationKey,
  }) async {
    await _box.put('lastServedKuralNum', kuralNumber);
    await _box.put('lastServedDate', date);
    await _box.put('lastInterpretation', interpretationKey);
  }
}
