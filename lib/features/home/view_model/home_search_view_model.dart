import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../config/services/remote_services/errors/failure.dart';
import '../models/search_models.dart';
import '../service/home_search_service.dart';

/// State for the home search feature.
class HomeSearchState {
  const HomeSearchState({
    this.loading = false,
    this.error,
    this.results,
    this.query = '',
  });

  final bool loading;
  final Failure? error;
  final HomeSearchResponse? results;
  final String query;

  List<SearchCourse> get courses => results?.courses ?? const <SearchCourse>[];
  List<SearchMockTest> get mockTests =>
      results?.mockTests ?? const <SearchMockTest>[];

  bool get hasResults => results != null && results!.isNotEmpty;
  bool get isEmpty => results != null && results!.isEmpty;
  
  /// Whether there's a pending or valid search query (>= 2 chars)
  bool get hasValidQuery => query.length >= 2;

  HomeSearchState copyWith({
    bool? loading,
    Failure? error,
    bool clearError = false,
    HomeSearchResponse? results,
    bool clearResults = false,
    String? query,
  }) {
    return HomeSearchState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      results: clearResults ? null : (results ?? this.results),
      query: query ?? this.query,
    );
  }
}

/// ViewModel for managing home search state.
class HomeSearchViewModel extends StateNotifier<HomeSearchState> {
  HomeSearchViewModel(this._service) : super(const HomeSearchState());

  final HomeSearchService _service;

  Timer? _debounceTimer;
  CancelToken? _cancelToken;

  static const int _minQueryLength = 2;
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  /// Called when search input changes.
  /// Implements debouncing and minimum character requirements.
  void onSearchChanged(String query) {
    final trimmedQuery = query.trim();

    // Cancel any pending debounce timer
    _debounceTimer?.cancel();

    // Update query immediately for UI feedback
    state = state.copyWith(query: trimmedQuery, clearError: true);

    // Clear results if query is too short
    if (trimmedQuery.length < _minQueryLength) {
      _cancelPendingRequest();
      state = state.copyWith(
        loading: false,
        clearResults: true,
        clearError: true,
      );
      return;
    }

    // Show loading state immediately for better UX
    state = state.copyWith(loading: true);

    // Debounce the search
    _debounceTimer = Timer(_debounceDuration, () {
      _performSearch(trimmedQuery);
    });
  }

  /// Retry the current search immediately (no debounce).
  /// Used by retry buttons after an error.
  void retrySearch() {
    if (state.query.length >= _minQueryLength) {
      _performSearch(state.query);
    }
  }

  /// Performs the search API call.
  Future<void> _performSearch(String query) async {
    if (query.length < _minQueryLength) return;

    // Cancel any previous pending request
    _cancelPendingRequest();
    _cancelToken = CancelToken();

    state = state.copyWith(loading: true, clearError: true);

    final result = await _service.search(
      query: query,
      limit: 10,
      cancelToken: _cancelToken,
    );

    // Only update state if this is still the current query
    if (state.query != query) return;

    state = result.fold(
      (failure) {
        // Ignore cancelled request errors
        if (failure.message.contains('cancel')) {
          return state.copyWith(loading: false);
        }
        return state.copyWith(
          loading: false,
          error: failure,
        );
      },
      (response) => state.copyWith(
        loading: false,
        results: response,
        clearError: true,
      ),
    );
  }

  /// Clears search results and resets state.
  void clearSearch() {
    _debounceTimer?.cancel();
    _cancelPendingRequest();
    state = const HomeSearchState();
  }

  void _cancelPendingRequest() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('New search request');
    }
    _cancelToken = null;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _cancelPendingRequest();
    super.dispose();
  }
}

final homeSearchViewModelProvider =
    StateNotifierProvider<HomeSearchViewModel, HomeSearchState>((ref) {
  final service = ref.read(homeSearchServiceProvider);
  return HomeSearchViewModel(service);
});
