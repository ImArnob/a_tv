import 'package:a_tv/models/channel_model.dart';
import 'package:a_tv/services/iptv_service.dart';
import 'package:a_tv/widgets/channel_card.dart';
import 'package:a_tv/widgets/loading_error_widget.dart';
import 'package:a_tv/widgets/search_box.dart';
import 'package:flutter/material.dart';


enum LoadState { loading, success, error }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Channel> allChannels = [];
  List<Channel> filteredChannels = [];

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

      setState(() {
        allChannels = channels;
        filteredChannels = channels;
        loadState = LoadState.success;
      });
    } catch (e) {
      setState(() {
        loadState = LoadState.error;
      });
    }
  }

  void searchChannel(String query) {
    final input = query.toLowerCase().trim();

    final result = allChannels.where((channel) {
      final name = channel.name.toLowerCase();
      final category = channel.category.toLowerCase();

      return name.contains(input) || category.contains(input);
    }).toList();

    setState(() {
      filteredChannels = result;
    });
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
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'Live TV',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                      12,
                    ),
                    child: SearchBox(onChanged: searchChannel),
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
