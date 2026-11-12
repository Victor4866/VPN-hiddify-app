# IOS8 VPN 客户端（Hiddify 公开 Fork）

**项目定位：** 基于 Hiddify App 与 sing-box 的 Windows / iPhone VPN 客户端二次开发项目，产品名称为 **IOS8 VPN**，默认简体中文。

> 当前仓库已建立为 Hiddify 的公开 Fork。IOS8 品牌化、中文界面改造、服务端接入和正式安装包仍在开发中；当前源码不代表已经可供日常使用的 IOS8 VPN 发布版。

## 目标平台

- Windows 10 / 11 x64
- iPhone（iOS；通过 Apple Network Extension / Packet Tunnel Provider）

## 首期功能目标

1. **智能分流**：中国大陆域名 / IP 与局域网按规则直连，其余互联网流量走自己的美国 VPS。
2. **全局美国**：互联网流量经自己的美国 VPS 出口。
3. 一键连接、断开、自动重连与网络切换恢复。
4. DNS 路由与流量路由一致，避免 DNS 泄漏。
5. 显示当前模式、服务器、隧道状态、延迟、出口 IP 和错误诊断。
6. 与私有 IOS8 VPN Server 配合，支持设备独立授权、临时配对和配置更新。

Windows 与 iOS 的系统网络能力不同，尤其 iOS 的 Network Extension 限制；所有功能以各平台实际实现和测试结果为准，不承诺跨平台完全相同的分流粒度。

## 开发状态

| 模块 | 状态 |
|---|---|
| Hiddify 公开 Fork | 已建立 |
| 上游许可核对 | 已完成初步核对 |
| IOS8 中文品牌界面 | 待开发 |
| Windows 安装包 | 待构建与签名 |
| iPhone TestFlight | 待配置 Apple Developer / Network Extension 签名 |
| 智能分流 | 待接入自有服务端并测试 |
| 全局美国模式 | 待接入自有服务端并测试 |
| 设备临时配对 | 待与私有服务端联调 |

## 上游项目与许可

本仓库是以下项目的公开 Fork，不是 Hiddify 官方发行版：

- 上游源码：<https://github.com/hiddify/hiddify-app>
- 上游说明：<https://github.com/hiddify/hiddify-app/blob/main/README.md>
- 许可文件：本仓库根目录的 [LICENSE.md](LICENSE.md)

本项目保留 Hiddify、sing-box 和其他第三方组件的版权及许可声明。二次开发会记录在变更日志中。产品发布前将使用独立的 IOS8 VPN 名称、图标、色彩和重新设计的中文界面，不沿用 Hiddify 的产品品牌或近似视觉设计。

**使用限制：** 当前上游 `LICENSE.md` 为 Hiddify Extended GPL v3，包含额外条件，其中明确限制未经书面许可的商业用途，并要求公开 Fork、通过 GitHub Actions 发布、保留署名和以相同许可分享修改。当前项目按个人、非商业用途开发；每次跟进上游前都要重新检查许可内容。

## 构建与发布原则

- 正式构建与发布使用 GitHub Actions。
- Windows 安装包在未配置 Authenticode 证书前，明确标记为未签名。
- iPhone 版本需独立的 Apple Developer 账号、Network Extension entitlement、Bundle ID、App Group 和签名配置；优先通过 TestFlight 内测。
- 不把证书、P12、Provisioning Profile、API 密钥、服务端私钥或设备长期凭据提交到仓库。
- Release 必须附版本说明和 SHA-256 校验值。

## 中文开发文档

见 [IOS8 VPN 中文开发路线图](docs/IOS8-VPN-ROADMAP.zh-CN.md)。

---

**注意：** 当前默认分支跟随 Hiddify 上游更新。对上游同步后，必须先检查 Windows / iOS 构建、路由规则、系统 VPN 权限和许可变化，再决定是否作为 IOS8 VPN 的发布基线。
