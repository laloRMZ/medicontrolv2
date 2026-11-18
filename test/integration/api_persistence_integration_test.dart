import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:medicontrol/services/api_service.dart';
import 'package:medicontrol/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Redirige peticiones dirigidas a localhost:3000 / 10.0.2.2:3000 hacia el HttpServer efímero de pruebas.
class _LoopbackPortRedirectOverrides extends HttpOverrides {
  final int targetPort;

  _LoopbackPortRedirectOverrides(this.targetPort);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final inner = super.createHttpClient(context);
    return _RedirectingHttpClient(inner, targetPort);
  }
}

class _RedirectingHttpClient implements HttpClient {
  final HttpClient _inner;
  final int _targetPort;

  _RedirectingHttpClient(this._inner, this._targetPort);

  Uri _rewriteUri(Uri uri) {
    if ((uri.host == 'localhost' || uri.host == '10.0.2.2') &&
        uri.port == 3000) {
      return uri.replace(host: '127.0.0.1', port: _targetPort);
    }
    return uri;
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      _inner.openUrl(method, _rewriteUri(url));

  @override
  Future<HttpClientRequest> getUrl(Uri url) =>
      _inner.getUrl(_rewriteUri(url));

  @override
  Future<HttpClientRequest> postUrl(Uri url) =>
      _inner.postUrl(_rewriteUri(url));

  @override
  Future<HttpClientRequest> putUrl(Uri url) =>
      _inner.putUrl(_rewriteUri(url));

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) =>
      _inner.deleteUrl(_rewriteUri(url));

  @override
  void close({bool force = false}) => _inner.close(force: force);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Práctica 13 - Fase 3: Pruebas de Integración (Servicio + Persistencia)', () {
    late HttpServer server;
    String? lastAuthorizationHeader;
    bool simulateServerError = false;

    setUp(() async {
      lastAuthorizationHeader = null;
      simulateServerError = false;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((HttpRequest request) async {
        lastAuthorizationHeader = request.headers.value('authorization');

        if (simulateServerError) {
          request.response
            ..statusCode = HttpStatus.serviceUnavailable
            ..write('Servicio temporalmente no disponible');
          await request.response.close();
          return;
        }

        if (request.method == 'GET' && request.uri.path == '/api/appointments') {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(
              jsonEncode([
                {
                  'id': 10,
                  'doctorName': 'Dra. Valeria Soto',
                  'specialty': 'Cardiología',
                  'date': '2026-12-10T11:00:00.000Z',
                  'reason': 'Seguimiento anual',
                  'location': 'Hospital Central',
                },
              ]),
            );
          await request.response.close();
          return;
        }

        if (request.method == 'GET' && request.uri.path == '/api/profile') {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(
              jsonEncode({
                'fullName': 'Eduardo Rodríguez',
                'email': 'eduardo@medicontrol.com',
                'phone': '+52 55 1234 5678',
                'bloodType': 'O+',
                'allergies': 'Ninguna',
                'address': 'Av. Reforma 100',
                'emergencyContactName': 'María Rodríguez',
              }),
            );
          await request.response.close();
          return;
        }

        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('AUT-04: ApiService envía token de AuthService y recibe citas válidas (HTTP 200)', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'jwt-demo-token-123',
      });

      await HttpOverrides.runZoned(
        () async {
          final appointments = await ApiService.fetchAppointments();

          expect(lastAuthorizationHeader, equals('Bearer jwt-demo-token-123'));
          expect(appointments, hasLength(1));
          expect(appointments.first.id, equals('10'));
          expect(appointments.first.doctorName, equals('Dra. Valeria Soto'));
          expect(appointments.first.specialty, equals('Cardiología'));
        },
        createHttpClient: (ctx) =>
            _LoopbackPortRedirectOverrides(server.port).createHttpClient(ctx),
      );
    });

    test('AUT-04: ApiService obtiene y deserializa el perfil del usuario (HTTP 200)', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'jwt-profile-token',
      });

      await HttpOverrides.runZoned(
        () async {
          final profile = await ApiService.fetchProfile();

          expect(lastAuthorizationHeader, equals('Bearer jwt-profile-token'));
          expect(profile.fullName, equals('Eduardo Rodríguez'));
          expect(profile.email, equals('eduardo@medicontrol.com'));
          expect(profile.bloodType, equals('O+'));
          expect(profile.emergencyContactName, equals('María Rodríguez'));
        },
        createHttpClient: (ctx) =>
            _LoopbackPortRedirectOverrides(server.port).createHttpClient(ctx),
      );
    });

    test('AUT-05: ApiService reporta error controlado cuando el servidor responde 503', () async {
      SharedPreferences.setMockInitialValues({});
      simulateServerError = true;

      await HttpOverrides.runZoned(
        () async {
          await expectLater(
            ApiService.fetchAppointments(),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                allOf(contains('503'), contains('/api/appointments')),
              ),
            ),
          );
        },
        createHttpClient: (ctx) =>
            _LoopbackPortRedirectOverrides(server.port).createHttpClient(ctx),
      );
    });

    test('AUT-06: Persistencia local SharedPreferences + AuthService conserva y limpia sesión', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'header.payload.signature',
        'refresh_token': 'refresh-abc',
        'user_data': jsonEncode({
          'id': 'u-01',
          'fullName': 'Eduardo Rodríguez',
          'email': 'eduardo@medicontrol.com',
          'phone': '+52 55 1234 5678',
          'role': 'patient',
        }),
      });

      final stored = await AuthService.getStoredUser();
      expect(stored, isNotNull);
      expect(stored!.email, equals('eduardo@medicontrol.com'));

      final headers = await AuthService.getAuthHeaders();
      expect(headers['Authorization'], equals('Bearer header.payload.signature'));

      await AuthService.logout();
      expect(await AuthService.getStoredUser(), isNull);
      expect(await AuthService.isTokenExpired(), isTrue);
    });
  });
}
