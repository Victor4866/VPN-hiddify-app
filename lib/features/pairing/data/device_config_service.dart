import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hiddify/features/profile/data/profile_repository.dart';

/// Downloads with a Bearer header, never a credential in a profile URL.
/// Core validation and activation must both succeed before connecting.
class DeviceConfigService {
  DeviceConfigService({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ?? Dio(BaseOptions(
          baseUrl: 'https://vpn.ios8.io',
          followRedirects: false,
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 15),
        )),
        _storage = storage ?? const FlutterSecureStorage();

  final Dio _dio;
  final FlutterSecureStorage _storage;

  Future<void> prepare(ProfileRepository repository) async {
    final credential = await _storage.read(key: 'ios8vpn.device.credential');
    final deviceId = await _storage.read(key: 'ios8vpn.device.id');
    if (credential == null || deviceId == null) {
      throw StateError('请先在 vpn.ios8.io 登录并授权此设备。');
    }
    Map<String, dynamic>? data;
    try {
      data = (await _dio.get<Map<String, dynamic>>('/api/device/config',
        options: Options(headers: {'Authorization': 'Bearer $credential'}),
      )).data;
    } on DioException catch (error) {
      // Never propagate DioException: it contains the Authorization header.
      if (error.response?.statusCode == 401) {
        throw StateError('设备授权已失效，请重新登录并授权。');
      }
      if (error.response?.statusCode == 503) {
        throw StateError('服务端正在同步设备配置，请稍后再次连接。');
      }
      throw StateError('无法获取设备配置，请检查网络后重试。');
    }
    if (data == null || data['deviceId'] != deviceId || data['config'] is! Map) {
      throw StateError('设备配置校验失败，请重新授权。');
    }
    final content = jsonEncode(data['config']);
    final profileId = await _storage.read(key: 'ios8vpn.device.profile');
    final previous = profileId == null ? null
        : (await repository.getById(profileId).run()).getOrElse((_) => null);
    String id;
    if (previous != null) {
      // Includes core validation; retain the previous file if validation fails.
      (await repository.offlineUpdate(previous, content).run())
          .getOrElse((_) => throw StateError('VPN 核心拒绝设备配置，请更新客户端。'));
      id = previous.id;
    } else {
      id = (await repository.addLocal(content).run())
          .getOrElse((_) => throw StateError('VPN 核心拒绝设备配置，请更新客户端。'));
      await _storage.write(key: 'ios8vpn.device.profile', value: id);
    }
    (await repository.setAsActive(id).run())
        .getOrElse((_) => throw StateError('无法启用设备配置，请重试。'));
  }

  void close() => _dio.close();
}
