import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme.dart';

/// Shows a web page (search results, YouTube, a website) inside Vocax AI.
class WebScreen extends StatefulWidget {
  const WebScreen({super.key, required this.title, required this.url});

  final String title;
  final String url;

  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _failed = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) return;
            if (mounted) setState(() => _failed = true);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _back() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: context.surfaceColor,
          foregroundColor: context.textPrimary,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Back to Vocax AI',
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reload',
              onPressed: () => _controller.reload(),
            ),
          ],
          bottom: _progress < 100 && !_failed
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    value: _progress / 100,
                    minHeight: 3,
                  ),
                )
              : null,
        ),
        body: _failed
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 56,
                        color: context.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'This page could not load. Check your internet connection and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () {
                          setState(() => _failed = false);
                          _controller.reload();
                        },
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              )
            : WebViewWidget(controller: _controller),
      ),
    );
  }
}
