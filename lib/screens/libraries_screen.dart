import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import '../models/library.dart';

class LibrariesScreen extends StatefulWidget {
  const LibrariesScreen({super.key});

  @override
  State<LibrariesScreen> createState() => _LibrariesScreenState();
}

class _LibrariesScreenState extends State<LibrariesScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  Library? _editingLibrary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LibraryProvider>(context, listen: false).fetchLibraries();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _showCreateDialog() async {
    _nameController.clear();
    _descriptionController.clear();
    _editingLibrary = null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _LibraryDialog(
        nameController: _nameController,
        descriptionController: _descriptionController,
        editingLibrary: null,
      ),
    );

    if (result == true && mounted) {
      final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
      final l10n = AppLocalizations.of(context)!;
      
      final success = await libraryProvider.createLibrary(
        _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? l10n.libraryCreated : l10n.libraryError),
          ),
        );
      }
    }
  }

  Future<void> _showEditDialog(Library library) async {
    _nameController.text = library.name;
    _descriptionController.text = library.description ?? '';
    _editingLibrary = library;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _LibraryDialog(
        nameController: _nameController,
        descriptionController: _descriptionController,
        editingLibrary: library,
      ),
    );

    if (result == true && mounted) {
      final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
      final l10n = AppLocalizations.of(context)!;
      
      final success = await libraryProvider.updateLibrary(
        library.id,
        _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? l10n.libraryUpdated : l10n.libraryError),
          ),
        );
      }
    }
  }

  Future<void> _deleteLibrary(Library library) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteLibrary),
        content: Text('${l10n.deleteLibrary} "${library.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.deleteLibrary),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
      final success = await libraryProvider.deleteLibrary(library.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? l10n.libraryDeleted : l10n.libraryError),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myLibraries),
        backgroundColor: const Color(0xFF1A365D),
        foregroundColor: Colors.white,
      ),
      body: Consumer<LibraryProvider>(
        builder: (context, libraryProvider, _) {
          if (libraryProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (libraryProvider.libraries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.library_books, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noLibraries,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.createLibraryFirst,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => libraryProvider.fetchLibraries(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: libraryProvider.libraries.length,
              itemBuilder: (context, index) {
                final library = libraryProvider.libraries[index];
                final isSelected = libraryProvider.selectedLibrary?.id == library.id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isSelected ? const Color(0xFF1A365D).withOpacity(0.1) : null,
                  child: ListTile(
                    leading: Icon(
                      Icons.library_books,
                      color: isSelected ? const Color(0xFF1A365D) : null,
                    ),
                    title: Text(
                      library.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: library.description != null && library.description!.isNotEmpty
                        ? Text(library.description!)
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(Icons.check_circle, color: Color(0xFF1A365D)),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditDialog(library),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteLibrary(library),
                        ),
                      ],
                    ),
                    onTap: () {
                      libraryProvider.selectLibrary(library);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: const Color(0xFF1A365D),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _LibraryDialog extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final Library? editingLibrary;

  const _LibraryDialog({
    required this.nameController,
    required this.descriptionController,
    this.editingLibrary,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(editingLibrary == null ? l10n.createLibrary : l10n.editLibrary),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.libraryName,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: l10n.libraryDescription,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.enterLibraryName)),
              );
              return;
            }
            Navigator.pop(context, true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A365D),
            foregroundColor: Colors.white,
          ),
          child: Text(editingLibrary == null ? l10n.createLibrary : l10n.editLibrary),
        ),
      ],
    );
  }
}
