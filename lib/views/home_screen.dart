import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:animations/animations.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/note_viewmodel.dart';
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
    final user = authViewModel.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
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
          _buildSearchBar(),
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
                
                // Filtering
                var filteredNotes = allNotes.where((note) {
                  final matchesSearch = note.title.toLowerCase().contains(_searchQuery) ||
                      note.description.toLowerCase().contains(_searchQuery);
                  final matchesCategory = noteViewModel.selectedCategory == 'All' || 
                      note.category == noteViewModel.selectedCategory;
                  return matchesSearch && matchesCategory;
                }).toList();

                // Sorting: Pinned first, then by timestamp
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search your notes',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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
          Icon(Icons.note_alt_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
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
    
    return OpenContainer(
      closedElevation: 0,
      closedColor: Colors.transparent,
      openBuilder: (context, _) => AddEditNoteScreen(note: note),
      closedBuilder: (context, openContainer) => GestureDetector(
        onTap: openContainer,
        onLongPress: () => _showDeleteDialog(context, noteViewModel),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          color: Color(note.color).withOpacity(0.9),
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
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(note.category, style: const TextStyle(fontSize: 10)),
                      ),
                    if (note.isPinned)
                      const Icon(Icons.push_pin, size: 16, color: Colors.black54),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  note.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  note.description,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.black.withOpacity(0.7)),
                ),
                const SizedBox(height: 10),
                Text(
                  DateFormat.yMMMd().format(note.timestamp),
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
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
