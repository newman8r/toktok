import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../theme/gem_theme.dart';

class FeedPage extends StatefulWidget {
  final List<File> recordedVideos;

  const FeedPage({
    super.key,
    required this.recordedVideos,
  });

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final List<Map<String, dynamic>> _placeholderContent = [
    {
      'title': 'Crystal Cave Exploration',
      'description': 'Deep in the heart of the cave...',
      'color': Colors.purple.shade900,
      'icon': Icons.diamond_outlined,
    },
    {
      'title': 'Ruby Mining Adventure',
      'description': 'Found a rare gem today...',
      'color': Colors.red.shade900,
      'icon': Icons.catching_pokemon,
    },
    {
      'title': 'Emerald Forest',
      'description': 'The glow of nature...',
      'color': Colors.green.shade900,
      'icon': Icons.forest,
    },
  ];

  final Map<String, VideoPlayerController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  Future<void> _initializeControllers() async {
    for (var i = 0; i < widget.recordedVideos.length; i++) {
      final controller = VideoPlayerController.file(widget.recordedVideos[i]);
      await controller.initialize();
      _controllers['video_$i'] = controller;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepCave,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Gem Feed', style: crystalHeading),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Recorded Videos Section
          if (widget.recordedVideos.isNotEmpty) ...[
            Text('Your Recordings', style: crystalHeading.copyWith(color: Colors.white)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.recordedVideos.length,
                itemBuilder: (context, index) {
                  final controller = _controllers['video_$index'];
                  if (controller == null) return const SizedBox();
                  
                  return Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: VideoPlayer(controller),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (controller.value.isPlaying) {
                                controller.pause();
                              } else {
                                controller.play();
                              }
                              setState(() {});
                            },
                            child: Center(
                              child: Icon(
                                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Placeholder Content
          Text('Discover Gems', style: crystalHeading.copyWith(color: Colors.white)),
          const SizedBox(height: 16),
          ..._placeholderContent.map((content) => _buildPlaceholderCard(content)),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard(Map<String, dynamic> content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: content['color'],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: content['color'].withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  content['icon'],
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content['title'],
                        style: crystalHeading.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        content['description'],
                        style: gemText.copyWith(color: Colors.white.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 