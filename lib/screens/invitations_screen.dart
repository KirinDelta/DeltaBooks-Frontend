import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../providers/invitation_provider.dart';
import '../models/invitation.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InvitationProvider>(context, listen: false).fetchInvitations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.invitations),
        backgroundColor: const Color(0xFF1A365D),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.receivedInvitations),
            Tab(text: l10n.sentInvitations),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReceivedInvitationsTab(),
          _SentInvitationsTab(),
        ],
      ),
    );
  }
}

class _ReceivedInvitationsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<InvitationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final invitations = provider.receivedInvitations;

        if (invitations.isEmpty) {
          return Center(
            child: Text(
              l10n.noInvitations,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchInvitations(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              return _InvitationCard(
                invitation: invitation,
                isReceived: true,
              );
            },
          ),
        );
      },
    );
  }
}

class _SentInvitationsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<InvitationProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final invitations = provider.sentInvitations;

        if (invitations.isEmpty) {
          return Center(
            child: Text(
              l10n.noInvitations,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchInvitations(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              return _InvitationCard(
                invitation: invitation,
                isReceived: false,
              );
            },
          ),
        );
      },
    );
  }
}

class _InvitationCard extends StatelessWidget {
  final Invitation invitation;
  final bool isReceived;

  const _InvitationCard({
    required this.invitation,
    required this.isReceived,
  });

  String _getStatusText(String status, AppLocalizations l10n) {
    switch (status) {
      case 'pending':
        return l10n.pending;
      case 'accepted':
        return l10n.accepted;
      case 'rejected':
        return l10n.rejected;
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleAction(
    BuildContext context,
    InvitationProvider provider,
    String action,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    bool success = false;
    String message = '';

    switch (action) {
      case 'accept':
        success = await provider.acceptInvitation(invitation.id);
        message = success ? l10n.invitationAccepted : l10n.invitationError;
        break;
      case 'reject':
        success = await provider.rejectInvitation(invitation.id);
        message = l10n.invitationRejected;
        break;
      case 'cancel':
        success = await provider.cancelInvitation(invitation.id);
        message = l10n.invitationCanceled;
        break;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<InvitationProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: _getStatusColor(invitation.status),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isReceived
                            ? '${l10n.inviteFrom} ${invitation.senderEmail}'
                            : '${l10n.inviteTo} ${invitation.receiverEmail}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (invitation.libraryName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.forLibrary} "${invitation.libraryName}"',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        _getStatusText(invitation.status, l10n),
                        style: TextStyle(
                          color: _getStatusColor(invitation.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (invitation.isPending && isReceived) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _handleAction(context, provider, 'reject'),
                    child: Text(l10n.reject),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _handleAction(context, provider, 'accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A365D),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(l10n.accept),
                  ),
                ],
              ),
            ],
            if (invitation.isPending && !isReceived) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _handleAction(context, provider, 'cancel'),
                    child: Text(l10n.cancel),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
