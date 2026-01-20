import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';
import 'package:path/path.dart' as p;

class LocalAssetServer {
  HttpServer? _server;
  int _port = 8080;

  int get port => _port;

  /// Starts the local server after copying assets to a temporary directory
  Future<int> start() async {
    // 1. Get temporary directory
    final docDir = await getApplicationDocumentsDirectory();
    final gitvilleDir = Directory(p.join(docDir.path, 'gitville'));

    // 2. Clear old run to ensure fresh assets (optional, maybe check versions in prod)
    if (await gitvilleDir.exists()) {
      await gitvilleDir.delete(recursive: true);
    }
    await gitvilleDir.create(recursive: true);

    // 3. List of files to copy (Must match what is in pubspec.yaml and folder structure)
    // We have to list them manually or use AssetManifest if available.
    // For now, listing known files is safer/simpler for this constrained env.
    final files = [
      'web/index.html',
      'web/script.js',
      'web/style.css',
      'web/clouds.js',
      'web/npc.js',
      'web/tree.js',
      'data/stargazers_houses.json',
      'data/world.json',
      'data/roads.json',
    ];

    // 4. Copy loop
    for (String file in files) {
      try {
        final assetKey = 'lib/location/gitville/$file';
        final content = await rootBundle.load(assetKey);
        final fileOnDisk = File(p.join(gitvilleDir.path, file));
        
        // Ensure parent dirs exist
        await fileOnDisk.parent.create(recursive: true);
        
        await fileOnDisk.writeAsBytes(content.buffer.asUint8List());
      } catch (e) {
        print('Error copying $file: $e');
      }
    }

    // 5. Start Shelf Server
    var handler = createStaticHandler(gitvilleDir.path, defaultDocument: 'index.html');
    
    // Add CORS headers just in case
    final pipeline = const Pipeline().addMiddleware((innerHandler) {
      return (request) async {
        final response = await innerHandler(request);
        return response.change(headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        });
      };
    }).addHandler(handler);

    _server = await io.serve(pipeline, InternetAddress.loopbackIPv4, 0); // 0 = random free port
    _port = _server!.port;
    
    print('Local server started at http://127.0.0.1:$_port');
    return _port;
  }

  Future<void> stop() async {
    await _server?.close();
  }
}
