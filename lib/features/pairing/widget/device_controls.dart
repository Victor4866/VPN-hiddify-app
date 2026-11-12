import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Managed Windows controls: device authorization and two routing choices.
class DeviceControls extends ConsumerWidget {
  const DeviceControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isWindows) return const SizedBox.shrink();
    final smart = ref.watch(ConfigOptions.ios8SmartRouting);
    final disconnected = ref.watch(connectionNotifierProvider).valueOrNull is Disconnected;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('智能分流'), icon: Icon(Icons.alt_route)),
              ButtonSegment(value: false, label: Text('全局模式'), icon: Icon(Icons.public)),
            ],
            selected: {smart},
            onSelectionChanged: !disconnected ? null : (selection) async {
              try {
                await ref.read(ConfigOptions.ios8SmartRouting.notifier).update(selection.single);
              } catch (_) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('模式保存失败，请重试。')));
              }
            },
          ),
          const SizedBox(height: 8),
          Text(disconnected
              ? smart ? '中国大陆网站直连，其他流量通过 VPN。' : '互联网流量通过 VPN，局域网保持直连。'
              : '请先断开连接，再切换模式。', textAlign: TextAlign.center),
          TextButton.icon(
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('登录网站并授权此设备'),
            onPressed: () async {
              try {
                final opened = await launchUrl(Uri.parse('https://vpn.ios8.io'), mode: LaunchMode.externalApplication);
                if (!opened) throw StateError('browser unavailable');
              } catch (_) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请在浏览器打开 https://vpn.ios8.io 完成授权。')));
              }
            },
          ),
        ],
      ),
    );
  }
}
