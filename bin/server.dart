import 'dart:io';

import 'package:propertylistserialization/propertylistserialization.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Configure routes.
final Router _router = Router()
  ..get('/<bundleId>/<version>/<title>', _echoHandler);

Response _echoHandler(final Request request) {
  final String? bundleId = request.params['bundleId'];
  final String? version = request.params['version'];
  final String? title = request.params['title'];

  if (bundleId != null && version != null && title != null) {
    final String fileName = '$title-$version';
    final String downloadUrl = 'https://download.vanyasem.ru/ipa/$fileName.ipa';
    // https://developer.apple.com/documentation/devicemanagement/manifesturl/itemsitem
    final Map<String, Object> dict = <String, Object>{
      'items': <Object>[
        <String, Object>{
          'assets': <Object>[
            <String, Object>{'kind': 'software-package', 'url': downloadUrl},
          ],
          'metadata': <String, Object>{
            'bundle-identifier': bundleId,
            'kind': 'software',
            'title': title,
          },
        },
      ],
    };

    try {
      final String result = PropertyListSerialization.stringWithPropertyList(
        dict,
      );
      return Response.ok(
        result,
        headers: <String, Object>{'Content-Type': 'application/octet-stream'},
      );
    } on PropertyListWriteStreamException catch (_) {
      return Response.internalServerError();
    }
  } else {
    String error = '';
    if (bundleId == null) {
      error += 'Missing bundleId\n';
    }
    if (version == null) {
      error += 'Missing version\n';
    }
    if (title == null) {
      error += 'Missing title\n';
    }
    return Response.badRequest(body: error);
  }
}

void main(final List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final InternetAddress ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final Handler handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(_router.call);

  // For running in containers, we respect the PORT environment variable.
  final int port = int.parse(Platform.environment['PORT'] ?? '8080');
  final HttpServer server = await serve(handler, ip, port);
  // ignore: avoid_print, Initialization message useful for verifying Docker configuration
  print('Server listening on port ${server.port}');
}
