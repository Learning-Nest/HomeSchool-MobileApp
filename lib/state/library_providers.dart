import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homeschooling/core/api_exception.dart';
import 'package:homeschooling/data/catalogue_repository.dart';
import 'package:homeschooling/models/library.dart';
import 'package:homeschooling/state/environment.dart';

class LibraryState {
  const LibraryState({
    this.childId,
    this.subject,
    this.query = '',
    this.results = const <LibraryActivity>[],
    this.loading = false,
    this.loadingMore = false,
    this.hasMore = false,
    this.error,
  });

  final String? childId;
  final String? subject;
  final String query;
  final List<LibraryActivity> results;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final ApiException? error;

  /// A subject and a child have been chosen, so there is a list (possibly empty) to show.
  bool get hasSelection => childId != null && subject != null;
}

/// The Activity library for one child and one subject: nothing is loaded until both are chosen.
class LibraryNotifier extends Notifier<LibraryState> {
  @override
  LibraryState build() => const LibraryState();

  AppEnvironment get _env => ref.read(environmentProvider);

  /// Shows [subject]'s activities for [childId] (page one). Pass the same values again to reload.
  Future<void> show({required String? childId, required String? subject, String query = ''}) async {
    if (childId == null || subject == null) {
      state = LibraryState(childId: childId, subject: subject, query: query);
      return;
    }
    state = LibraryState(childId: childId, subject: subject, query: query, loading: true);
    await _fetch(offset: 0);
  }

  /// Reloads what is on screen (for example after adding something to the plan).
  Future<void> refresh() async {
    if (!state.hasSelection) return;
    await _fetch(offset: 0);
  }

  Future<void> loadMore() async {
    if (!state.hasSelection || !state.hasMore || state.loading || state.loadingMore) return;
    state = LibraryState(
      childId: state.childId,
      subject: state.subject,
      query: state.query,
      results: state.results,
      hasMore: state.hasMore,
      loadingMore: true,
    );
    await _fetch(offset: state.results.length, append: true);
  }

  Future<void> _fetch({required int offset, bool append = false}) async {
    final String childId = state.childId!;
    final String subject = state.subject!;
    final String query = state.query;
    try {
      final List<LibraryActivity> page = await _env.catalogueRepository.library(
        childId,
        subject: subject,
        query: query,
        offset: offset,
      );
      if (state.childId != childId || state.subject != subject || state.query != query) return; // a newer request won
      state = LibraryState(
        childId: childId,
        subject: subject,
        query: query,
        results: append ? <LibraryActivity>[...state.results, ...page] : page,
        hasMore: page.length >= CatalogueRepository.pageSize,
      );
    } on ApiException catch (e) {
      if (state.childId != childId || state.subject != subject || state.query != query) return;
      state = LibraryState(childId: childId, subject: subject, query: query, results: state.results, error: e);
    }
  }
}

final NotifierProvider<LibraryNotifier, LibraryState> libraryProvider =
    NotifierProvider<LibraryNotifier, LibraryState>(LibraryNotifier.new);
