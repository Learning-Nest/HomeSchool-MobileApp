import 'package:homeschooling/models/activity.dart';
import 'package:homeschooling/models/json.dart';

/// An education board (CBSE, ICSE, ...). Boards are data on the server, never hard-coded here.
class Board {
  const Board({required this.code, required this.name});

  final String code;
  final String name;

  factory Board.fromJson(Map<String, dynamic> j) => Board(code: reqString(j, 'code'), name: reqString(j, 'name'));
}

/// A textbook of one board, class and subject (`GET /v1/curriculum/books`).
class Book {
  const Book({
    required this.code,
    required this.boardCode,
    required this.grade,
    required this.subjectCode,
    required this.title,
    required this.lessonCount,
    this.publisher,
    this.editionYear,
  });

  final String code;
  final String boardCode;
  final String grade;
  final String subjectCode;
  final String title;
  final int lessonCount;
  final String? publisher;
  final int? editionYear;

  factory Book.fromJson(Map<String, dynamic> j) => Book(
        code: reqString(j, 'code'),
        boardCode: reqString(j, 'board_code'),
        grade: optString(j, 'grade') ?? '',
        subjectCode: optString(j, 'subject_code') ?? '',
        title: reqString(j, 'title'),
        lessonCount: optInt(j, 'lesson_count') ?? 0,
        publisher: optString(j, 'publisher'),
        editionYear: optInt(j, 'edition_year'),
      );

  /// "Class 5 · Marigold 5".
  String get label => grade.isEmpty ? title : 'Class $grade · $title';
}

/// One textbook a child is working through (`GET /v1/children/{id}/books`).
class ChildBook {
  const ChildBook({
    required this.book,
    required this.unlockedThrough,
    required this.lessonsTotal,
    required this.lessonsComplete,
    required this.canUnlockNext,
  });

  final Book book;
  final int unlockedThrough;
  final int lessonsTotal;
  final int lessonsComplete;
  final bool canUnlockNext;

  factory ChildBook.fromJson(Map<String, dynamic> j) => ChildBook(
        book: Book.fromJson(asJsonMap(j['book'], 'book')),
        unlockedThrough: optInt(j, 'unlocked_through') ?? 0,
        lessonsTotal: optInt(j, 'lessons_total') ?? 0,
        lessonsComplete: optInt(j, 'lessons_complete') ?? 0,
        canUnlockNext: boolOr(j, 'can_unlock_next'),
      );
}

/// How far a child has got with one activity in a lesson.
enum PathStatus { notStarted, attempted, passed }

PathStatus _pathStatus(String? s) {
  switch (s) {
    case 'passed':
      return PathStatus.passed;
    case 'attempted':
      return PathStatus.attempted;
    default:
      return PathStatus.notStarted;
  }
}

class PathActivity {
  const PathActivity({
    required this.id,
    required this.title,
    required this.durationMin,
    required this.status,
    required this.locked,
    this.bestScore,
  });

  final String id;
  final String title;
  final int durationMin;
  final PathStatus status;
  final bool locked;
  final double? bestScore;

  factory PathActivity.fromJson(Map<String, dynamic> j) => PathActivity(
        id: reqString(j, 'id'),
        title: reqString(j, 'title'),
        durationMin: optInt(j, 'duration_min') ?? 0,
        status: _pathStatus(optString(j, 'status')),
        locked: boolOr(j, 'locked'),
        bestScore: optDouble(j, 'best_score'),
      );
}

enum LessonState { locked, open, complete }

LessonState _lessonState(String? s) {
  switch (s) {
    case 'complete':
      return LessonState.complete;
    case 'open':
      return LessonState.open;
    default:
      return LessonState.locked;
  }
}

class PathLesson {
  const PathLesson({
    required this.position,
    required this.title,
    required this.state,
    required this.activityCount,
    required this.activities,
    this.label,
  });

  final int position;
  final String title;
  final String? label;
  final LessonState state;
  final int activityCount;
  final List<PathActivity> activities;

  factory PathLesson.fromJson(Map<String, dynamic> j) => PathLesson(
        position: reqInt(j, 'position'),
        title: reqString(j, 'title'),
        label: optString(j, 'label'),
        state: _lessonState(optString(j, 'state')),
        activityCount: optInt(j, 'activity_count') ?? 0,
        activities: mapList<PathActivity>(j['activities'], PathActivity.fromJson),
      );

  /// "Unit 1 · A Happy Child" or just the title.
  String get heading => label == null || label!.isEmpty ? title : '$label · $title';
}

/// A child's path through one textbook (`GET /v1/children/{id}/books/{code}/path`).
class BookPath {
  const BookPath({
    required this.book,
    required this.unlockedThrough,
    required this.passScore,
    required this.canUnlockNext,
    required this.lessons,
    this.nextLessonPosition,
  });

  final Book book;
  final int unlockedThrough;
  final double passScore;
  final int? nextLessonPosition;
  final bool canUnlockNext;
  final List<PathLesson> lessons;

  factory BookPath.fromJson(Map<String, dynamic> j) => BookPath(
        book: Book.fromJson(asJsonMap(j['book'], 'book')),
        unlockedThrough: optInt(j, 'unlocked_through') ?? 0,
        passScore: optDouble(j, 'pass_score') ?? 0.6,
        nextLessonPosition: optInt(j, 'next_lesson_position'),
        canUnlockNext: boolOr(j, 'can_unlock_next'),
        lessons: mapList<PathLesson>(j['lessons'], PathLesson.fromJson),
      );

  /// True when there is a lesson left to unlock, finished or not.
  bool get hasMoreLessons => nextLessonPosition != null;
}

/// An activity the child can do now, in textbook order (`GET /v1/children/{id}/next-up`).
class NextUpItem {
  const NextUpItem({
    required this.activity,
    required this.bookCode,
    required this.lessonPosition,
    required this.lessonTitle,
    required this.attempted,
  });

  final ActivitySummary activity;
  final String bookCode;
  final int lessonPosition;
  final String lessonTitle;

  /// Finished before but below the pass score: "try again" rather than "start".
  final bool attempted;

  factory NextUpItem.fromJson(Map<String, dynamic> j) => NextUpItem(
        activity: ActivitySummary.fromJson(j),
        bookCode: reqString(j, 'book_code'),
        lessonPosition: reqInt(j, 'lesson_position'),
        lessonTitle: optString(j, 'lesson_title') ?? '',
        attempted: optString(j, 'status') == 'attempted',
      );
}
