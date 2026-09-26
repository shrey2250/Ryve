import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// State of an in-app update check
enum UpdateCheckState {
  initial,
  checking,
  upToDate,
  updateAvailable,
  downloading,
  readyToRestart,
  error,
}

class AppUpdateState {
  final UpdateCheckState state;
  final int? currentPatchNumber;
  final String? version;
  final String? title;
  final String? releaseNotes;
  final String? errorMessage;

  const AppUpdateState({
    this.state = UpdateCheckState.initial,
    this.currentPatchNumber,
    this.version,
    this.title,
    this.releaseNotes,
    this.errorMessage,
  });

  bool get hasUpdate => state == UpdateCheckState.updateAvailable;
  bool get isDownloading => state == UpdateCheckState.downloading;
  bool get isReadyToRestart => state == UpdateCheckState.readyToRestart;

  AppUpdateState copyWith({
    UpdateCheckState? state,
    int? currentPatchNumber,
    String? version,
    String? title,
    String? releaseNotes,
    String? errorMessage,
  }) {
    return AppUpdateState(
      state: state ?? this.state,
      currentPatchNumber: currentPatchNumber ?? this.currentPatchNumber,
      version: version ?? this.version,
      title: title ?? this.title,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      errorMessage: errorMessage,
    );
  }
}

class UpdateService extends StateNotifier<AppUpdateState> {
  UpdateService() : super(const AppUpdateState()) {
    _init();
  }

  final ShorebirdUpdater _updater = ShorebirdUpdater();
  static const String _versionUrl =
      'https://raw.githubusercontent.com/shrey2250/Ryve/main/version.json';

  Future<void> _init() async {
    try {
      final currentPatch = await _updater.readCurrentPatch();
      state = state.copyWith(currentPatchNumber: currentPatch?.number);
    } catch (_) {}
  }

  /// Checks if a Shorebird patch or new version is available.
  Future<bool> checkForUpdates({bool isManual = false}) async {
    state = state.copyWith(state: UpdateCheckState.checking);

    try {
      // 1. Check Shorebird OTA status
      final status = await _updater.checkForUpdate();
      final currentPatch = await _updater.readCurrentPatch();

      // 2. Fetch Release Notes metadata from GitHub
      Map<String, dynamic>? meta;
      try {
        final res = await http.get(Uri.parse(_versionUrl)).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          meta = jsonDecode(res.body) as Map<String, dynamic>;
        }
      } catch (_) {}

      final versionStr = meta?['version'] as String? ?? '1.0.1';
      final titleStr = meta?['title'] as String? ?? 'New Feature & Stability Update';
      final notesStr = meta?['releaseNotes'] as String? ??
          '• Added Online payment & account tracking\n• Database performance improvements\n• Fluid motion & UI refinements';

      if (status == UpdateStatus.outdated) {
        state = state.copyWith(
          state: UpdateCheckState.updateAvailable,
          currentPatchNumber: currentPatch?.number,
          version: versionStr,
          title: titleStr,
          releaseNotes: notesStr,
        );
        return true;
      } else if (status == UpdateStatus.restartRequired) {
        state = state.copyWith(
          state: UpdateCheckState.readyToRestart,
          currentPatchNumber: currentPatch?.number,
          version: versionStr,
          title: titleStr,
          releaseNotes: notesStr,
        );
        return true;
      } else {
        state = state.copyWith(
          state: UpdateCheckState.upToDate,
          currentPatchNumber: currentPatch?.number,
          version: versionStr,
        );
        return false;
      }
    } catch (e) {
      debugPrint('[UpdateService] Update check failed: $e');
      state = state.copyWith(
        state: UpdateCheckState.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Downloads the update and marks ready to restart
  Future<void> downloadUpdate() async {
    state = state.copyWith(state: UpdateCheckState.downloading);

    try {
      await _updater.update();
      state = state.copyWith(state: UpdateCheckState.readyToRestart);
    } catch (e) {
      debugPrint('[UpdateService] Update download failed: $e');
      state = state.copyWith(
        state: UpdateCheckState.error,
        errorMessage: 'Failed to download update: $e',
      );
    }
  }
}

final updateServiceProvider = StateNotifierProvider<UpdateService, AppUpdateState>((ref) {
  return UpdateService();
});
