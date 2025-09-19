import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Configure routes.
final Router _router = Router()..get('/<message>', _echoHandler);

Response _echoHandler(final Request request) {
  final String? message = request.params['message'];
  return Response.ok(
    '$message\n',
    headers: <String, Object>{'Content-Type': 'application/octet-stream'},
  );
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
