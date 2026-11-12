import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

/// Redeems a short-lived IOS8 VPN pairing token and stores the device
/// credential in the platform secure store (Windows encrypted storage / iOS Keychain).
class PairingPage extends StatefulWidget {
  const PairingPage({super.key, required this.token});

  final String token;

  @override
  State<PairingPage> createState() => _PairingPageState();
}

class _PairingPageState extends State<PairingPage> {
  static const _serverUrl = 'https://vpn.ios8.io';
  static const _storage = FlutterSecureStorage();

  bool _isPairing = false;
  bool _paired = false;
  String? _error;
  String? _statusWarning;
  String? _deviceName;
  String? _deviceId;

  String? get _platform {
    if (Platform.isWindows) return 'windows';
    if (Platform.isIOS) return 'ios';
    return null;
  }

  bool get _hasToken => widget.token.isNotEmpty && widget.token.length <= 256;

  String _errorMessage(Object error) {
    if (error is DioException) {
      final body = error.response?.data;
      if (body is Map && body['detail'] is String) {
        return body['detail'] as String;
      }
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          '连接 IOS8 VPN 服务器超时，请检查当前网络后重试。',
        DioExceptionType.connectionError =>
          '无法连接 IOS8 VPN 服务器，请检查网络连接。',
        _ => '设备配对失败，请重新生成临时连接码后重试。',
      };
    }
    return '设备配对失败，请稍后重试。';
  }

  Future<String> _loadOrCreatePendingCredential() async {
    final pendingToken = await _storage.read(key: 'ios8vpn.pending_pairing.token');
    final pendingCredential = await _storage.read(key: 'ios8vpn.pending_pairing.credential');
    if (pendingToken == widget.token && pendingCredential != null && pendingCredential.length >= 32) {
      return pendingCredential;
    }

    final random = Random.secure();
    final bytes = List<int>.generate(48, (_) => random.nextInt(256));
    final credential = base64Url.encode(bytes).replaceAll('=', '');
    await _storage.write(key: 'ios8vpn.pending_pairing.token', value: widget.token);
    await _storage.write(key: 'ios8vpn.pending_pairing.credential', value: credential);
    return credential;
  }

  Future<void> _redeem() async {
    final platform = _platform;
    if (!_hasToken || platform == null || _isPairing || _paired) return;

    setState(() {
      _isPairing = true;
      _error = null;
      _statusWarning = null;
    });

    final dio = Dio(
      BaseOptions(
        baseUrl: _serverUrl,
        connectTimeout: const Duration(seconds: 12),
        sendTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {'Accept': 'application/json'},
      ),
    );

    String? redeemedDeviceId;
    try {
      // Generate and persist the credential before the network request. If the
      // response is lost, retrying this same one-time token reuses the same
      // credential and the server safely returns the original device record.
      final credential = await _loadOrCreatePendingCredential();
      final response = await dio.post<Map<String, dynamic>>(
        '/api/pairing-tokens/redeem',
        data: {
          'token': widget.token,
          'platform': platform,
          'device_credential': credential,
        },
      );
      final data = response.data;
      if (data == null) {
        throw const FormatException('服务器返回了空的配对结果');
      }

      final deviceId = data['deviceId'];
      if (deviceId is! String || deviceId.isEmpty) {
        throw const FormatException('服务器返回的设备编号不完整');
      }
      redeemedDeviceId = deviceId;

      // Store the long-lived device credential before showing success.
      // Never write the token or credential to application logs.
      await _storage.write(key: 'ios8vpn.device.server', value: _serverUrl);
      await _storage.write(key: 'ios8vpn.device.id', value: deviceId);
      await _storage.write(key: 'ios8vpn.device.platform', value: platform);
      await _storage.write(key: 'ios8vpn.device.credential', value: credential);
      await _storage.delete(key: 'ios8vpn.pending_pairing.token');
      await _storage.delete(key: 'ios8vpn.pending_pairing.credential');

      String? statusWarning;
      try {
        final status = await dio.get<Map<String, dynamic>>(
          '/api/device/me',
          options: Options(headers: {'Authorization': 'Bearer $credential'}),
        );
        if (status.data?['deviceId'] != deviceId) {
          statusWarning = '设备凭据已保存，但服务器返回的设备状态不匹配，请稍后检查。';
        }
      } on DioException {
        statusWarning = '设备凭据已安全保存；暂时无法读取设备状态，可稍后重新检测。';
      }

      if (!mounted) return;
      setState(() {
        _paired = true;
        _deviceId = deviceId;
        _deviceName = data['deviceName']?.toString();
        _statusWarning = statusWarning;
      });
    } catch (error) {
      if (error is DioException && error.response?.statusCode == 400) {
        await _storage.delete(key: 'ios8vpn.pending_pairing.token');
        await _storage.delete(key: 'ios8vpn.pending_pairing.credential');
      }
      if (!mounted) return;
      final message = redeemedDeviceId == null
          ? _errorMessage(error)
          : '服务器已登记设备。待完成配对凭据已保存在本机；请重试完成保存，不要重新生成配对码。';
      setState(() => _error = message);
    } finally {
      dio.close();
      if (mounted) setState(() => _isPairing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = _platform;
    final supported = platform != null;
    final title = _paired
        ? '设备配对成功'
        : !_hasToken
            ? '配对链接无效'
            : !supported
                ? '当前平台暂不支持配对'
                : '已识别 IOS8 VPN 配对链接';

    return Scaffold(
      appBar: AppBar(title: const Text('IOS8 VPN 设备配对')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _paired
                          ? Icons.verified_user_rounded
                          : _hasToken
                              ? Icons.qr_code_2_rounded
                              : Icons.link_off_rounded,
                      size: 42,
                      color: _paired ? Colors.green : null,
                    ),
                    const SizedBox(height: 18),
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    Text(
                      _paired
                          ? '设备${_deviceName?.isNotEmpty == true ? '“$_deviceName”' : ''}已登记并保存独立凭据。当前 VPN 核心配置尚未下发，因此暂时还不能建立 VPN 隧道。'
                          : !_hasToken
                              ? '链接中没有有效的临时配对令牌。请返回 IOS8 VPN 管理中心重新生成连接二维码。'
                              : !supported
                                  ? '当前版本仅开放 Windows 和 iPhone 配对。请在受支持的设备上打开此链接。'
                                  : '即将连接 https://vpn.ios8.io，兑换 5 分钟有效的一次性令牌，并将设备凭据安全保存到本机。令牌不会显示或写入日志。',
                    ),
                    if (_deviceId != null) ...[
                      const SizedBox(height: 12),
                      SelectableText('设备编号：$_deviceId'),
                    ],
                    if (_statusWarning != null) ...[
                      const SizedBox(height: 12),
                      Text(_statusWarning!, style: const TextStyle(color: Colors.orange)),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 20),
                    if (!_paired && _hasToken && supported)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isPairing ? null : _redeem,
                          child: _isPairing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('确认配对并注册设备'),
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('返回主页'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
