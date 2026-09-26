import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/security/lock_screen.dart';
import '../providers/settings_providers.dart';

class AppLockWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockWrapper({super.key, required this.child});

  @override
  ConsumerState<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends ConsumerState<AppLockWrapper> with WidgetsBindingObserver {
  bool _isUnlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final isLockEnabled = ref.read(appLockEnabledProvider).value ?? false;
      if (isLockEnabled) {
        setState(() => _isUnlocked = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockEnabledAsync = ref.watch(appLockEnabledProvider);

    return lockEnabledAsync.when(
      loading: () => widget.child,
      error: (_, __) => widget.child,
      data: (isLocked) {
        if (!isLocked || _isUnlocked) {
          return widget.child;
        }

        return LockScreen(
          onUnlocked: () {
            setState(() => _isUnlocked = true);
          },
        );
      },
    );
  }
}
