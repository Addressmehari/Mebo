import 'package:flutter/material.dart';
import 'package:habo/navigation/routes.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:habo/location/local_server.dart';
import 'package:habo/location/city_generator.dart';
import 'package:habo/habits/habits_manager.dart';
import 'package:provider/provider.dart';

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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initServerAndLoad();
  }

  Future<void> _initServerAndLoad() async {
    try {
      // 1. Start Server (extracts default assets)
      final port = await _server.start();
      
      if (!mounted) return;

      // 2. Overwrite defaults with Habit Data
      final habitsManager = Provider.of<HabitsManager>(context, listen: false);
      await CityGenerator.generateAndSave(habitsManager.activeHabits);

      // 3. Load WebView
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..loadRequest(Uri.parse('http://127.0.0.1:$port/web/index.html'));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
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

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('GitVille City')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Failed to start City Server',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _initServerAndLoad();
                  },
                  child: const Text('Retry'),
                )
              ],
            ),
          ),
        ),
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
