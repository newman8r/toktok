import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/gem_theme.dart';
import '../widgets/gem_button.dart';
import 'dart:ui' as ui;

class CreatorStudioPage extends StatefulWidget {
  const CreatorStudioPage({super.key});

  @override
  State<CreatorStudioPage> createState() => _CreatorStudioPageState();
}

class _CreatorStudioPageState extends State<CreatorStudioPage> with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _shimmerController;
  final _formKey = GlobalKey<FormState>();
  
  String _title = '';
  String _description = '';
  String _category = 'Music';
  bool _isOriginalContent = true;
  
  final List<String> _categories = [
    'Music',
    'Dance',
    'Comedy',
    'Education',
    'Gaming',
    'Lifestyle',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepCave,
      body: Stack(
        children: [
          // Background shimmer effect
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CreatorStudioBackgroundPainter(
                    progress: _shimmerController.value,
                  ),
                );
              },
            ),
          ),
          
          // Main content
          CustomScrollView(
            slivers: [
              // App Bar
              _buildAppBar(),
              
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(),
                      const SizedBox(height: 32),
                      _buildCreatorTabs(),
                      const SizedBox(height: 32),
                      _buildContentForm(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: FlexibleSpaceBar(
            title: Text(
              'Creator Studio',
              style: crystalHeading.copyWith(fontSize: 24),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    amethyst.withOpacity(0.3),
                    deepCave.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: caveShadow.withOpacity(0.3),
        borderRadius: BorderRadius.circular(emeraldCut),
        border: Border.all(
          color: amethyst.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to Your Creative Space',
            style: crystalHeading.copyWith(
              fontSize: 28,
              color: amethyst,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Share your unique content with the world. Your creativity is like a precious gem waiting to be discovered.',
            style: gemText.copyWith(
              color: silver,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStatCard('Views Today', '1.2K', emerald),
              const SizedBox(width: 16),
              _buildStatCard('Followers', '842', sapphire),
              const SizedBox(width: 16),
              _buildStatCard('Gems Earned', '156', ruby),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(emeraldCut),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: crystalHeading.copyWith(
                fontSize: 24,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: gemText.copyWith(
                fontSize: 12,
                color: silver,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatorTabs() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: caveShadow.withOpacity(0.3),
        borderRadius: BorderRadius.circular(emeraldCut),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(emeraldCut),
          color: amethyst.withOpacity(0.3),
        ),
        tabs: const [
          Tab(text: 'Upload'),
          Tab(text: 'Analytics'),
          Tab(text: 'Community'),
        ],
      ),
    );
  }

  Widget _buildContentForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGemTextField(
            label: 'Content Title',
            hint: 'Give your creation a captivating title',
            onChanged: (value) => _title = value,
          ),
          const SizedBox(height: 24),
          _buildGemTextField(
            label: 'Description',
            hint: 'Tell your story...',
            maxLines: 4,
            onChanged: (value) => _description = value,
          ),
          const SizedBox(height: 24),
          _buildCategoryDropdown(),
          const SizedBox(height: 24),
          _buildOriginalContentSwitch(),
          const SizedBox(height: 32),
          _buildUploadSection(),
          const SizedBox(height: 32),
          Center(
            child: GemButton(
              text: 'Share Creation',
              onPressed: _submitContent,
              gemColor: emerald,
              isAnimated: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGemTextField({
    required String label,
    required String hint,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: gemText.copyWith(
            color: silver,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          style: gemText.copyWith(color: Colors.white),
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: gemText.copyWith(
              color: silver.withOpacity(0.5),
            ),
            filled: true,
            fillColor: caveShadow.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(emeraldCut),
              borderSide: BorderSide(
                color: amethyst.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(emeraldCut),
              borderSide: BorderSide(
                color: amethyst.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(emeraldCut),
              borderSide: BorderSide(
                color: amethyst.withOpacity(0.8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: gemText.copyWith(
            color: silver,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: caveShadow.withOpacity(0.3),
            borderRadius: BorderRadius.circular(emeraldCut),
            border: Border.all(
              color: amethyst.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _category,
              isExpanded: true,
              dropdownColor: caveShadow,
              style: gemText.copyWith(color: Colors.white),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _category = newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOriginalContentSwitch() {
    return Row(
      children: [
        Text(
          'Original Content',
          style: gemText.copyWith(
            color: silver,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Switch(
          value: _isOriginalContent,
          onChanged: (bool value) {
            setState(() => _isOriginalContent = value);
          },
          activeColor: emerald,
          activeTrackColor: emerald.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildUploadSection() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: caveShadow.withOpacity(0.3),
        borderRadius: BorderRadius.circular(emeraldCut),
        border: Border.all(
          color: amethyst.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: silver.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Drag and drop your content here\nor click to browse',
              style: gemText.copyWith(
                color: silver.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _submitContent() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: Implement content submission
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Content submitted successfully!',
            style: gemText,
          ),
          backgroundColor: emerald.withOpacity(0.8),
        ),
      );
    }
  }
}

class _CreatorStudioBackgroundPainter extends CustomPainter {
  final double progress;

  _CreatorStudioBackgroundPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          amethyst.withOpacity(0.1),
          sapphire.withOpacity(0.1),
          ruby.withOpacity(0.1),
        ],
        stops: [
          0.0,
          0.5,
          1.0,
        ],
        transform: GradientRotation(progress * 2 * 3.14159),
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_CreatorStudioBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
} 