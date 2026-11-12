import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hiddify/features/pairing/data/device_config_service.dart';
import 'package:hiddify/features/profile/data/profile_repository.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/model/profile_failure.dart';

class _Repository implements ProfileRepository {
  bool valid = true;
  int added = 0;
  int updated = 0;
  String? active;
  ProfileEntity? profile;

  @override
  TaskEither<ProfileFailure, ProfileEntity?> getById(String id) => TaskEither.right(profile);

  @override
  TaskEither<ProfileFailure, String> addLocal(String content, {UserOverride? userOverride}) => TaskEither(() async {
    added++;
    if (!valid) return left(const ProfileFailure.notFound());
    profile = ProfileEntity.local(id: 'managed-profile', active: false, name: 'IOS8 VPN', lastUpdate: DateTime(2026));
    return right('managed-profile');
  });

  @override
  TaskEither<ProfileFailure, Unit> offlineUpdate(ProfileEntity nProfile, String nContent) => TaskEither(() async {
    updated++;
    return valid ? right(unit) : left(const ProfileFailure.notFound());
  });

  @override
  TaskEither<ProfileFailure, Unit> setAsActive(String id) => TaskEither(() async {
    active = id;
    return right(unit);
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Repository repository;
  late Dio dio;
  late DeviceConfigService service;
  late int requests;
  late int status;
  late String returnedDevice;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'ios8vpn.device.id': 'test-device',
      'ios8vpn.device.credential': 'unit-test-credential',
    });
    repository = _Repository();
    requests = 0;
    status = 200;
    returnedDevice = 'test-device';
    dio = Dio(BaseOptions(baseUrl: 'https://vpn.example.test', followRedirects: false));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests++;
      expect(options.uri.query, isEmpty);
      expect(options.headers['Authorization'], 'Bearer unit-test-credential');
      if (status != 200) {
        handler.reject(DioException(requestOptions: options, type: DioExceptionType.badResponse,
          response: Response<dynamic>(requestOptions: options, statusCode: status)));
        return;
      }
      handler.resolve(Response<dynamic>(requestOptions: options, statusCode: 200,
        data: {'deviceId': returnedDevice, 'config': {'outbounds': <dynamic>[]}}));
    }));
    service = DeviceConfigService(dio: dio);
  });

  tearDown(() => service.close());

  test('new device profile is validated, saved and activated without a URL credential', () async {
    final profile = await service.prepare(repository);
    expect(profile.id, 'managed-profile');
    expect(repository.added, 1);
    expect(repository.active, profile.id);
    expect(requests, 1);
    expect(await const FlutterSecureStorage().read(key: 'ios8vpn.device.profile'), profile.id);
  });

  test('repeat connect updates the same profile rather than adding duplicates', () async {
    await service.prepare(repository);
    await service.prepare(repository);
    expect(repository.added, 1);
    expect(repository.updated, 1);
  });

  test('unpaired device fails before making a request', () async {
    FlutterSecureStorage.setMockInitialValues({});
    await expectLater(service.prepare(repository), throwsStateError);
    expect(requests, 0);
    expect(repository.active, isNull);
  });

  test('revoked and pending authorization never fall back to a cached profile', () async {
    for (final code in [401, 503]) {
      status = code;
      await expectLater(service.prepare(repository), throwsStateError);
    }
    expect(repository.added, 0);
    expect(repository.active, isNull);
  });

  test('cross-device response is rejected before importing config', () async {
    returnedDevice = 'another-device';
    await expectLater(service.prepare(repository), throwsStateError);
    expect(repository.added, 0);
  });

  test('core validation failure never activates the profile', () async {
    repository.valid = false;
    await expectLater(service.prepare(repository), throwsStateError);
    expect(repository.active, isNull);
  });
}
