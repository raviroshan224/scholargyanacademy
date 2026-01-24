import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/core.dart';
import '../../../courses/view_model/course_view_model.dart';
// category model is accessed via the courses view-model
import '../widgets/courses_tab.dart';
import '../widgets/explore_tab_bar.dart';

final selectedTabIndexProvider = StateProvider<int>((Ref ref) => 0);

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  int _tabLength = 1;
  bool _ignoreNextTabChange = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLength, vsync: this);
    _tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(coursesViewModelProvider.notifier);
      notifier.loadCategories();
      notifier.fetch(
        page: 1,
        limit: 10,
        applySearch: true,
        search: null,
        applyCategory: true,
        categoryId: null,
      );
      notifier.fetchSaved(force: true);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_ignoreNextTabChange) {
      _ignoreNextTabChange = false;
      return;
    }
    if (_tabController.indexIsChanging) return;
    final state = ref.read(coursesViewModelProvider);
    final index = _tabController.index;
    ref.read(selectedTabIndexProvider.notifier).state = index;
    final categories = state.categories;
    if (index > 0 && index - 1 >= categories.length) {
      return;
    }
    final categoryId = index == 0 ? null : categories[index - 1].id;
    _fetchCourses(
      categoryId: categoryId,
      applyCategory: true,
    );
  }

  void _fetchCourses({
    String? categoryId,
    bool applySearch = false,
    bool applyCategory = false,
    String? explicitSearch,
  }) {
    final notifier = ref.read(coursesViewModelProvider.notifier);
    final state = ref.read(coursesViewModelProvider);
    final searchValue = applySearch
        ? (explicitSearch ?? _searchController.text.trim())
        : (explicitSearch ?? state.currentSearch);
    final categoryValue =
        applyCategory ? categoryId : (categoryId ?? state.currentCategoryId);
    final limit = state.publicMeta?.limit ?? 10;

    notifier.fetch(
      page: 1,
      limit: limit,
      search: searchValue,
      categoryId: categoryValue,
      applySearch: applySearch,
      applyCategory: applyCategory,
    );
  }

  void _onSearchSubmitted() {
    _fetchCourses(applySearch: true);
  }

  void _updateTabController(int newLength) {
    // kept for compatibility but handled via ref.listen. noop here.
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coursesViewModelProvider);
    final selectedTabIndex = ref.watch(selectedTabIndexProvider);
    final categories = state.categories;
    final tabTitles = <String>[
      'All',
      ...categories.map((e) => e.categoryName),
    ];
    _updateTabController(tabTitles.length);

    final currentCategoryId = state.currentCategoryId;
    if (currentCategoryId != null) {
      final categoryIndex =
          categories.indexWhere((category) => category.id == currentCategoryId);
      if (categoryIndex >= 0 && selectedTabIndex != categoryIndex + 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(selectedTabIndexProvider.notifier).state = categoryIndex + 1;
        });
      }
    }

    // keep TabController in sync with categories length (synchronously)
    final newLength = 1 + categories.length;
    if (newLength != _tabLength) {
      final currentIndex = _tabController.index.clamp(0, newLength - 1);
      _tabController.removeListener(_handleTabChange);
      _tabController.dispose();
      _tabController = TabController(
        length: newLength,
        vsync: this,
        initialIndex: currentIndex,
      );
      _tabController.addListener(_handleTabChange);
      _tabLength = newLength;
    }

    if (selectedTabIndex >= _tabController.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(selectedTabIndexProvider.notifier).state = 0;
        if (_tabController.index != 0) {
          _tabController.index = 0;
        }
      });
    } else if (selectedTabIndex >= 0 &&
        selectedTabIndex < _tabController.length &&
        _tabController.index != selectedTabIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_tabController.index != selectedTabIndex) {
          _tabController.index = selectedTabIndex;
        }
      });
    }

    return WillPopScope(
      onWillPop: () async {
        final courseState = ref.read(coursesViewModelProvider);
        final hasSearch = (courseState.currentSearch?.isNotEmpty ?? false);
        final hasCategory = courseState.currentCategoryId != null;
        if (hasSearch || hasCategory) {
          _searchController.clear();
          if (_tabController.length > 0 && _tabController.index != 0) {
            _tabController.index = 0;
          }
          ref.read(selectedTabIndexProvider.notifier).state = 0;
          _fetchCourses(
              applySearch: true, applyCategory: true, categoryId: null);
          return false;
        }
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.white,
          appBar: CustomAppBar(
            leadingIcon: Icon(
              Icons.arrow_forward_ios_outlined,
              color: AppColors.black,
            ),
            title: 'Explore Courses',
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CustTextField(
                  borderRadius: 8,
                  hintText: 'Search Here',
                  hintColor: AppColors.gray400,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SvgPicture.asset(AppAssets.searchIcon),
                  ),
                  controller: _searchController,
                  onFieldSubmitted: (_) {
                    _onSearchSubmitted();
                  },
                  suffixIcon: const Icon(Icons.close, size: 18),
                  onSuffixIconClick: () {
                    if (_searchController.text.isEmpty) return;
                    _searchController.clear();
                    _fetchCourses(applySearch: true);
                  },
                  validator: null,
                ),
              ),
              AppSpacing.verticalSpaceAverage,
              SizedBox(
                // height: 50,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  physics: const BouncingScrollPhysics(),

                  indicatorColor: Colors.transparent, // FIX

                  labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                  unselectedLabelColor: AppColors.black,

                  tabs: [
                    for (var i = 0; i < tabTitles.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: selectedTabIndex == i
                              ? AppColors.primary.withOpacity(0.15)
                              : Colors.grey.shade100,
                        ),
                        child: Text(
                          tabTitles[i],
                          style: TextStyle(
                            fontWeight: selectedTabIndex == i
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: selectedTabIndex == i
                                ? AppColors.primary
                                : AppColors.gray700,
                          ),
                        ),
                      ),
                  ],

                  onTap: (index) {
                    final cat = index == 0 ? null : categories[index - 1];
                    _ignoreNextTabChange = true;
                    _tabController.index = index;
                    ref.read(selectedTabIndexProvider.notifier).state = index;
                    _fetchCourses(categoryId: cat?.id, applyCategory: true);
                  },
                ),
              ),
              AppSpacing.verticalSpaceAverage,
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: tabTitles.map((_) => const CoursesTab()).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
