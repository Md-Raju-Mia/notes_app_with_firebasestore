import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/note_viewmodel.dart';

class AddEditNoteScreen extends StatefulWidget {
  final Note? note;

  const AddEditNoteScreen({super.key, this.note});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _selectedColor = 0xFFFFFFFF;
  String _selectedCategory = 'General';
  bool _isPinned = false;

  final List<int> _colors = [
    0xFFFFFFFF, // White
    0xFFFFCDD2, // Red
    0xFFF8BBD0, // Pink
    0xFFE1BEE7, // Purple
    0xFFD1C4E9, // Deep Purple
    0xFFC5CAE9, // Indigo
    0xFFBBDEFB, // Blue
    0xFFB3E5FC, // Light Blue
    0xFFB2EBF2, // Cyan
    0xFFB2DFDB, // Teal
    0xFFC8E6C9, // Green
    0xFFDCEDC8, // Light Green
    0xFFF0F4C3, // Lime
    0xFFFFF9C4, // Yellow
    0xFFFFECB3, // Amber
    0xFFFFE0B2, // Orange
    0xFFFFCCBC, // Deep Orange
  ];

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _descriptionController.text = widget.note!.description;
      _selectedColor = widget.note!.color;
      _selectedCategory = widget.note!.category;
      _isPinned = widget.note!.isPinned;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveNote() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    final noteViewModel = context.read<NoteViewModel>();
    final authViewModel = context.read<AuthViewModel>();

    try {
      if (widget.note == null) {
        final newNote = Note(
          id: '',
          title: title,
          description: description,
          timestamp: DateTime.now(),
          userId: authViewModel.user!.uid,
          color: _selectedColor,
          category: _selectedCategory,
          isPinned: _isPinned,
        );
        await noteViewModel.addNote(newNote);
      } else {
        final updatedNote = widget.note!.copyWith(
          title: title,
          description: description,
          timestamp: DateTime.now(),
          color: _selectedColor,
          category: _selectedCategory,
          isPinned: _isPinned,
        );
        await noteViewModel.updateNote(updatedNote);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save note: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NoteViewModel>();
    
    return Scaffold(
      backgroundColor: Color(_selectedColor),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: () => setState(() => _isPinned = !_isPinned),
            tooltip: 'Pin Note',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveNote,
            tooltip: 'Save Note',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildToolBar(vm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ListView(
                children: [
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: 'Title',
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: null,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      hintText: 'Start typing...',
                      border: InputBorder.none,
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

  Widget _buildToolBar(NoteViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                final color = _colors[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color ? Colors.black : Colors.black12,
                        width: _selectedColor == color ? 2 : 1,
                      ),
                    ),
                    child: _selectedColor == color 
                      ? const Icon(Icons.check, size: 16) 
                      : null,
                  ),
                );
              },
            ),
          ),
          const Divider(height: 16),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: vm.categories.length,
              itemBuilder: (context, index) {
                final cat = vm.categories[index];
                if (cat == 'All') return const SizedBox.shrink();
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedCategory = cat),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
