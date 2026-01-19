import 'package:flutter/material.dart';
import 'package:habo/navigation/routes.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:habo/location/local_server.dart';
import 'package:habo/location/city_generator.dart';
import 'package:provider/provider.dart';
import 'package:habo/habits/habits_manager.dart';

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
    // 1. Generate City Data from Habits
    if (mounted) {
        final habitsManager = Provider.of<HabitsManager>(context, listen: false);
        final cityGen = CityGenerator(habitsManager);
        await cityGen.generateAndSave();
    }

    // 2. Start Server
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
