import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import '../../models/admin_feature_flag.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_colors.dart';

class AdminFeatureFlagsScreen extends StatefulWidget {
  const AdminFeatureFlagsScreen({super.key});

  @override
  State<AdminFeatureFlagsScreen> createState() => _AdminFeatureFlagsScreenState();
}

class _AdminFeatureFlagsScreenState extends State<AdminFeatureFlagsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchFeatureFlags();
    });
  }

  Future<void> _onRefresh() => context.read<AdminProvider>().fetchFeatureFlags();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminFeatureFlags),
        backgroundColor: AppColors.deepSeaBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _onRefresh,
            tooltip: l10n.retry,
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          if (provider.isFlagsLoading && provider.featureFlags.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.flagsError != null && provider.featureFlags.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    provider.flagsError!,
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearFlagsError();
                      _onRefresh();
                    },
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          if (provider.featureFlags.isEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        l10n.noFeatureFlags,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.featureFlags.length,
              itemBuilder: (context, index) {
                return _FlagCard(flag: provider.featureFlags[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _FlagCard extends StatefulWidget {
  final AdminFeatureFlag flag;

  const _FlagCard({required this.flag});

  @override
  State<_FlagCard> createState() => _FlagCardState();
}

class _FlagCardState extends State<_FlagCard> {
  bool _isActing = false;

  Future<void> _act(Future<bool> Function() action, String successMsg) async {
    setState(() => _isActing = true);
    final ok = await action();
    if (mounted) {
      setState(() => _isActing = false);
      final provider = context.read<AdminProvider>();
      if (ok) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(successMsg)));
      } else {
        final err = provider.flagsError ?? AppLocalizations.of(context)!.errorUpdatingFlag;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        provider.clearFlagsError();
      }
    }
  }

  void _showActorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ActorSheet(
        flag: widget.flag,
        onActed: (msg) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          }
        },
      ),
    );
  }

  void _showPercentageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _PercentageDialog(
        flag: widget.flag,
        onActed: (msg) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final flag = widget.flag;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: name + state badge ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    flag.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.deltaTeal,
                    ),
                  ),
                ),
                _StateBadge(state: flag.state),
              ],
            ),

            const SizedBox(height: 12),

            // ── Global toggle ──
            _isActing
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: flag.isOn
                            ? OutlinedButton.icon(
                                onPressed: () => _act(
                                  () => context.read<AdminProvider>().disableFlag(flag.name),
                                  l10n.flagUpdated,
                                ),
                                icon: const Icon(Icons.toggle_off_outlined,
                                    color: Colors.red, size: 18),
                                label: Text(l10n.disableGlobally,
                                    style: const TextStyle(color: Colors.red)),
                                style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.red)),
                              )
                            : ElevatedButton.icon(
                                onPressed: () => _act(
                                  () => context.read<AdminProvider>().enableFlag(flag.name),
                                  l10n.flagUpdated,
                                ),
                                icon: const Icon(Icons.toggle_on_outlined, size: 18),
                                label: Text(l10n.enableGlobally),
                              ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showActorSheet(context),
                        icon: const Icon(Icons.people_outline, size: 18),
                        label: Text(l10n.manageFlagActors),
                      ),
                    ],
                  ),

            // ── Details: actors + percentage ──
            if (flag.enabledActors.isNotEmpty || flag.percentageOfActors != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 10),
            ],

            if (flag.enabledActors.isNotEmpty) ...[
              Text(
                l10n.enabledForUsers,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: flag.enabledActors
                    .map((a) => Chip(
                          label: Text(a, style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor:
                              AppColors.deepSeaBlue.withValues(alpha: 0.08),
                        ))
                    .toList(),
              ),
            ],

            if (flag.percentageOfActors != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.pie_chart_outline,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    l10n.percentageActors(flag.percentageOfActors!),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _act(
                      () => context
                          .read<AdminProvider>()
                          .disablePercentageOfActors(flag.name),
                      l10n.percentageDisabled,
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.red),
                  ),
                ],
              ),
            ],

            // ── Percentage setter ──
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showPercentageDialog(context),
              icon: const Icon(Icons.percent, size: 14),
              label: Text(
                flag.percentageOfActors != null
                    ? l10n.setPercentage
                    : l10n.setPercentage,
                style: const TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  final String state;

  const _StateBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String label;

    switch (state) {
      case 'on':
        color = Colors.green;
        label = l10n.flagOn;
        break;
      case 'conditional':
        color = Colors.amber.shade700;
        label = l10n.flagConditional;
        break;
      default:
        color = AppColors.textTertiary;
        label = l10n.flagOff;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Bottom sheet: enable / disable for a specific user ────────────────────────

class _ActorSheet extends StatefulWidget {
  final AdminFeatureFlag flag;
  final void Function(String message) onActed;

  const _ActorSheet({required this.flag, required this.onActed});

  @override
  State<_ActorSheet> createState() => _ActorSheetState();
}

class _ActorSheetState extends State<_ActorSheet> {
  final _emailController = TextEditingController();
  bool _isActing = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit(bool enable) async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = AppLocalizations.of(context)!.email);
      return;
    }
    setState(() {
      _isActing = true;
      _error = null;
    });

    final provider = context.read<AdminProvider>();
    final ok = enable
        ? await provider.enableFlagForUser(widget.flag.name, email)
        : await provider.disableFlagForUser(widget.flag.name, email);

    if (!mounted) return;
    setState(() => _isActing = false);

    if (ok) {
      final l10n = AppLocalizations.of(context)!;
      Navigator.pop(context);
      widget.onActed(enable
          ? l10n.enableForUserSuccess(email)
          : l10n.disableForUserSuccess(email));
    } else {
      setState(() => _error = provider.flagsError ?? 'Error');
      provider.clearFlagsError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.manageFlagActors}: ${widget.flag.name}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.deltaTeal,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.email,
              hintText: 'user@example.com',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 16),
          if (_isActing)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _submit(true),
                    child: Text(l10n.enableForUser),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _submit(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: Text(l10n.disableForUser),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Dialog: set percentage of actors ─────────────────────────────────────────

class _PercentageDialog extends StatefulWidget {
  final AdminFeatureFlag flag;
  final void Function(String message) onActed;

  const _PercentageDialog({required this.flag, required this.onActed});

  @override
  State<_PercentageDialog> createState() => _PercentageDialogState();
}

class _PercentageDialogState extends State<_PercentageDialog> {
  late final TextEditingController _controller;
  bool _isActing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.flag.percentageOfActors?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final raw = int.tryParse(_controller.text.trim());
    if (raw == null || raw < 0 || raw > 100) {
      setState(() => _error = l10n.invalidPercentage);
      return;
    }
    setState(() {
      _isActing = true;
      _error = null;
    });

    final provider = context.read<AdminProvider>();
    final ok = await provider.enablePercentageOfActors(widget.flag.name, raw);
    if (!mounted) return;
    setState(() => _isActing = false);

    if (ok) {
      Navigator.pop(context);
      widget.onActed(l10n.percentageUpdated);
    } else {
      setState(() => _error = provider.flagsError ?? l10n.errorUpdatingFlag);
      provider.clearFlagsError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.setPercentage),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.percentageHint,
              errorText: _error,
              suffixText: '%',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        if (_isActing)
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          ElevatedButton(
            onPressed: _submit,
            child: Text(l10n.confirm),
          ),
      ],
    );
  }
}
