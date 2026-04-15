import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:animations/animations.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/note_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import 'add_edit_note_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.read<AuthViewModel>();
    final noteViewModel = context.watch<NoteViewModel>();
    final themeViewModel = context.watch<ThemeViewModel>();
    final user = authViewModel.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(themeViewModel.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeViewModel.toggleTheme(!themeViewModel.isDarkMode),
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authViewModel.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(isDark),
          _buildCategoryFilter(noteViewModel),
          Expanded(
            child: StreamBuilder<List<Note>>(
              stream: noteViewModel.getNotesStream(user!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allNotes = snapshot.data ?? [];
                
                var filteredNotes = allNotes.where((note) {
                  final matchesSearch = note.title.toLowerCase().contains(_searchQuery) ||
                      note.description.toLowerCase().contains(_searchQuery);
                  final matchesCategory = noteViewModel.selectedCategory == 'All' || 
                      note.category == noteViewModel.selectedCategory;
                  return matchesSearch && matchesCategory;
                }).toList();

                filteredNotes.sort((a, b) {
                  if (a.isPinned && !b.isPinned) return -1;
                  if (!a.isPinned && b.isPinned) return 1;
                  return b.timestamp.compareTo(a.timestamp);
                });

                if (filteredNotes.isEmpty) {
                  return _buildEmptyState();
                }

                return _isGridView 
                  ? _buildGridView(filteredNotes) 
                  : _buildListView(filteredNotes);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: OpenContainer(
        transitionType: ContainerTransitionType.fade,
        openBuilder: (context, _) => const AddEditNoteScreen(),
        closedElevation: 6.0,
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        closedColor: Theme.of(context).colorScheme.primaryContainer,
        closedBuilder: (context, openContainer) => FloatingActionButton(
          onPressed: openContainer,
          elevation: 0,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search your notes',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
      ),
    );
  }

  Widget _buildCategoryFilter(NoteViewModel vm) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: vm.categories.map((category) {
          final isSelected = vm.selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) => vm.setCategory(category),
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, size: 80, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No notes yet' : 'No results found',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<Note> notes) {
    return MasonryGridView.count(
      padding: const EdgeInsets.all(12),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      itemCount: notes.length,
      itemBuilder: (context, index) => _NoteCard(note: notes[index]),
    );
  }

  Widget _buildListView(List<Note> notes) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: notes.length,
      itemBuilder: (context, index) => _NoteCard(note: notes[index]),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final noteViewModel = context.read<NoteViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Adjust colors for dark mode to ensure text is readable
    Color cardColor = Color(note.noteColorFor(isDark));
    
    return OpenContainer(
      closedElevation: 0,
      closedColor: Colors.transparent,
      openBuilder: (context, _) => AddEditNoteScreen(note: note),
      closedBuilder: (context, openContainer) => GestureDetector(
        onTap: openContainer,
        onLongPress: () => _showDeleteDialog(context, noteViewModel),
        child: Card(
          elevation: 0,
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (note.category != 'General')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Colors.black12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          note.category, 
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    if (note.isPinned)
                      Icon(
                        Icons.push_pin, 
                        size: 16, 
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  note.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  note.description,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  DateFormat.yMMMd().format(note.timestamp),
                  style: TextStyle(
                    fontSize: 10, 
                    color: isDark ? Colors.white38 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, NoteViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              vm.deleteNote(note.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

extension NoteColorExtension on Note {
  int noteColorFor(bool isDark) {
    if (!isDark) return color;
    
    // If it's pure white in light mode, use a dark surface color in dark mode
    if (color == 0xFFFFFFFF) return 0xFF1E1E1E;
    
    // For other colors, we can slightly darken/desaturate them for dark mode
    // or use a consistent dark theme mapping.
    // Simple approach: if it's not white, use a semi-transparent overlay of the color
    // or return a specific dark-mode version.
    return color; // We will adjust the opacity in the UI instead for simplicity
  }
}
