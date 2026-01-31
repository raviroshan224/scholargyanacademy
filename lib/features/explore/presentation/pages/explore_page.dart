import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/core.dart';
import '../../../courses/view_model/course_view_model.dart';
import '../widgets/courses_tab.dart';

final selectedTabIndexProvider = StateProvider<int>((Ref ref) => 0);

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key, this.initialCategoryId});

  final String? initialCategoryId;

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  int _tabLength = 1;
  bool _ignoreNextTabChange = false;
  bool _isSearchFocused = false;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLength, vsync: this);
    _tabController.addListener(_handleTabChange);
    _searchFocusNode.addListener(_handleSearchFocus);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(coursesViewModelProvider.notifier);
      notifier.loadCategories();
      notifier.fetch(
        page: 1,
        limit: 10,
        applySearch: true,
        search: null,
        applyCategory: widget.initialCategoryId != null,
        categoryId: widget.initialCategoryId,
      );
      notifier.fetchSaved(force: true);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.removeListener(_handleSearchFocus);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchFocus() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
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
    _searchFocusNode.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    _fetchCourses(applySearch: true);
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(coursesViewModelProvider);
    final selectedTabIndex = ref.watch(selectedTabIndexProvider);
    final categories = state.categories;
    final tabTitles = <String>[
      'All Courses',
      ...categories.map((e) => e.categoryName),
    ];

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

    // Keep TabController in sync with categories length
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

    final hasActiveFilters = (state.currentSearch?.isNotEmpty ?? false) ||
        state.currentCategoryId != null;

    return WillPopScope(
      onWillPop: () async {
        if (hasActiveFilters) {
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
      child: Scaffold(
        backgroundColor: AppColors.gray100 ?? const Color(0xFFF9FAFB),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // GestureDetector(
                    //   onTap: () => Navigator.of(context).pop(),
                    //   child: Container(
                    //     padding: const EdgeInsets.all(8),
                    //     decoration: BoxDecoration(
                    //       color: AppColors.gray600.withOpacity(0.08),
                    //       borderRadius: BorderRadius.circular(10),
                    //     ),
                    //     child: Icon(
                    //       Icons.arrow_back_ios_new_rounded,
                    //       color: AppColors.black,
                    //       size: 18,
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CText(
                            'Explore Courses',
                            type: TextType.headlineSmall,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                          // if (state.publicMeta?.total != null)
                          //   CText(
                          //     '${state.publicMeta!.total} courses available',
                          //     type: TextType.bodySmall,
                          //     fontSize: 11,
                          //     color: AppColors.gray600,
                          //   ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Search Bar Section
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: AppColors.gray100 ?? const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSearchFocused
                        ? AppColors.primary.withOpacity(0.3)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: _isSearchFocused
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onSubmitted: (_) => _onSearchSubmitted(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search courses, topics...',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.gray400,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: SvgPicture.asset(
                        AppAssets.searchIcon,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          _isSearchFocused
                              ? AppColors.primary
                              : AppColors.gray400,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: _clearSearch,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.gray600.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: AppColors.gray700,
                                ),
                              ),
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),

            // Category Tabs Section
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 16),
                  //   child: Row(
                  //     children: [
                  //       Icon(
                  //         Icons.category_rounded,
                  //         size: 16,
                  //         color: AppColors.gray600,
                  //       ),
                  //       const SizedBox(width: 6),
                  //       CText(
                  //         'Categories',
                  //         type: TextType.bodySmall,
                  //         fontSize: 12,
                  //         fontWeight: FontWeight.w600,
                  //         color: AppColors.gray600,
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // const SizedBox(height: 12),

                  // Category Chips
                  SizedBox(
                    height: 44,
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      physics: const BouncingScrollPhysics(),
                      indicatorColor: Colors.transparent,
                      dividerColor: Colors.transparent,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      tabs: List.generate(
                        tabTitles.length,
                        (i) => _buildCategoryChip(
                          tabTitles[i],
                          i == selectedTabIndex,
                          i == 0,
                        ),
                      ),
                      onTap: (index) {
                        final cat = index == 0 ? null : categories[index - 1];
                        _ignoreNextTabChange = true;
                        _tabController.index = index;
                        ref.read(selectedTabIndexProvider.notifier).state =
                            index;
                        _fetchCourses(categoryId: cat?.id, applyCategory: true);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Active Filters Indicator
            // if (hasActiveFilters)
            //   Container(
            //     color: AppColors.white,
            //     padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            //     child: Container(
            //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            //       decoration: BoxDecoration(
            //         color: AppColors.primary.withOpacity(0.08),
            //         borderRadius: BorderRadius.circular(8),
            //         border: Border.all(
            //           color: AppColors.primary.withOpacity(0.2),
            //           width: 1,
            //         ),
            //       ),
            //       child: Row(
            //         children: [
            //           Icon(
            //             Icons.filter_alt_rounded,
            //             size: 16,
            //             color: AppColors.primary,
            //           ),
            //           const SizedBox(width: 6),
            //           Expanded(
            //             child: CText(
            //               'Filters active',
            //               type: TextType.bodySmall,
            //               fontSize: 12,
            //               fontWeight: FontWeight.w600,
            //               color: AppColors.primary,
            //             ),
            //           ),
            //           GestureDetector(
            //             onTap: () {
            //               _clearSearch();
            //               if (_tabController.index != 0) {
            //                 _tabController.index = 0;
            //               }
            //               ref.read(selectedTabIndexProvider.notifier).state = 0;
            //               _fetchCourses(
            //                 applySearch: true,
            //                 applyCategory: true,
            //                 categoryId: null,
            //               );
            //             },
            //             child: Container(
            //               padding: const EdgeInsets.symmetric(
            //                 horizontal: 8,
            //                 vertical: 4,
            //               ),
            //               decoration: BoxDecoration(
            //                 color: AppColors.primary,
            //                 borderRadius: BorderRadius.circular(6),
            //               ),
            //               child: CText(
            //                 'Clear All',
            //                 type: TextType.bodySmall,
            //                 fontSize: 11,
            //                 fontWeight: FontWeight.w600,
            //                 color: AppColors.white,
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),

            // // Divider
            // Container(
            //   height: 1,
            //   color: AppColors.gray600.withOpacity(0.08),
            // ),

            // Courses Content
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
    );
  }

  Widget _buildCategoryChip(String title, bool isSelected, bool isAll) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isSelected
            ? AppColors.primary
            : AppColors.gray600.withOpacity(0.06),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAll)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                Icons.grid_view_rounded,
                size: 16,
                color: isSelected ? AppColors.white : AppColors.gray600,
              ),
            ),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? AppColors.white : AppColors.gray700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
