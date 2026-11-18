import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:medicontrol/models/appointment.dart';
import 'package:medicontrol/services/api_service.dart';
import 'package:medicontrol/services/appointment_logic.dart';
import 'package:medicontrol/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FailingHttpOverrides extends HttpOverrides {
  final int statusCode;
  final String body;

  _FailingHttpOverrides({required this.statusCode, required this.body});

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _MockStatusHttpClient(statusCode: statusCode, body: body);
}

class _MockStatusHttpClient implements HttpClient {
  final int statusCode;
  final String body;

  _MockStatusHttpClient({required this.statusCode, required this.body});

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _MockStatusHttpRequest(statusCode: statusCode, body: body);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockStatusHttpRequest implements HttpClientRequest {
  final int statusCode;
  final String body;

  _MockStatusHttpRequest({required this.statusCode, required this.body});

  @override
  final HttpHeaders headers = _MockHeaders();

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
  void add(List<int> data) {}

  @override
  Future addStream(Stream<List<int>> stream) async {}

  @override
  Future<HttpClientResponse> close() async =>
      _MockStatusHttpResponse(statusCode: statusCode, body: body);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockStatusHttpResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  final int statusCode;
  final String body;

  _MockStatusHttpResponse({required this.statusCode, required this.body});

  @override
  int get contentLength => utf8.encode(body).length;

  @override
  HttpHeaders get headers => _MockHeaders();

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => 'Error';

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  Stream<List<int>> asBroadcastStream({
    void Function(StreamSubscription<List<int>> subscription)? onListen,
    void Function(StreamSubscription<List<int>> subscription)? onCancel,
  }) =>
      Stream.value(utf8.encode(body)).asBroadcastStream();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      Stream.value(utf8.encode(body)).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHeaders implements HttpHeaders {
  final Map<String, List<String>> _map = {};

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _map.putIfAbsent(name.toLowerCase(), () => []).add(value.toString());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _map[name.toLowerCase()] = [value.toString()];
  }

  @override
  List<String>? operator [](String name) => _map[name.toLowerCase()];

  @override
  String? value(String name) => _map[name.toLowerCase()]?.firstOrNull;

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _map.forEach(action);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Práctica 13 - Fase 2: Pruebas Unitarias', () {
    final fixedNow = DateTime(2026, 11, 17, 10, 0);

    test('1. Entrada válida: valida cita con espacios laterales y formatea fecha', () {
      final targetDate = DateTime(2026, 12, 5, 9, 30);
      final validation = AppointmentLogic.validateAppointment(
        doctorName: '  Dra. Sofía Ramírez  ',
        specialty: ' Cardiología ',
        location: ' Hospital Central ',
        reason: ' Revisión semestral ',
        date: targetDate,
        now: fixedNow,
      );

      expect(validation.isValid, isTrue);
      expect(validation.errorMessage, isNull);
      expect(AppointmentLogic.formatDate(targetDate), equals('5 dic 2026'));
    });

    test('2. Entrada vacía o nula: rechaza campos vacíos y retorna null sin sesión', () async {
      final validation = AppointmentLogic.validateAppointment(
        doctorName: '',
        specialty: '   ',
        location: 'Clínica Norte',
        reason: 'Chequeo',
        date: fixedNow.add(const Duration(days: 1)),
        now: fixedNow,
      );

      expect(validation.isValid, isFalse);
      expect(
        validation.errorMessage,
        equals('Completa todos los campos de la cita'),
      );
      expect(AppointmentLogic.findNextAppointment([], now: fixedNow), isNull);

      SharedPreferences.setMockInitialValues({});
      final storedUser = await AuthService.getStoredUser();
      expect(storedUser, isNull);
    });

    test('3. Valores fuera de rango: rechaza fecha pasada fuera de margen y token inválido', () async {
      final outOfRangePast = fixedNow.subtract(const Duration(minutes: 2));
      final validation = AppointmentLogic.validateAppointment(
        doctorName: 'Dr. Luis Vega',
        specialty: 'Neurología',
        location: 'Consultorio 4',
        reason: 'Cefalea',
        date: outOfRangePast,
        now: fixedNow,
      );

      expect(validation.isValid, isFalse);
      expect(
        validation.errorMessage,
        equals('La fecha y hora de la cita no pueden ser en el pasado'),
      );

      SharedPreferences.setMockInitialValues({
        'auth_token': 'token-invalido-no-jwt',
      });
      expect(await AuthService.isTokenExpired(), isTrue);
    });

    test('4. Resultado esperado: ordena citas sin mutar lista original y selecciona la próxima', () {
      final past = Appointment(
        id: '1',
        doctorName: 'Dr. Pasado',
        specialty: 'General',
        location: 'Sala 1',
        reason: 'Previo',
        date: fixedNow.subtract(const Duration(hours: 2)),
      );
      final later = Appointment(
        id: '2',
        doctorName: 'Dra. Tarde',
        specialty: 'Dermatología',
        location: 'Sala 2',
        reason: 'Control',
        date: fixedNow.add(const Duration(days: 3)),
      );
      final soonest = Appointment(
        id: '3',
        doctorName: 'Dr. Próximo',
        specialty: 'Cardiología',
        location: 'Sala 3',
        reason: 'Electrocardiograma',
        date: fixedNow.add(const Duration(hours: 4)),
      );

      final original = [later, past, soonest];
      final sorted = AppointmentLogic.sortChronologically(original);

      expect(sorted.map((a) => a.id).toList(), equals(['1', '3', '2']));
      expect(original.map((a) => a.id).toList(), equals(['2', '1', '3']));

      final next = AppointmentLogic.findNextAppointment(original, now: fixedNow);
      expect(next?.id, equals('3'));
    });

    test('5. Manejo de excepciones: tolera JSON corrupto en persistencia local', () async {
      SharedPreferences.setMockInitialValues({
        'user_data': '{corrupt_json_payload',
      });

      final user = await AuthService.getStoredUser();
      expect(user, isNull);
    });

    test('6. Manejo de excepciones: ApiService lanza excepción descriptiva ante HTTP 500', () async {
      SharedPreferences.setMockInitialValues({});
      await HttpOverrides.runZoned(
        () async {
          await expectLater(
            ApiService.fetchProfile(),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('500'),
              ),
            ),
          );
        },
        createHttpClient: (ctx) =>
            _FailingHttpOverrides(statusCode: 500, body: 'Internal Server Error')
                .createHttpClient(ctx),
      );
    });
  });
}
