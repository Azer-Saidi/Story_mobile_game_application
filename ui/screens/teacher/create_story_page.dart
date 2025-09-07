import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:storyapp/models/teacher_model.dart';
import '../../../models/story_model.dart';
import '../../../services/firestore_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/gemini_service_t.dart';

class CreateStoryPage extends StatefulWidget {
  final StoryModel? initialData;
  final Teacher teacher;
  final bool isRootNode;
  final CloudinaryService cloudinaryService;

  const CreateStoryPage({
    super.key,
    required this.cloudinaryService,
    this.initialData,
    required this.teacher,
    this.isRootNode = true,
    required String authorId,
  });

  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final Uuid _uuid = const Uuid();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _imagePicker = ImagePicker();
  final GeminiService _geminiService = GeminiService();
  late StoryModel _story;
  bool _isSaving = false;
  bool _isGenerating = false;
  final TextEditingController _pointsController = TextEditingController();
  final TextEditingController _storyContentController = TextEditingController();
  final TextEditingController _geminiPromptController = TextEditingController();

  // Animation controllers for improved UI
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeStoryData();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _storyContentController.dispose();
    _geminiPromptController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _initializeStoryData() {
    if (widget.initialData != null) {
      _story = widget.initialData!;
      _pointsController.text = _story.pointsToUnlock.toString();
      _storyContentController.text = _story.content;
    } else {
      _story = StoryModel(
        id: _uuid.v4(),
        title: '',
        content: '',
        authorId: widget.teacher.id,
        createdAt: DateTime.now(),
        choices: [],
        type: StoryType.allTypes.first,
        description: '', // Added description field
      );
      _pointsController.text = '0';
      _storyContentController.text = '';
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isSaving = true);

    try {
      _story.type = _story.type.toLowerCase();
      _story.content = _storyContentController.text;

      if (_story.imageFile != null) {
        _story.imageUrl = await widget.cloudinaryService.uploadFile(
          file: _story.imageFile!,
          folder: 'stories/${_story.id}',
          resourceType: 'image',
        );
      }
      if (_story.audioFile != null) {
        _story.audioUrl = await widget.cloudinaryService.uploadFile(
          file: _story.audioFile!,
          folder: 'stories/${_story.id}',
          resourceType: 'audio',
        );
      }
      if (widget.isRootNode) {
        await _firestoreService.saveStory(_story);
      }
      if (mounted) {
        _showSuccessSnackBar('Story saved successfully!');
        Navigator.pop(context, _story);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error saving story: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showGeminiPromptDialog() {
    _geminiPromptController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.purple.shade50, Colors.blue.shade50],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    size: 32,
                    color: Colors.purple.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Generate with AI',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Describe your story concept and let AI create an interactive adventure!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _geminiPromptController,
                  autofocus: true,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Story Concept',
                    hintText: 'Ex: A pirate adventure on a magical island...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.lightbulb_outline),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_geminiPromptController.text.trim().isNotEmpty) {
                            Navigator.pop(context);
                            _generateFullStoryTree();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Generate'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateFullStoryTree() async {
    setState(() => _isGenerating = true);

    try {
      final storyTree = await _geminiService.generateStoryTree(
        _geminiPromptController.text,
      );

      if (storyTree.containsKey('error')) {
        _showErrorSnackBar(storyTree['error']);
      } else {
        final rootStory = _parseStoryNode(storyTree, isRoot: true);
        setState(() {
          _story = rootStory;
          _storyContentController.text = _story.content;
        });

        _showSuccessSnackBar('Story tree generated successfully!');
      }
    } catch (e) {
      _showErrorSnackBar('Generation error: $e');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  StoryModel _parseStoryNode(Map<String, dynamic> node, {bool isRoot = false}) {
    return StoryModel(
      id: _uuid.v4(),
      title: node['title']?.toString() ?? 'Untitled',
      content: node['content']?.toString() ?? '',
      authorId: widget.teacher.id,
      createdAt: DateTime.now(),
      choices:
          (node['choices'] as List?)?.map((choice) {
            final child = choice['child'] as Map<String, dynamic>?;
            return StoryChoice(
              id: _uuid.v4(),
              label: choice['label']?.toString() ?? 'Choice',
              child: child != null ? _parseStoryNode(child) : null,
            );
          }).toList() ??
          [],
      type: isRoot ? _story.type : 'branch',
      description: node['description']?.toString() ?? '', // Added description
    );
  }

  void _addChoice() {
    if (_story.choices.length >= 3) return;
    setState(() {
      _story.choices.add(StoryChoice(id: _uuid.v4(), label: ''));
    });
  }

  void _editChild(int index) async {
    _formKey.currentState?.save();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateStoryPage(
          cloudinaryService: widget.cloudinaryService,
          teacher: widget.teacher,
          initialData: _story.choices[index].child,
          isRootNode: false,
          authorId: widget.teacher.id,
        ),
      ),
    );
    if (result != null && result is StoryModel) {
      setState(() => _story.choices[index].child = result);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() => _story.imageFile = File(pickedFile.path));
    }
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() => _story.audioFile = File(result.files.single.path!));
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            color: _story.imageFile != null
                ? Colors.green.shade50
                : Colors.grey.shade50,
          ),
          child: InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _story.imageFile != null
                      ? Icons.check_circle
                      : Icons.add_photo_alternate,
                  size: 32,
                  color: _story.imageFile != null
                      ? Colors.green.shade600
                      : Colors.grey.shade600,
                ),
                const SizedBox(height: 8),
                Text(
                  _story.imageFile != null ? 'File Selected' : 'Add Image',
                  style: TextStyle(
                    color: _story.imageFile != null
                        ? Colors.green.shade600
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_story.imageFile != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                _story.imageFile = null;
                _story.imageUrl = '';
              }),
              icon: const Icon(Icons.delete, size: 16),
              label: const Text('Remove'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required File? file,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            color: file != null ? Colors.green.shade50 : Colors.grey.shade50,
          ),
          child: InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  file != null ? Icons.check_circle : icon,
                  size: 32,
                  color: file != null
                      ? Colors.green.shade600
                      : Colors.grey.shade600,
                ),
                const SizedBox(height: 8),
                Text(
                  file != null ? 'File Selected' : 'Add $label',
                  style: TextStyle(
                    color: file != null
                        ? Colors.green.shade600
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (file != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.delete, size: 16),
              label: const Text('Remove'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _choiceTile(int index) {
    final choice = _story.choices[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: choice.label,
                    decoration: const InputDecoration(
                      labelText: 'Choice Text',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (val) => choice.label = val,
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      setState(() => _story.choices.removeAt(index)),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Remove Choice',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editChild(index),
                    icon: Icon(
                      choice.child != null ? Icons.edit : Icons.add,
                      size: 16,
                    ),
                    label: Text(
                      choice.child != null ? 'Edit Branch' : 'Add Branch',
                    ),
                  ),
                ),
                if (choice.child != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => setState(() => choice.child = null),
                    icon: const Icon(Icons.clear, color: Colors.orange),
                    tooltip: 'Remove Branch',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.isRootNode ? 'Create Story' : 'Edit Story Branch'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: widget.isRootNode
            ? [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade400,
                            Colors.blue.shade400,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: _isGenerating ? null : _showGeminiPromptDialog,
                    tooltip: 'Generate with AI',
                  ),
                ),
              ]
            : null,
      ),
      floatingActionButton: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: FloatingActionButton.extended(
          onPressed: _isSaving ? null : _submitForm,
          backgroundColor: _isSaving ? Colors.grey : Colors.green.shade600,
          label: Text(
            _isSaving ? "SAVING..." : "SAVE",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.save),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                if (_isGenerating)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade50, Colors.blue.shade50],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.purple.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Generating...',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                              Text(
                                'AI is creating your interactive story',
                                style: TextStyle(color: Colors.purple.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                _buildSectionHeader('Core Details', Icons.article_outlined),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: TextEditingController(text: _story.title),
                          decoration: InputDecoration(
                            labelText: 'Story Title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.title),
                          ),
                          onChanged: (val) => _story.title = val,
                          validator: (val) => val!.isEmpty ? 'Required' : null,
                        ),
                        if (widget.isRootNode) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _story.type,
                            decoration: InputDecoration(
                              labelText: 'Story Type',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.category),
                            ),
                            items: StoryType.allTypes
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(
                                      type[0].toUpperCase() + type.substring(1),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setState(
                              () => _story.type =
                                  value ?? StoryType.allTypes.first,
                            ),
                            onSaved: (value) =>
                                _story.type = value ?? StoryType.allTypes.first,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: TextEditingController(
                              text: _story.description,
                            ),
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Short Description',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.description),
                            ),
                            onChanged: (val) => _story.description = val,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                if (widget.isRootNode) ...[
                  _buildSectionHeader(
                    'Monetization',
                    Icons.monetization_on_outlined,
                  ),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextFormField(
                        controller: _pointsController,
                        decoration: InputDecoration(
                          labelText: 'Points to Unlock',
                          hintText: 'Enter 0 for a free story',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.stars_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (val) =>
                            _story.pointsToUnlock = int.tryParse(val) ?? 0,
                      ),
                    ),
                  ),
                ],

                _buildSectionHeader('Story Content', Icons.edit_document),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextFormField(
                      controller: _storyContentController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        labelText: 'Full Story Text',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 140),
                          child: Icon(Icons.edit),
                        ),
                      ),
                      onChanged: (val) => _story.content = val,
                    ),
                  ),
                ),

                _buildSectionHeader(
                  'Media Attachments',
                  Icons.perm_media_outlined,
                ),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(child: _buildImageSection()),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMediaButton(
                            icon: Icons.audiotrack,
                            label: 'Audio',
                            file: _story.audioFile,
                            onPick: _pickAudio,
                            onClear: () => setState(() {
                              _story.audioFile = null;
                              _story.audioUrl = '';
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                _buildSectionHeader('Story Choices', Icons.call_split),
                if (_story.choices.isEmpty)
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.call_split,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No choices added yet",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Add a choice to create a branching path.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ...List.generate(_story.choices.length, _choiceTile),
                if (_story.choices.length < 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      onPressed: _addChoice,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Choice'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
