# IOS8 VPN iPhone 交付状态

Windows 联网已由用户验收。iPhone 继续使用同一设备配对、独立凭据和服务端配置 API，不重部署 VPS。

## 本次接入

- iPhone 首次连接自动获取并校验设备配置，失败时显示错误，不退回旧配置。
- 主页提供设备授权、智能分流和全局模式，不要求手动导入节点。
- 配置导入期间跳过同一连接操作引起的配置监听，直接使用校验完成的配置。
- 复用 Windows 已覆盖的未授权、撤销、同步中、设备不匹配及核心拒绝配置的测试。

## 尚未完成，不能称为 iPhone 可安装版本

- GitHub 源码测试不等同于 Xcode 编译、真机运行或 VPN 数据平面验证。
- iOS 原生项目仍有上游应用标识、开发团队和导出配置。正式构建前必须替换为 IOS8 自有 App ID、App Group、开发团队及主应用和 Packet Tunnel 扩展的描述文件。
- pubspec 的预览版本和原生扩展版本需要在 iOS 构建流程中同步；现有上游发布校验不接受预发布版本。
- 需要完成独立的 iOS 云端编译、签名、TestFlight 上传和真机授权/连接/断开验收。
- 用户当前没有 Apple Developer Program 账号，不能生成自有 TestFlight 安装链接。
- Apple 的 VPN 应用审核规则 5.4 要求组织开发者身份。请先确定组织资格，再办理适用的账号；不能承诺个人账号一定可以发布。

官方说明：
- https://developer.apple.com/app-store/review/guidelines/#vpn-apps
- https://developer.apple.com/testflight/

## Windows 签名

现有 `windows-signed-candidate.yml` 需要用户自有、受公开信任的签名证书或受支持的签名服务身份。
目前用户没有证书或签名服务账号，尚未执行正式签名。不得以自签名、未签名包或仅构建成功替代正式签名。
