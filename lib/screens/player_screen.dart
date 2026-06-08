import 'package:a_tv/models/channel_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;

  const PlayerScreen({super.key, required this.channel});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? videoPlayerController;
  ChewieController? chewieController;

  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  Future<void> initializePlayer() async {
    try {
      final videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.channel.streamUrl),
      );

      await videoController.initialize();
      await videoController.play();

      final chewie = ChewieController(
        videoPlayerController: videoController,
        autoPlay: true,
        looping: false,
        isLive: true,
        showControls: true,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: false,
        aspectRatio: 16 / 9,
        customControls: LiveTvControls(
          videoController: videoController,
          streamUrl: widget.channel.streamUrl,
          onReinitialize: _reinitializePlayer,
        ),
        errorBuilder: (context, errorMessage) {
          return const Center(
            child: Text(
              'Stream not available',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      );

      if (!mounted) return;

      setState(() {
        videoPlayerController = videoController;
        chewieController = chewie;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  /// Called when the user resumes after pausing —
  /// disposes old controllers and creates fresh ones so the
  /// live stream picks up from the current broadcast position.
  Future<void> _reinitializePlayer() async {
    setState(() {
      isLoading = true;
    });

    // Dispose old controllers cleanly
    chewieController?.dispose();
    await videoPlayerController?.dispose();

    setState(() {
      chewieController = null;
      videoPlayerController = null;
    });

    await initializePlayer();
  }

  @override
  void dispose() {
    chewieController?.dispose();
    videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;

    return Scaffold(
      backgroundColor: const Color(0xff080B12),
      appBar: isLandscape
          ? null
          : AppBar(
              title: Text(
                widget.channel.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: const Color(0xff080B12),
            ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (isLandscape) {
              return Center(child: _buildVideoArea(isLandscape: true));
            }

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    _buildVideoArea(),
                    const SizedBox(height: 24),
                    _buildChannelInfo(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoArea({bool isLandscape = false}) {
    final chewie = chewieController;

    if (isLoading) {
      return Container(
        width: double.infinity,
        color: Colors.black,
        child: const AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (hasError || chewie == null) {
      return Container(
        width: double.infinity,
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Stream not available',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _reinitializePlayer,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isLandscape) {
      return SizedBox.expand(child: Chewie(controller: chewie));
    }

    return Container(
      width: double.infinity,
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Chewie(controller: chewie),
      ),
    );
  }

  Widget _buildChannelInfo(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final logoSize = width < 360 ? 72.0 : 92.0;
    final titleSize = width < 360 ? 18.0 : 22.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Hero(
            tag: widget.channel.streamUrl,
            child: Container(
              height: logoSize,
              width: logoSize,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xff111827),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white10),
              ),
              child: widget.channel.logo.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.channel.logo,
                      fit: BoxFit.contain,
                      errorWidget: (context, url, error) {
                        return const Icon(Icons.live_tv_rounded);
                      },
                    )
                  : const Icon(Icons.live_tv_rounded),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.channel.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.channel.category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Custom live-TV controls
// ─────────────────────────────────────────────

class LiveTvControls extends StatefulWidget {
  final VideoPlayerController videoController;
  final String streamUrl;

  /// Called when the user taps the resume (play) button.
  /// The parent reinitialises the player so the stream
  /// reconnects at the current live position.
  final Future<void> Function() onReinitialize;

  const LiveTvControls({
    super.key,
    required this.videoController,
    required this.streamUrl,
    required this.onReinitialize,
  });

  @override
  State<LiveTvControls> createState() => _LiveTvControlsState();
}

class _LiveTvControlsState extends State<LiveTvControls> {
  bool showControls = true;
  bool isMuted = false;
  bool isResuming = false;

  /// Pause: simply pauses the underlying controller.
  /// Resume: reinitialises the whole player so the live
  ///         stream reconnects at the current broadcast position.
  Future<void> togglePlayPause() async {
    final controller = widget.videoController;

    if (controller.value.isPlaying) {
      // ── PAUSE ──────────────────────────────────────────
      await controller.pause();
      if (mounted) setState(() {});
    } else {
      // ── RESUME (reinitialise) ───────────────────────────
      // Show a spinner while the new controller loads.
      setState(() => isResuming = true);
      await widget.onReinitialize();
      // After reinitialise the widget may already be unmounted
      // because the parent rebuilt with a brand-new LiveTvControls.
      // Guard with mounted just in case.
      if (mounted) setState(() => isResuming = false);
    }
  }

  void toggleMute() {
    final controller = widget.videoController;

    if (isMuted) {
      controller.setVolume(1);
    } else {
      controller.setVolume(0);
    }

    setState(() {
      isMuted = !isMuted;
    });
  }

  void toggleControls() {
    setState(() {
      showControls = !showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chewieController = ChewieController.of(context);

    return GestureDetector(
      onTap: toggleControls,
      child: Stack(
        children: [
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: widget.videoController,
            builder: (context, value, child) {
              final isPlaying = value.isPlaying;
              final isBuffering = value.isBuffering;

              // While reconnecting show a full-overlay spinner
              if (isResuming) {
                return Container(
                  color: Colors.black.withOpacity(0.6),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }

              return AnimatedOpacity(
                opacity: showControls || !isPlaying ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  color: Colors.black.withOpacity(0.25),
                  child: Stack(
                    children: [
                      // ── Centre play/pause / buffering indicator ──
                      Center(
                        child: isBuffering
                            ? const CircularProgressIndicator()
                            : IconButton(
                                onPressed: togglePlayPause,
                                iconSize: 58,
                                color: Colors.white,
                                icon: Icon(
                                  isPlaying
                                      ? Icons.pause_circle_filled_rounded
                                      : Icons.play_circle_fill_rounded,
                                ),
                              ),
                      ),

                      // ── Bottom control bar ───────────────────────
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 8,
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: togglePlayPause,
                              color: Colors.white,
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                            ),

                            IconButton(
                              onPressed: toggleMute,
                              color: Colors.white,
                              icon: Icon(
                                isMuted
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                              ),
                            ),

                            const SizedBox(width: 8),

                            // LIVE badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const Spacer(),

                            IconButton(
                              onPressed: () {
                                chewieController.enterFullScreen();
                              },
                              color: Colors.white,
                              icon: const Icon(Icons.fullscreen_rounded),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
