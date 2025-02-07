import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/gem_theme.dart';
import '../widgets/gem_button.dart';
import '../services/gem_service.dart';
import '../models/gem_model.dart';
import 'dart:ui' as ui;

class GemMetaEditPage extends StatefulWidget {
  final String gemId;
  final GemModel gem;

  const GemMetaEditPage({
    super.key,
    required this.gemId,
    required this.gem,
  });

  @override
  State<GemMetaEditPage> createState() => _GemMetaEditPageState();
}

class _GemMetaEditPageState extends State<GemMetaEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _keywordController = TextEditingController();
  final _gemService = GemService();
  
  List<String> _keywords = [];
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.gem.title;
    _descriptionController.text = widget.gem.description;
    _keywords = List.from(widget.gem.tags);

    // Listen for changes
    _titleController.addListener(_checkForChanges);
    _descriptionController.addListener(_checkForChanges);
  }

  // Monitors changes in title, description, and tags
  // Enables/disables save button based on modifications
  void _checkForChanges() {
    final hasChanges = 
      _titleController.text != widget.gem.title ||
      _descriptionController.text != widget.gem.description ||
      !_areListsEqual(_keywords, widget.gem.tags);

    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  // Utility function to compare two string lists for equality
  // Used to detect changes in tags list
  bool _areListsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Adds a new keyword to the tags list
  // Handles duplicates and empty strings
  void _addKeyword() {
    final keyword = _keywordController.text.trim().toLowerCase();
    if (keyword.isNotEmpty && !_keywords.contains(keyword)) {
      setState(() {
        _keywords.add(keyword);
        _keywordController.clear();
        _checkForChanges();
      });
      HapticFeedback.mediumImpact();
    }
  }

  // Removes a keyword from the tags list
  // Updates UI and save button state
  void _removeKeyword(String keyword) {
    setState(() {
      _keywords.remove(keyword);
      _checkForChanges();
    });
    HapticFeedback.mediumImpact();
  }

  // Saves changes to Firestore
  // Handles loading states and error conditions
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _gemService.updateGem(
        widget.gemId,
        {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'tags': _keywords,
        },
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving changes: $e',
              style: gemText.copyWith(color: Colors.white),
            ),
            backgroundColor: ruby.withOpacity(0.8),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepCave,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Edit Gem Details',
          style: crystalHeading.copyWith(fontSize: 20),
        ),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    amethyst.withOpacity(0.15),
                    deepCave.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  amethyst.withOpacity(0.1),
                  deepCave,
                ],
              ),
            ),
          ),

          // Content
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field
                  Text(
                    'Title',
                    style: gemText.copyWith(
                      color: silver,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    style: gemText.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: caveShadow.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(emeraldCut),
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Description field
                  Text(
                    'Description',
                    style: gemText.copyWith(
                      color: silver,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    style: gemText.copyWith(color: Colors.white),
                    maxLines: 4,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: caveShadow.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(emeraldCut),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Keywords section
                  Text(
                    'Keywords',
                    style: gemText.copyWith(
                      color: silver,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _keywordController,
                          style: gemText.copyWith(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Add keyword...',
                            hintStyle: gemText.copyWith(
                              color: silver.withOpacity(0.5),
                            ),
                            filled: true,
                            fillColor: caveShadow.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(emeraldCut),
                            ),
                          ),
                          onFieldSubmitted: (_) => _addKeyword(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: emerald),
                        onPressed: _addKeyword,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _keywords.map((keyword) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: sapphire.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: sapphire.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              keyword,
                              style: gemText.copyWith(
                                color: silver,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _removeKeyword(keyword),
                              child: const Icon(
                                Icons.close,
                                color: silver,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  // Save button
                  Center(
                    child: GemButton(
                      text: _isSaving ? 'Saving...' : 'Save Changes',
                      onPressed: (_hasChanges && !_isSaving) ? () async {
                        await _saveChanges();
                      } : null,
                      gemColor: emerald,
                      isAnimated: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 