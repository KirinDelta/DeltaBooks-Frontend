import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/invitation_provider.dart';
import '../providers/library_provider.dart';
import '../models/library.dart';
import 'libraries_screen.dart';

class ShareLibraryScreen extends StatefulWidget {
  final Library? selectedLibrary;
  
  const ShareLibraryScreen({super.key, this.selectedLibrary});

  @override
  State<ShareLibraryScreen> createState() => _ShareLibraryScreenState();
}

class _ShareLibraryScreenState extends State<ShareLibraryScreen> {
  final _emailController = TextEditingController();
  bool _isSearching = false;
  Map<String, dynamic>? _foundUser;
  String? _errorMessage;
  Library? _selectedLibrary;

  Future<void> _searchUser() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = null;
        _foundUser = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _foundUser = null;
    });

    final invitationProvider = Provider.of<InvitationProvider>(context, listen: false);
    final user = await invitationProvider.searchUserByEmail(email);

    if (mounted) {
      setState(() {
        _isSearching = false;
        if (user != null) {
          _foundUser = user;
        } else {
          _errorMessage = 'userNotFound';
        }
      });
    }
  }

  Future<void> _sendInvitation() async {
    if (_foundUser == null || _selectedLibrary == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectLibraryFirst)),
      );
      return;
    }

    final invitationProvider = Provider.of<InvitationProvider>(context, listen: false);
    final receiverId = _foundUser!['id'] as int;
    final success = await invitationProvider.sendInvitation(receiverId, _selectedLibrary!.id);

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.invitationSent)),
        );
        setState(() {
          _foundUser = null;
          _emailController.clear();
        });
        // Refresh invitations list
        await invitationProvider.fetchInvitations();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.invitationError)),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize library selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
      libraryProvider.fetchLibraries().then((_) {
        if (mounted) {
          // Use provided library or find matching one from list
          if (widget.selectedLibrary != null) {
            final matchingLibrary = libraryProvider.libraries.firstWhere(
              (lib) => lib.id == widget.selectedLibrary!.id,
              orElse: () => widget.selectedLibrary!,
            );
            setState(() {
              _selectedLibrary = matchingLibrary;
            });
          } else if (libraryProvider.selectedLibrary != null) {
            final matchingLibrary = libraryProvider.libraries.firstWhere(
              (lib) => lib.id == libraryProvider.selectedLibrary!.id,
              orElse: () => libraryProvider.libraries.isNotEmpty 
                  ? libraryProvider.libraries.first 
                  : libraryProvider.selectedLibrary!,
            );
            setState(() {
              _selectedLibrary = matchingLibrary;
            });
          } else if (libraryProvider.libraries.isNotEmpty) {
            setState(() {
              _selectedLibrary = libraryProvider.libraries.first;
            });
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.searchUser),
        backgroundColor: const Color(0xFF1A365D),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Consumer<LibraryProvider>(
              builder: (context, libraryProvider, _) {
                if (libraryProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (libraryProvider.libraries.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.library_books, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noLibraries,
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.createLibraryFirst,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LibrariesScreen(),
                                ),
                              );
                              // Refresh libraries after returning
                              if (mounted) {
                                final libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
                                await libraryProvider.fetchLibraries();
                                if (libraryProvider.selectedLibrary != null) {
                                  setState(() {
                                    _selectedLibrary = libraryProvider.selectedLibrary;
                                  });
                                }
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: Text(l10n.createLibrary),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A365D),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                // Find the current selected library from the list (by ID to avoid instance mismatch)
                Library? currentSelectedLibrary;
                if (_selectedLibrary != null) {
                  currentSelectedLibrary = libraryProvider.libraries.firstWhere(
                    (lib) => lib.id == _selectedLibrary!.id,
                    orElse: () => libraryProvider.libraries.isNotEmpty 
                        ? libraryProvider.libraries.first 
                        : _selectedLibrary!,
                  );
                } else if (libraryProvider.selectedLibrary != null) {
                  currentSelectedLibrary = libraryProvider.libraries.firstWhere(
                    (lib) => lib.id == libraryProvider.selectedLibrary!.id,
                    orElse: () => libraryProvider.libraries.isNotEmpty 
                        ? libraryProvider.libraries.first 
                        : libraryProvider.selectedLibrary!,
                  );
                } else if (libraryProvider.libraries.isNotEmpty) {
                  currentSelectedLibrary = libraryProvider.libraries.first;
                }
                
                // Update state if needed to ensure we have a valid selection
                if (currentSelectedLibrary != null && (_selectedLibrary == null || _selectedLibrary!.id != currentSelectedLibrary.id)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _selectedLibrary = currentSelectedLibrary;
                      });
                    }
                  });
                }
                
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.selectLibrary,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<Library>(
                          value: currentSelectedLibrary,
                          decoration: InputDecoration(
                            labelText: l10n.library,
                            border: const OutlineInputBorder(),
                          ),
                          items: libraryProvider.libraries.map((library) {
                            return DropdownMenuItem<Library>(
                              value: library,
                              child: Text(library.name),
                            );
                          }).toList(),
                          onChanged: (Library? library) {
                            if (library != null) {
                              setState(() {
                                _selectedLibrary = library;
                              });
                              libraryProvider.selectLibrary(library);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: l10n.email,
                hintText: l10n.searchUserByEmail,
                border: const OutlineInputBorder(),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _isSearching ? null : _searchUser,
                      ),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchUser(),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage == 'userNotFound' ? l10n.userNotFound : _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_foundUser != null) ...[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, size: 32, color: Color(0xFF1A365D)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _foundUser!['email'] as String? ?? '',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_foundUser!['id'] != null)
                                  Text(
                                    'ID: ${_foundUser!['id']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _sendInvitation,
                        icon: const Icon(Icons.send),
                        label: Text(l10n.sendInvitation),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A365D),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
