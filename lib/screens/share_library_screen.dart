import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/invitation_provider.dart';
import '../providers/library_provider.dart';
import '../providers/auth_provider.dart';
import '../models/library.dart';
import '../models/library_member.dart';
import '../theme/app_colors.dart';
import '../widgets/user_avatar.dart';
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
  bool _allowPartnerToAddBooks = true;
  bool _allowPartnerToRemoveBooks = true;

  void _showPermissionsUpdatedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permissions updated'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showPartnerRemovedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Partner removed'),
        duration: Duration(seconds: 2),
      ),
    );
  }

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
    final success = await invitationProvider.sendInvitation(
      receiverId,
      _selectedLibrary!.id,
      canAddBooks: _allowPartnerToAddBooks,
      canRemoveBooks: _allowPartnerToRemoveBooks,
    );

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
      // Always refresh invitations + members when this screen is opened
      final invitationProvider =
          Provider.of<InvitationProvider>(context, listen: false);
      invitationProvider.fetchInvitations();

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
            libraryProvider.fetchLibraryMembers(matchingLibrary.id);
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
            libraryProvider.fetchLibraryMembers(matchingLibrary.id);
          } else if (libraryProvider.libraries.isNotEmpty) {
            setState(() {
              _selectedLibrary = libraryProvider.libraries.first;
            });
            libraryProvider.fetchLibraryMembers(libraryProvider.libraries.first.id);
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
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
                            const Icon(Icons.library_books,
                                size: 48, color: Colors.grey),
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
                                  final refreshedProvider =
                                      Provider.of<LibraryProvider>(context,
                                          listen: false);
                                  await refreshedProvider.fetchLibraries();
                                  if (refreshedProvider.selectedLibrary !=
                                      null) {
                                    setState(() {
                                      _selectedLibrary =
                                          refreshedProvider.selectedLibrary;
                                    });
                                  }
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: Text(l10n.createLibrary),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
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
                    currentSelectedLibrary =
                        libraryProvider.libraries.firstWhere(
                      (lib) => lib.id == _selectedLibrary!.id,
                      orElse: () => libraryProvider.libraries.isNotEmpty
                          ? libraryProvider.libraries.first
                          : _selectedLibrary!,
                    );
                  } else if (libraryProvider.selectedLibrary != null) {
                    currentSelectedLibrary =
                        libraryProvider.libraries.firstWhere(
                      (lib) => lib.id == libraryProvider.selectedLibrary!.id,
                      orElse: () => libraryProvider.libraries.isNotEmpty
                          ? libraryProvider.libraries.first
                          : libraryProvider.selectedLibrary!,
                    );
                  } else if (libraryProvider.libraries.isNotEmpty) {
                    currentSelectedLibrary = libraryProvider.libraries.first;
                  }

                  // Update state if needed to ensure we have a valid selection
                  if (currentSelectedLibrary != null &&
                      (_selectedLibrary == null ||
                          _selectedLibrary!.id != currentSelectedLibrary.id)) {
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
                                libraryProvider
                                    .fetchLibraryMembers(library.id);
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
              // Unified Member List: Active Partners & Pending Invitations
              Consumer2<LibraryProvider, InvitationProvider>(
                builder: (context, libraryProvider, invitationProvider, _) {
                  final selected = _selectedLibrary;
                  if (selected == null) {
                    return const SizedBox.shrink();
                  }

                  // Determine ownership for the current user on this library (use backend-computed field).
                  final isCurrentUserOwner = selected.isOwner;

                  // Active library members come from the members endpoint.
                  final activeMembers = libraryProvider.activeMembers
                      .where((m) => m.libraryId == selected.id)
                      .toList();

                  // Pending invitations come solely from the invitations endpoint.
                  final pendingInvitations = invitationProvider.sentInvitations
                      .where((inv) =>
                          inv.libraryId == selected.id && inv.isPending)
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isCurrentUserOwner) ...[
                        Text(
                          'Only the library owner can manage permissions.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        'Active Partners',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: AppColors.deltaTeal),
                      ),
                      const SizedBox(height: 8),
                      if (libraryProvider.isMembersLoading)
                        const Center(
                            child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ))
                      else if (activeMembers.isEmpty)
                        Text(
                          'No active partners in this library yet. Invite someone below!',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        Column(
                          children: activeMembers
                              .map(
                                (member) => _MemberPermissionsTile(
                                      key: ValueKey(member.id),
                                      member: member,
                                      isCurrentUserOwner: isCurrentUserOwner,
                                    ),
                              )
                              .toList(),
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Pending Invitations',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: AppColors.deltaTeal),
                      ),
                      const SizedBox(height: 8),
                      if (pendingInvitations.isEmpty)
                        Text(
                          'No pending invitations',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Pending invitations (sent) for this library
                            ...pendingInvitations.map(
                              (invitation) => Card(
                                child: ListTile(
                                  leading: const Icon(Icons.mail_outline,
                                      color: Colors.orange),
                                  title: Text(
                                    invitation.receiverEmail,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    invitation.libraryName != null
                                        ? 'Invitation for "${invitation.libraryName}"'
                                        : 'Invitation pending',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              // Email search and new invitation section
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
                            _errorMessage == 'userNotFound'
                                ? l10n.userNotFound
                                : _errorMessage!,
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
                            Icon(Icons.person,
                                size: 32,
                                color:
                                    Theme.of(context).colorScheme.primary),
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
                        // Permission switches
                        SwitchListTile(
                          title: Text(
                            'Allow partner to add books',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.deltaTeal,
                                ),
                          ),
                          value: _allowPartnerToAddBooks,
                          activeColor: AppColors.deepSeaBlue,
                          onChanged: (value) {
                            setState(() {
                              _allowPartnerToAddBooks = value;
                            });
                          },
                        ),
                        SwitchListTile(
                          title: Text(
                            'Allow partner to remove books',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.deltaTeal,
                                ),
                          ),
                          value: _allowPartnerToRemoveBooks,
                          activeColor: AppColors.deepSeaBlue,
                          onChanged: (value) {
                            setState(() {
                              _allowPartnerToRemoveBooks = value;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _sendInvitation,
                          icon: const Icon(Icons.send),
                          label: Text(l10n.sendInvitation),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
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
      ),
    );
  }
}

class _MemberPermissionsTile extends StatefulWidget {
  final LibraryMember member;
  final bool isCurrentUserOwner;

  const _MemberPermissionsTile({
    super.key,
    required this.member,
    required this.isCurrentUserOwner,
  });

  @override
  State<_MemberPermissionsTile> createState() => _MemberPermissionsTileState();
}

class _MemberPermissionsTileState extends State<_MemberPermissionsTile> {
  bool _isUpdating = false;

  Future<void> _handleToggle({
    required bool newCanAdd,
    required bool newCanRemove,
  }) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    final provider = Provider.of<LibraryProvider>(context, listen: false);
    final libraryId = widget.member.libraryId;
    final error = await provider.updateMemberPermissions(
      libraryId,
      widget.member.id,
      newCanAdd,
      newCanRemove,
    );

    if (!mounted) return;

    setState(() {
      _isUpdating = false;
    });

    final state =
        context.findAncestorStateOfType<_ShareLibraryScreenState>();

    if (error == null) {
      state?._showPermissionsUpdatedSnackBar();
    } else {
      state?._showErrorSnackBar(error);
    }
  }

  Future<void> _handleRemovePartner() async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    final provider = Provider.of<LibraryProvider>(context, listen: false);
    final libraryId = widget.member.libraryId;
    final error = await provider.removeMember(libraryId, widget.member.id);

    if (!mounted) return;

    setState(() {
      _isUpdating = false;
    });

    final state =
        context.findAncestorStateOfType<_ShareLibraryScreenState>();

    if (error == null) {
      state?._showPartnerRemovedSnackBar();
    } else {
      state?._showErrorSnackBar(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final user = member.user;

    // Hide the current user from the "Active Partners" list if the backend
    // happens to include them, but only when the current user is the owner
    // (owners manage others; partners can see themselves).
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (widget.isCurrentUserOwner &&
        auth.user != null &&
        user.id == auth.user!.id) {
      return const SizedBox.shrink();
    }
    final nameBuffer = StringBuffer();
    if (user.firstName != null && user.firstName!.isNotEmpty) {
      nameBuffer.write(user.firstName);
    }
    if (user.lastName != null && user.lastName!.isNotEmpty) {
      if (nameBuffer.isNotEmpty) {
        nameBuffer.write(' ');
      }
      nameBuffer.write(user.lastName);
    }

    final displayName = nameBuffer.isNotEmpty ? nameBuffer.toString() : null;
    final isOwnerMember = member.isOwner;
    final canManage = widget.isCurrentUserOwner && !isOwnerMember;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: UserAvatar(
              firstName: user.firstName,
              lastName: user.lastName,
              email: user.email,
              size: 32,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    displayName ?? user.email,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.deltaTeal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isOwnerMember) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.goldLeaf.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.goldLeaf, width: 1),
                    ),
                    child: const Text(
                      'Owner',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldLeaf,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: displayName != null
                ? Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  )
                : null,
            trailing: !canManage
                ? null
                : (_isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: _handleRemovePartner,
                        child: const Text(
                          'Remove',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )),
          ),
          // Permission controls: interactive for owners, read-only for non-owners.
          if (canManage)
            SwitchListTile(
              title: Text(
                'Can Add Books',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.deltaTeal,
                    ),
              ),
              value: member.canAddBooks,
              activeColor: AppColors.deepSeaBlue,
              onChanged: (value) {
                if (_isUpdating) return;
                _handleToggle(
                  newCanAdd: value,
                  newCanRemove: member.canRemoveBooks,
                );
              },
            )
          else
            SwitchListTile(
              title: Text(
                'Can Add Books',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.deltaTeal,
                    ),
              ),
              value: member.canAddBooks,
              activeColor: AppColors.deepSeaBlue,
              onChanged: null,
            ),
          if (canManage)
            SwitchListTile(
              title: Text(
                'Can Remove Books',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.deltaTeal,
                    ),
              ),
              value: member.canRemoveBooks,
              activeColor: AppColors.deepSeaBlue,
              onChanged: (value) {
                if (_isUpdating) return;
                _handleToggle(
                  newCanAdd: member.canAddBooks,
                  newCanRemove: value,
                );
              },
            )
          else
            SwitchListTile(
              title: Text(
                'Can Remove Books',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.deltaTeal,
                    ),
              ),
              value: member.canRemoveBooks,
              activeColor: AppColors.deepSeaBlue,
              onChanged: null,
            ),
        ],
      ),
    );
  }
}

