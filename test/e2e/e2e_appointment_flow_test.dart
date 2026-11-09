import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicontrol/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Doble de red que intercepta las peticiones HTTP del ApiService durante el test E2E.
class _E2EHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient();
  }
}

class _FakeHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeHttpRequest(method.toUpperCase(), url);

  @override
  Future<HttpClientRequest> getUrl(Uri url) async =>
      _FakeHttpRequest('GET', url);

  @override
  Future<HttpClientRequest> postUrl(Uri url) async =>
      _FakeHttpRequest('POST', url);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) async =>
      _FakeHttpRequest('DELETE', url);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpRequest implements HttpClientRequest {
  @override
  final String method;
  final Uri url;
  final List<int> _body = [];

  _FakeHttpRequest(this.method, this.url);

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  int contentLength = 0;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  bool persistentConnection = false;

  @override
  Encoding encoding = utf8;

  @override
  void add(List<int> data) {
    _body.addAll(data);
  }

  @override
  Future addStream(Stream<List<int>> stream) => stream.forEach(add);

  @override
  Future<HttpClientResponse> close() async {
    final path = url.path;
    // print('REQUEST METHOD: $method PATH: $path FULL: $url');

    if (method == 'GET' && path == '/api/appointments') {
      final jsonResponse = jsonEncode([
        {
          'id': 101,
          'doctorName': 'Dra. Ana López',
          'specialty': 'Cardiología',
          'date': '2026-11-20T10:30:00.000Z',
          'location': 'Clínica del Norte',
          'reason': 'Control de presión arterial',
        },
      ]);
      return _FakeHttpResponse(200, jsonResponse);
    }

    if (method == 'POST' && path == '/api/appointments') {
      final jsonResponse = jsonEncode({
        'id': 202,
        'doctorName': 'Dr. E2E Automatizado',
        'specialty': 'Neurología',
        'date': '2026-12-01T15:00:00.000Z',
        'location': 'Hospital Ángeles',
        'reason': 'Consulta especializada de rutina',
      });
      return _FakeHttpResponse(201, jsonResponse);
    }

    if (method == 'DELETE' && path.startsWith('/api/appointments/')) {
      return _FakeHttpResponse(200, 'OK');
    }

    if (method == 'GET' && path == '/api/profile') {
      final profileJson = jsonEncode({
        'fullName': 'Eduardo Rodríguez',
        'email': 'eduardo@medicontrol.com',
        'phone': '+57 320 123 4567',
        'bloodType': 'O+',
        'allergies': 'Ninguna',
        'address': 'Calle 45',
        'emergencyContactName': 'María',
      });
      return _FakeHttpResponse(200, profileJson);
    }

    return _FakeHttpResponse(200, '[]');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpResponse extends Stream<List<int>>
    implements HttpClientResponse {
  final int _statusCode;
  final List<int> _contentBytes;

  _FakeHttpResponse(this._statusCode, String content)
    : _contentBytes = utf8.encode(content);

  @override
  int get statusCode => _statusCode;

  @override
  int get contentLength => _contentBytes.length;

  @override
  String get reasonPhrase =>
      _statusCode == 200 ? 'OK' : (_statusCode == 201 ? 'Created' : '');

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  bool get persistentConnection => false;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(_contentBytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = {
    'content-type': ['application/json; charset=utf-8'],
  };

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }

  @override
  ContentType? get contentType => ContentType.json;

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers[name.toLowerCase()] = [value.toString()];
  }

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers.putIfAbsent(name.toLowerCase(), () => []).add(value.toString());
  }

  @override
  List<String>? operator [](String name) => _headers[name.toLowerCase()];

  @override
  String? value(String name) {
    final values = _headers[name.toLowerCase()];
    if (values == null || values.isEmpty) return null;
    return values.first;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'Fase 4: Prueba E2E - Flujo Crítico Completo (Login -> Navegación -> Alta de Cita -> Verificación -> Baja)',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await HttpOverrides.runZoned(() async {
        // 1. Iniciar la aplicación
        await tester.pumpWidget(const MediControl());
        await tester.pumpAndSettle();

        // Verificar pantalla inicial de Login
        expect(find.text('MediControl'), findsAtLeastNWidgets(1));
        expect(find.text('Iniciar sesión'), findsOneWidget);

        // 2. Interacción inicial: Llenar credenciales e iniciar sesión
        await tester.enterText(
          find.widgetWithText(TextField, 'Correo electrónico'),
          'eduardo@medicontrol.com',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Contraseña'),
          'password123',
        );
        await tester.tap(find.text('Iniciar sesión'));
        await tester.pumpAndSettle();

        // 3. Confirmar acceso al área privada (Dashboard)
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.text('Inicio'), findsOneWidget);

        // 4. Navegación a la funcionalidad crítica: Pantalla de Citas en NavigationBar
        await tester.tap(find.byIcon(Icons.calendar_month_outlined));
        await tester.pumpAndSettle();

        // Verificar que se cargó la agenda de citas desde la API
        expect(find.text('Citas médicas'), findsOneWidget);
        expect(find.text('Dra. Ana López'), findsAtLeastNWidgets(1));

        // 5. Apertura del formulario de nueva cita mediante el FAB
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Verificar que el modal de nueva cita está visible
        expect(find.text('Nueva cita'), findsAtLeastNWidgets(1));

        // 6. Llenado del formulario con datos de la nueva cita médica
        await tester.enterText(
          find.widgetWithText(TextField, 'Médico'),
          'Dr. E2E Automatizado',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Especialidad'),
          'Neurología',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Lugar'),
          'Hospital Ángeles',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Motivo de la consulta'),
          'Consulta especializada de rutina',
        );

        // 7. Guardar la cita
        await tester.tap(find.text('Guardar cita'));
        await tester.pumpAndSettle();

        // 8. Verificación de persistencia en UI y comprobación del resultado final
        expect(find.text('Dr. E2E Automatizado'), findsOneWidget);
        expect(find.text('Neurología • Hospital Ángeles'), findsOneWidget);
        expect(find.text('Consulta especializada de rutina'), findsOneWidget);

        // 9. Operación de baja/limpieza en el flujo
        final e2eCard = find.widgetWithText(Card, 'Dr. E2E Automatizado');
        final deleteBtn = find.descendant(
          of: e2eCard,
          matching: find.byIcon(Icons.delete_outline),
        );
        expect(deleteBtn, findsOneWidget);

        // Tocar el botón de eliminar del registro creado
        await tester.tap(deleteBtn, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Comprobar que el elemento fue retirado
        expect(find.text('Dr. E2E Automatizado'), findsNothing);
      }, createHttpClient: (context) => _FakeHttpClient());
    },
  );
}
