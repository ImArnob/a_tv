import 'package:a_tv/category_drawer.dart';
import 'package:a_tv/services/iptv_service.dart';
import 'package:a_tv/widgets/channel_card.dart';
import 'package:a_tv/widgets/loading_error_widget.dart';
import 'package:a_tv/widgets/search_box.dart';
import 'package:flutter/material.dart';
import 'package:a_tv/models/channel_model.dart';

enum LoadState { loading, success, error }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Channel> allChannels = [];
  List<Channel> filteredChannels = [];
  List<String> categories = ['All Channels'];

  String selectedCategory = 'All Channels';
  String searchQuery = '';

  LoadState loadState = LoadState.loading;

  @override
  void initState() {
    super.initState();
    loadChannels();
  }

  Future<void> loadChannels() async {
    setState(() {
      loadState = LoadState.loading;
    });

    try {
      final channels = await IPTVService.fetchChannels();

      final uniqueCategories = channels
          .map((channel) => channel.category.trim())
          .where((category) => category.isNotEmpty)
          .toSet()
          .toList();

      uniqueCategories.sort();

      setState(() {
        allChannels = channels;
        categories = ['All Channels', ...uniqueCategories];
        selectedCategory = 'All Channels';
        searchQuery = '';
        filteredChannels = channels;
        loadState = LoadState.success;
      });
    } catch (e) {
      setState(() {
        loadState = LoadState.error;
      });
    }
  }

  void applyFilters() {
    final input = searchQuery.toLowerCase().trim();

    final result = allChannels.where((channel) {
      final matchesCategory =
          selectedCategory == 'All Channels' ||
          channel.category.toLowerCase() == selectedCategory.toLowerCase();

      final matchesSearch =
          input.isEmpty ||
          channel.name.toLowerCase().contains(input) ||
          channel.category.toLowerCase().contains(input);

      return matchesCategory && matchesSearch;
    }).toList();

    setState(() {
      filteredChannels = result;
    });
  }

  void searchChannel(String query) {
    searchQuery = query;
    applyFilters();
  }

  void selectCategory(String category) {
    selectedCategory = category;
    applyFilters();
  }

  int getCrossAxisCount(double width) {
    if (width >= 1100) return 6;
    if (width >= 850) return 5;
    if (width >= 650) return 4;
    if (width >= 420) return 3;
    return 2;
  }

  double getChildAspectRatio(double width) {
    if (width >= 850) return 0.92;
    if (width >= 650) return 0.88;
    if (width >= 420) return 0.82;
    return 0.76;
  }

  double getHorizontalPadding(double width) {
    if (width >= 900) return 32;
    if (width >= 600) return 24;
    return 16;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CategoryDrawer(
        categories: categories,
        selectedCategory: selectedCategory,
        onCategorySelected: selectCategory,
      ),
      body: RefreshIndicator(
        onRefresh: loadChannels,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = getCrossAxisCount(width);
            final aspectRatio = getChildAspectRatio(width);
            final horizontalPadding = getHorizontalPadding(width);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: width < 360 ? 170 : 210,
                  pinned: true,
                  backgroundColor: const Color(0xff111827),
                  leading: Builder(
                    builder: (context) {
                      return IconButton(
                        icon: const Icon(Icons.menu_rounded),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      );
                    },
                  ),
                  title: Text(
                    selectedCategory == 'All Channels'
                        ? 'Live TV'
                        : selectedCategory,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xffEF4444),
                            Color(0xff111827),
                            Color(0xff080B12),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.live_tv_rounded,
                          size: width < 360 ? 60 : 85,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      16,
                      horizontalPadding,
                      8,
                    ),
                    child: SearchBox(onChanged: searchChannel),
                  ),
                ),

                if (loadState == LoadState.success)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        12,
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xff111827),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.category_rounded,
                                    size: 16,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      selectedCategory,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${filteredChannels.length} channels',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (loadState == LoadState.loading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),

                if (loadState == LoadState.error)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: LoadingErrorWidget(
                      title: 'Failed to load channels',
                      buttonText: 'Try Again',
                      onPressed: loadChannels,
                    ),
                  ),

                if (loadState == LoadState.success && filteredChannels.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No channel found')),
                  ),

                if (loadState == LoadState.success &&
                    filteredChannels.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final channel = filteredChannels[index];

                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 220 + index * 12),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: ChannelCard(channel: channel),
                        );
                      }, childCount: filteredChannels.length),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: aspectRatio,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }
}
