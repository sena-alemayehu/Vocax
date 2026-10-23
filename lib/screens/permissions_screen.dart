import 'package:flutter/material.dart';

import '../services/device_service.dart';
import '../theme.dart';

/// Shows what Vocax AI is allowed to do and lets you turn each thing on.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key, required this.device});

  final DeviceService device;

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  Map<String, bool> _status = const {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Coming back from Android settings: re-check everything.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final status = await widget.device.permissionStatus();
    if (!mounted) return;
    setState(() {
      _status = status;
      _loaded = true;
    });
  }

  bool _allowed(String key) => _status[key] == true;

  /// Asks Android; if it will not ask again, opens this app's settings page.
  Future<void> _request(String key) async {
    final granted = await widget.device.requestPermissions([key]);
    if (!granted) {
      await widget.device.openAppSettings();
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: vocaxBackground(context, center: const Alignment(0, -0.8)),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back',
                  color: context.textPrimary,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'App Permissions',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Vocax AI only uses these when you ask it to.',
                  style: TextStyle(fontSize: 16, color: context.textSecondary),
                ),
              ),
              const SizedBox(height: 24),
              _PermissionCard(
                icon: Icons.mic_rounded,
                title: 'Microphone',
                description: 'Needed to hear your voice commands.',
                allowed: _allowed('microphone'),
                loaded: _loaded,
                actionLabel: 'Allow',
                onAction: () => _request('microphone'),
              ),
              _PermissionCard(
                icon: Icons.contacts_rounded,
                title: 'Contacts',
                description: 'Lets you say "Call Mom" or "Text John".',
                allowed: _allowed('contacts'),
                loaded: _loaded,
                actionLabel: 'Allow',
                onAction: () => _request('contacts'),
              ),
              _PermissionCard(
                icon: Icons.call_rounded,
                title: 'Phone calls',
                description: 'Starts a call right away instead of only opening the dialer.',
                allowed: _allowed('phone'),
                loaded: _loaded,
                actionLabel: 'Allow',
                onAction: () => _request('phone'),
              ),
              _PermissionCard(
                icon: Icons.accessibility_new_rounded,
                title: 'Accessibility',
                description:
                    'Lets Vocax AI take screenshots, lock the screen, go back or home, '
                    'scroll and tap inside other apps, and flip Wi-Fi, Bluetooth and '
                    'airplane mode by voice.',
                allowed: _allowed('accessibility'),
                loaded: _loaded,
                actionLabel: 'Turn on',
                onAction: () async {
                  await widget.device.openSettings('accessibility');
                },
                footer: _allowed('accessibility')
                    ? null
                    : _RestrictedHint(
                        onOpenAppInfo: () => widget.device.openAppSettings(),
                      ),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => widget.device.openAppSettings(),
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Open app settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.allowed,
    required this.loaded,
    required this.actionLabel,
    required this.onAction,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool allowed;
  final bool loaded;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2EAD5B);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: allowed ? green.withValues(alpha: 0.5) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kBlue.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: kBlue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ),
              if (loaded && allowed)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: green, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'On',
                      style: TextStyle(color: green, fontWeight: FontWeight.w600),
                    ),
                  ],
                )
              else if (loaded)
                FilledButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(fontSize: 14, height: 1.4, color: context.textSecondary),
          ),
          if (footer != null) ...[const SizedBox(height: 12), footer!],
        ],
      ),
    );
  }
}

class _RestrictedHint extends StatelessWidget {
  const _RestrictedHint({required this.onOpenAppInfo});

  final VoidCallback onOpenAppInfo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF29900).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Switch is greyed out? On Android 13 or newer, an app installed '
            'outside the Play Store needs one extra step: tap Open app info, '
            'then the three dots (top right), then Allow restricted settings. '
            'After that, come back and tap Turn on.',
            style: TextStyle(fontSize: 13, height: 1.4, color: context.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onOpenAppInfo,
            child: const Text('Open app info'),
          ),
        ],
      ),
    );
  }
}
