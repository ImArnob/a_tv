import 'package:http/http.dart' as http;
import '../models/channel_model.dart';

class IPTVService {
  static const String apiUrl =
      'https://raw.githubusercontent.com/Monjil404/livetv/refs/heads/main/pro';

  static Future<List<Channel>> fetchChannels() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode != 200) {
      throw Exception('Failed to load channels');
    }

    return parseM3U(response.body);
  }

  static List<Channel> parseM3U(String data) {
    final lines = data.split('\n').map((e) => e.trim()).toList();

    final List<Channel> channels = [];

    String name = 'Unknown Channel';
    String logo = '';
    String category = 'Live TV';

    for (final line in lines) {
      if (line.isEmpty) continue;

      final isInfoLine =
          line.contains('tvg-logo') || line.contains('group-title');

      final isStreamLine =
          line.startsWith('http://') || line.startsWith('https://');

      if (isInfoLine) {
        logo = _extractValue(line, 'tvg-logo');
        category = _extractValue(line, 'group-title');

        if (line.contains(',')) {
          name = line.split(',').last.trim();
        } else {
          name = 'Unknown Channel';
        }

        if (category.isEmpty) {
          category = 'Live TV';
        }
      }

      if (isStreamLine) {
        channels.add(
          Channel(
            name: name,
            logo: logo,
            category: category,
            streamUrl: line,
          ),
        );

        name = 'Unknown Channel';
        logo = '';
        category = 'Live TV';
      }
    }

    return channels;
  }

  static String _extractValue(String line, String key) {
    final regex = RegExp('$key="([^"]*)"');
    final match = regex.firstMatch(line);
    return match?.group(1) ?? '';
  }
}