import 'package:flutter_test/flutter_test.dart';
import 'package:homeschooling/models/textbooks.dart';

const Map<String, dynamic> _bookJson = <String, dynamic>{
  'code': 'cbse-1-english-marigold',
  'board_code': 'CBSE',
  'grade': '1',
  'subject_code': 'ENG',
  'title': 'Marigold 1',
  'publisher': 'NCERT',
  'edition_year': 2024,
  'level_code': 'L2',
  'lesson_count': 2,
};

void main() {
  test('Book reads the catalogue row and labels itself with the class', () {
    final Book b = Book.fromJson(_bookJson);
    expect(b.code, 'cbse-1-english-marigold');
    expect(b.boardCode, 'CBSE');
    expect(b.lessonCount, 2);
    expect(b.label, 'Class 1 · Marigold 1');
  });

  test('ChildBook reads progress', () {
    final ChildBook c = ChildBook.fromJson(<String, dynamic>{
      'book': _bookJson,
      'unlocked_through': 1,
      'lessons_total': 2,
      'lessons_complete': 1,
      'can_unlock_next': true,
    });
    expect(c.lessonsComplete, 1);
    expect(c.canUnlockNext, isTrue);
  });

  test('BookPath reads lessons, states and activity status', () {
    final BookPath p = BookPath.fromJson(<String, dynamic>{
      'book': _bookJson,
      'unlocked_through': 1,
      'pass_score': 0.6,
      'next_lesson_position': 2,
      'can_unlock_next': false,
      'lessons': <Map<String, dynamic>>[
        <String, dynamic>{
          'position': 1,
          'label': 'Unit 1',
          'title': 'A Happy Child',
          'state': 'open',
          'activity_count': 2,
          'activities': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'a1',
              'slug': 'a1',
              'title': 'Alphabet',
              'duration_min': 10,
              'status': 'attempted',
              'best_score': 0.4,
              'locked': false,
            },
            <String, dynamic>{
              'id': 'a2',
              'slug': 'a2',
              'title': 'Sounds',
              'duration_min': 8,
              'status': 'passed',
              'best_score': null,
              'locked': false,
            },
          ],
        },
        <String, dynamic>{
          'position': 2,
          'label': null,
          'title': 'Three Little Pigs',
          'state': 'locked',
          'activity_count': 1,
          'activities': <Map<String, dynamic>>[],
        },
      ],
    });
    expect(p.passScore, 0.6);
    expect(p.hasMoreLessons, isTrue);
    expect(p.lessons[0].state, LessonState.open);
    expect(p.lessons[0].heading, 'Unit 1 · A Happy Child');
    expect(p.lessons[0].activities[0].status, PathStatus.attempted);
    expect(p.lessons[0].activities[0].bestScore, 0.4);
    expect(p.lessons[0].activities[1].status, PathStatus.passed);
    expect(p.lessons[1].state, LessonState.locked);
    expect(p.lessons[1].heading, 'Three Little Pigs');
    expect(p.lessons[1].activities, isEmpty);
  });

  test('BookPath with no lesson left to unlock', () {
    final BookPath p = BookPath.fromJson(<String, dynamic>{
      'book': _bookJson,
      'unlocked_through': 2,
      'pass_score': 0.6,
      'next_lesson_position': null,
      'can_unlock_next': false,
      'lessons': <Map<String, dynamic>>[],
    });
    expect(p.hasMoreLessons, isFalse);
  });

  test('NextUpItem is an activity summary plus where it sits', () {
    final NextUpItem n = NextUpItem.fromJson(<String, dynamic>{
      'id': 'a1',
      'slug': 'alphabet',
      'title': 'Alphabet',
      'summary': null,
      'subject_code': 'ENG',
      'level_from': 'L1',
      'level_to': 'L2',
      'duration_min': 10,
      'materials': <String>[],
      'interest_tags': <String>[],
      'version': 1,
      'book_code': 'cbse-1-english-marigold',
      'lesson_position': 1,
      'lesson_title': 'A Happy Child',
      'status': 'attempted',
    });
    expect(n.activity.title, 'Alphabet');
    expect(n.attempted, isTrue);
    expect(n.lessonPosition, 1);
  });
}
