import 'package:a_tv/models/channel_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';


class PlayerScreen extends StatefulWidget {
  final Channel channel;

  const PlayerScreen({super.key, required this.channel});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  FlickManager? flickManager;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  void initializePlayer() {
    try {
      flickManager = FlickManager(
        autoPlay: true,
        videoPlayerController: VideoPlayerController.networkUrl(
          Uri.parse(widget.channel.streamUrl),
        ),
      );
    } catch (e) {
      hasError = true;
    }
  }

  @override
  void dispose() {
    flickManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manager = flickManager;
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
              return _buildLandscapePlayer(manager);
            }

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    _buildPlayer(manager),
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

  Widget _buildLandscapePlayer(FlickManager? manager) {
    if (hasError || manager == null) {
      return const Center(child: Text('Stream not available'));
    }

    return SizedBox.expand(
      child: FlickVideoPlayer(
        flickManager: manager,
        flickVideoWithControls: const FlickVideoWithControls(
          videoFit: BoxFit.contain,
          controls: FlickPortraitControls(),
        ),
      ),
    );
  }

  Widget _buildPlayer(FlickManager? manager) {
    if (hasError || manager == null) {
      return Container(
        width: double.infinity,
        color: Colors.black,
        child: const AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(child: Text('Stream not available')),
        ),
      );
    }

    return Container(
      width: double.infinity,
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: FlickVideoPlayer(
          flickManager: manager,
          flickVideoWithControls: const FlickVideoWithControls(
            videoFit: BoxFit.contain,
            controls: FlickPortraitControls(),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelInfo(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final logoSize = width < 360 ? 76.0 : 95.0;

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
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.live_tv_rounded),
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
            style: TextStyle(
              fontSize: width < 360 ? 18 : 22,
              fontWeight: FontWeight.bold,
            ),
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
