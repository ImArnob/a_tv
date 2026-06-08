import 'package:a_tv/screens/player_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:a_tv/models/channel_model.dart';


class ChannelCard extends StatelessWidget {
  final Channel channel;

  const ChannelCard({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final logoSize = cardWidth * 0.42;
        final safeLogoSize = logoSize.clamp(50.0, 88.0);
        final fontSize = cardWidth < 130 ? 12.0 : 14.0;

        return InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, animation, __) {
                  return FadeTransition(
                    opacity: animation,
                    child: PlayerScreen(channel: channel),
                  );
                },
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xff111827),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: channel.streamUrl,
                  child: Container(
                    height: safeLogoSize,
                    width: safeLogoSize,
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: channel.logo.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: channel.logo,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.live_tv_rounded),
                          )
                        : const Icon(Icons.live_tv_rounded),
                  ),
                ),

                const SizedBox(height: 10),

                Flexible(
                  child: Text(
                    channel.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  channel.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: fontSize - 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
