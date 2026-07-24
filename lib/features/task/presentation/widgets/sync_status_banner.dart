import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:team_workspace/core/constants/app_strings.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_bloc.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_event.dart';
import 'package:team_workspace/features/task/presentation/bloc/sync/sync_state.dart';

/// Banner showing offline / syncing / pending sync status.
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final strings = AppStrings.of(context);

        if (state is SyncOffline) {
          return _Banner(
            color: colorScheme.tertiaryContainer,
            foreground: colorScheme.onTertiaryContainer,
            icon: Icons.cloud_off_outlined,
            label: state.pendingCount > 0
                ? strings.offlinePendingCount(state.pendingCount)
                : strings.youAreOffline,
          );
        }

        if (state is SyncSyncing) {
          return _Banner(
            color: colorScheme.secondaryContainer,
            foreground: colorScheme.onSecondaryContainer,
            icon: Icons.sync,
            label: strings.syncingChanges,
            trailing: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (state is SyncFailure) {
          return _Banner(
            color: colorScheme.errorContainer,
            foreground: colorScheme.onErrorContainer,
            icon: Icons.sync_problem,
            label: strings.resolveMessage(state.message),
            actionLabel: strings.retry,
            onAction: () => context.read<SyncBloc>().add(const RetrySync()),
          );
        }

        if (state is SyncSynced &&
            state.pendingCount > 0 &&
            state.message != null) {
          return _Banner(
            color: colorScheme.primaryContainer,
            foreground: colorScheme.onPrimaryContainer,
            icon: Icons.cloud_upload_outlined,
            label: strings.pendingCountWaiting(state.pendingCount),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.foreground,
    required this.icon,
    required this.label,
    this.trailing,
    this.actionLabel,
    this.onAction,
  });

  final Color color;
  final Color foreground;
  final IconData icon;
  final String label;
  final Widget? trailing;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: label,
      child: Material(
        color: color,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
              if (actionLabel != null && onAction != null)
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ),
        ),
      ),
    );
  }
}
