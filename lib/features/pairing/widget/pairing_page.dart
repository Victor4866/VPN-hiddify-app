import 'package:flutter/material.dart';

/// Safe landing page for IOS8 VPN one-time pairing links.
///
/// The token is intentionally not displayed or persisted here. The client
/// redemption API will be connected after the server issues real VPN configs.
class PairingPage extends StatelessWidget {
  const PairingPage({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    final hasToken = token.isNotEmpty && token.length <= 256;
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
                      hasToken ? Icons.qr_code_2_rounded : Icons.link_off_rounded,
                      size: 42,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      hasToken ? '已识别 IOS8 VPN 配对链接' : '配对链接无效',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      hasToken
                          ? '当前客户端已识别临时配对令牌。服务端设备兑换和 VPN 配置下发正在接入，暂时不能完成注册。请勿将此链接转发给他人。'
                          : '链接中没有有效的临时配对令牌。请返回 IOS8 VPN 管理中心重新生成连接二维码。',
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('返回'),
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
