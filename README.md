# IOS8 VPN 客户端

**基于 Hiddify / sing-box 的公开 Fork 二次开发。** 产品名称：**IOS8 VPN**；默认界面语言：简体中文。

客户端仓库：<https://github.com/Victor4866/VPN-hiddify-app>

> 当前仓库仍处于开发阶段。已经提交第一批中文化和品牌改造，并实现 ios8vpn:// 配对、客户端设备凭据安全保存与服务端状态校验；尚未完成 Windows / iPhone 安装包构建、签名、真实 VPN 数据平面和网络验收。当前 main 不是可供日常使用的正式 IOS8 VPN 发行版。

## 目标平台

- Windows 10 / 11 x64
- iPhone（iOS，Apple Network Extension / Packet Tunnel Provider）

## 首期网络模式

1. **智能分流（默认）**：中国大陆域名 / IP 与局域网直连，其他互联网流量经自己的美国 VPS。
2. **全局美国**：互联网流量经自己的美国 VPS 出口。

同时提供一键连接 / 断开、自动重连、网络切换恢复、DNS 路由一致性、出口 IP 和连接诊断。Windows 与 iOS 的系统网络能力不同，分流范围以各平台实际实现为准。

## 当前开发进度

| 模块 | 状态 |
|---|---|
| Hiddify 公开 Fork | 已验证 |
| 默认简体中文 | 已提交第一批改造 |
| 中文界面品牌字符串 | 已提交第一批改造 |
| iOS 显示名称与 IOS8 深链 | 已提交第一批改造 |
| Windows 原生窗口 / 可执行文件标识 | 已提交第一批改造 |
| IOS8 原创基础标志 | 已提交 SVG；平台二进制图标仍待替换 |
| Windows 安装包与签名 | 待构建 / 配置证书 |
| iPhone TestFlight | 待配置 Apple Developer / Network Extension 签名 |
| 智能分流 | 待接入自有服务端并测试 |
| 全局美国模式 | 待接入自有服务端并测试 |
| 设备临时配对 | 已实现一次性令牌兑换、客户端生成凭据并安全保存、设备状态校验；需正式安装包实测 |

## 技术基础

- Flutter：Windows 与 iOS 共用 UI。
- sing-box：客户端网络核心。
- Windows：沿用上游 TUN / 系统服务实现。
- iPhone：沿用上游 Packet Tunnel Provider / Network Extension。
- 私有服务端：<https://github.com/Victor4866/VPN>（IOS8 VPN Server）。

## 上游与许可

本仓库是 <https://github.com/hiddify/hiddify-app> 的公开 Fork，不是 Hiddify 官方发行版。

- 保留根目录 `LICENSE.md` 中的 Hiddify Extended GPL v3 及附加条件。
- 保留 Hiddify、sing-box 和其他第三方组件的版权与许可声明。
- 仅个人 / 非商业用途，除非取得上游书面许可。
- 正式发布必须通过 GitHub Actions。
- 修改与衍生代码按上游要求公开，并记录在变更日志。
- IOS8 VPN 使用独立名称、标志与中文界面，不使用 Hiddify 产品品牌或近似视觉设计。

## 构建与发布

- Windows：x64 安装包；在没有可信 Authenticode 证书前，明确显示未签名状态。
- iPhone：需要 IOS8 自己的 Bundle ID、App Group、Network Extension entitlement、Apple Developer 签名与 provisioning profile；优先通过 TestFlight 内测。
- 签名证书、P12、Provisioning Profile、Apple API 私钥和服务端密钥不得提交到 Git。
- Release 附版本说明与 SHA-256。

开发路线见 [IOS8 VPN 中文路线图](docs/IOS8-VPN-ROADMAP.zh-CN.md)。
