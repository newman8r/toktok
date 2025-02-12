import 'package:flutter/material.dart';
import '../theme/gem_theme.dart';
import '../models/gem_model.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class GemInfoPage extends StatelessWidget {
  final GemModel gem;

  const GemInfoPage({
    super.key,
    required this.gem,
  });

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y \'at\' h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepCave,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    sapphire.withOpacity(0.15),
                    deepCave.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Crystal Analysis',
          style: crystalHeading.copyWith(fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gem Preview Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: caveShadow.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(emeraldCut),
                    border: Border.all(
                      color: amethyst.withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: amethyst.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail with crystal overlay
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(emeraldCut),
                        ),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                gem.thumbnailUrl,
                                fit: BoxFit.cover,
                              ),
                              // Crystal overlay
                              CustomPaint(
                                painter: _CrystalOverlayPainter(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Title and description
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gem.title,
                              style: crystalHeading.copyWith(
                                fontSize: 24,
                                color: amethyst,
                              ),
                            ),
                            if (gem.description != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                gem.description!,
                                style: gemText.copyWith(
                                  color: silver,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Technical Details Section
                Text(
                  'Crystal Structure',
                  style: crystalHeading.copyWith(
                    fontSize: 20,
                    color: sapphire,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoGrid([
                  {
                    'icon': Icons.memory,
                    'label': 'Size',
                    'value': _formatFileSize(gem.bytes),
                    'color': emerald,
                  },
                  {
                    'icon': Icons.calendar_today,
                    'label': 'Created',
                    'value': _formatDate(gem.createdAt),
                    'color': ruby,
                  },
                  {
                    'icon': Icons.tag,
                    'label': 'Tags',
                    'value': gem.tags.length.toString(),
                    'color': amethyst,
                  },
                  {
                    'icon': Icons.fingerprint,
                    'label': 'Gem ID',
                    'value': gem.id.substring(0, 8),
                    'color': sapphire,
                  },
                ]),

                const SizedBox(height: 24),

                // Tags Section
                if (gem.tags.isNotEmpty) ...[
                  Text(
                    'Enchantments',
                    style: crystalHeading.copyWith(
                      fontSize: 20,
                      color: amethyst,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: gem.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: amethyst.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(emeraldCut),
                        border: Border.all(
                          color: amethyst.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '#$tag',
                        style: gemText.copyWith(
                          color: amethyst,
                          fontSize: 14,
                        ),
                      ),
                    )).toList(),
                  ),
                ],

                const SizedBox(height: 24),

                // Cloudinary Info
                Text(
                  'Arcane Storage',
                  style: crystalHeading.copyWith(
                    fontSize: 20,
                    color: ruby,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: caveShadow.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(emeraldCut),
                    border: Border.all(
                      color: ruby.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        icon: Icons.cloud,
                        label: 'Public ID',
                        value: gem.cloudinaryPublicId ?? 'Not available',
                        color: ruby,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.link,
                        label: 'URL',
                        value: gem.cloudinaryUrl ?? 'Not available',
                        color: ruby,
                        isMultiLine: true,
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

  Widget _buildInfoGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: caveShadow.withOpacity(0.3),
            borderRadius: BorderRadius.circular(emeraldCut),
            border: Border.all(
              color: (item['color'] as Color).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(emeraldCut / 2),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: item['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['value'] as String,
                      style: gemText.copyWith(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item['label'] as String,
                      style: gemText.copyWith(
                        color: silver,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isMultiLine = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(emeraldCut / 2),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: gemText.copyWith(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              Text(
                label,
                style: gemText.copyWith(
                  color: silver,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CrystalOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          sapphire.withOpacity(0.2),
          amethyst.withOpacity(0.1),
          ruby.withOpacity(0.2),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw crystal facets
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width * 0.3, 0);
    path.lineTo(size.width * 0.4, size.height * 0.2);
    path.lineTo(size.width * 0.6, size.height * 0.2);
    path.lineTo(size.width * 0.7, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width * 0.8, size.height);
    path.lineTo(size.width * 0.2, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CrystalOverlayPainter oldDelegate) => false;
} 