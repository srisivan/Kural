import 'package:flutter_test/flutter_test.dart';
import 'package:thirukkural_app/models/kural.dart';
import 'package:thirukkural_app/models/chapter.dart';

void main() {
  test('Kural.fromJson parses fields and picks interpretation by key', () {
    final k = Kural.fromJson(const {
      'Number': 1,
      'Line1': 'அகர முதல எழுத்தெல்லாம் ஆதி',
      'Line2': 'பகவன் முதற்றே உலகு.',
      'Translation': 'A leads letters...',
      'mv': 'mv-text',
      'sp': 'sp-text',
      'mk': 'mk-text',
    });

    expect(k.number, 1);
    expect(k.combinedLines, contains('\n'));
    expect(k.interpretation('sp'), 'sp-text');
    expect(k.interpretation('unknown'), 'mv-text'); // falls back to mv
  });

  test('Chapter.parseNested flattens the nested structure in kural order', () {
    final chapters = Chapter.parseNested(const {
      'section': {
        'detail': [
          {
            'translation': 'Virtue',
            'chapterGroup': {
              'detail': [
                {
                  'name': 'பாயிரவியல்',
                  'chapters': {
                    'detail': [
                      {
                        'number': 1,
                        'name': 'கடவுள் வாழ்த்து',
                        'translation': 'The Praise of God',
                        'transliteration': 'Katavul Vaazhththu',
                        'start': 1,
                        'end': 10,
                      },
                    ],
                  },
                },
              ],
            },
          },
        ],
      },
    });

    expect(chapters, hasLength(1));
    expect(chapters.first.number, 1);
    expect(chapters.first.start, 1);
    expect(chapters.first.end, 10);
    expect(chapters.first.sectionName, 'Virtue');
  });
}
