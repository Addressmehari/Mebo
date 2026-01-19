import 'package:flutter/material.dart';
import 'package:habo/navigation/routes.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:habo/location/local_server.dart';

class LocationScreen extends StatefulWidget {
  static MaterialPage page() {
    return MaterialPage(
      name: Routes.locationPath,
      key: ValueKey(Routes.locationPath),
      child: const LocationScreen(),
    );
  }

  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  late final WebViewController controller;
  final LocalAssetServer _server = LocalAssetServer();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initServerAndLoad();
  }

  Future<void> _initServerAndLoad() async {
    final port = await _server.start();
    
    if (!mounted) return;

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse('http://localhost:$port/web/index.html'));

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _server.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('GitVille City'),
        backgroundColor: Colors.transparent,
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
