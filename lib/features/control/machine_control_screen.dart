import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_scope.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/magic_panel.dart';
import '../../core/widgets/magic_scaffold.dart';
import '../auth/auth_service.dart';
import 'control_models.dart';
import 'machine_control_controller.dart';

/// Machine control: two big buttons, "Start/Resume" and "Stop", plus the state
/// of the machine. The commands go to the server.
class MachineControlScreen extends StatefulWidget {
  const MachineControlScreen({super.key});

  @override
  State<MachineControlScreen> createState() => _MachineControlScreenState();
}

class _MachineControlScreenState extends State<MachineControlScreen> {
  late final MachineControlController _controller;

  @override
  void initState() {
    super.initState();
    final deps = AppScope.of(context);
    _controller = MachineControlController(
      deps.machineControl,
      deps.machineStore.machine,
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _signInAgain() async {
    await AuthService.instance.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MagicScaffold(
      appBar: AppBar(title: Text(l10n.menuMachineControl)),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          final scheme = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _StatusPanel(controller: c, onSignInAgain: _signInAgain),
              const SizedBox(height: 24),
              _BigButton(
                buttonKey: const ValueKey('start-button'),
                label: l10n.startResume,
                icon: Icons.play_arrow_rounded,
                busy: c.sending == MachineCommand.start,
                onPressed: c.canStart ? c.start : null,
              ),
              const SizedBox(height: 16),
              _BigButton(
                buttonKey: const ValueKey('stop-button'),
                label: l10n.stop,
                icon: Icons.stop_rounded,
                busy: c.sending == MachineCommand.stop,
                destructive: true,
                onPressed: c.canStop ? c.stop : null,
              ),
              if (c.commandFailure != null) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.controlFailure(c.commandFailure!),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.error),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.buttonKey,
    required this.label,
    required this.icon,
    required this.busy,
    required this.onPressed,
    this.destructive = false,
  });

  final Key buttonKey;
  final String label;
  final IconData icon;
  final bool busy;
  final bool destructive;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final spinnerColor =
        destructive ? MagicColors.danger : MagicColors.background;
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
                strokeWidth: 3.5, color: spinnerColor),
          )
        else
          Icon(icon, size: 44),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(28));
    const size = Size.fromHeight(112);

    if (destructive) {
      return OutlinedButton(
        key: buttonKey,
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: size,
          shape: shape,
          foregroundColor: MagicColors.danger,
          side: BorderSide(
            color: onPressed == null
                ? MagicColors.danger.withAlpha(90)
                : MagicColors.danger,
            width: 2,
          ),
        ),
        child: content,
      );
    }
    return FilledButton(
      key: buttonKey,
      onPressed: onPressed,
      style: FilledButton.styleFrom(minimumSize: size, shape: shape),
      child: content,
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.controller, required this.onSignInAgain});

  final MachineControlController controller;
  final VoidCallback onSignInAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final c = controller;

    if (!c.hasMachine) {
      return MagicPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.noMachineTitle,
                style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              l10n.noMachineBody,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push('/link-machine'),
              child: Text(l10n.linkMachine),
            ),
          ],
        ),
      );
    }

    if (c.loadFailure != null) {
      final expired = c.loadFailure == MachineControlFailure.unauthorized;
      return MagicPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.controlLoadFailedTitle,
                style: text.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              l10n.controlFailure(c.loadFailure!),
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: expired ? onSignInAgain : c.load,
              child: Text(expired ? l10n.signInAgain : l10n.tryAgain),
            ),
          ],
        ),
      );
    }

    final state = c.state;
    return MagicPanel(
      child: Row(
        children: [
          const Icon(Icons.precision_manufacturing_outlined,
              color: MagicColors.gold, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.machine!.name, style: text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  state == null ? l10n.checkingMachine : l10n.runStateHint(state),
                  style:
                      text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (state == null)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else
            _StateChip(state: state),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});

  final MachineRunState state;

  Color get _color => switch (state) {
        MachineRunState.idle => MagicColors.parchmentMuted,
        MachineRunState.running => const Color(0xFF4CC38A),
        MachineRunState.stopped => MagicColors.gold,
      };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _color),
          ),
          const SizedBox(width: 6),
          Text(
            context.l10n.runStateLabel(state),
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
