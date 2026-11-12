# Windows 正式候选包

`windows-installer-preview.yml` 仍只产出未签名预览。新增手动工作流 `windows-signed-candidate.yml`，仅允许 main 和 windows-release 环境。签名材料缺失、自签名证书、信任链无效、发布者不符或任何 PE 签名无效时失败，不上传候选 Artifact。

优先复用现有 Azure Artifact Signing 后端。配置环境变量 AZURE_SIGNING_ENDPOINT、AZURE_SIGNING_ACCOUNT、AZURE_SIGNING_CERT_PROFILE、WINDOWS_SIGNING_PUBLISHER（证书完整 Subject）、AZURE_CLIENT_ID、AZURE_TENANT_ID、AZURE_SUBSCRIPTION_ID；使用受限于该仓库 windows-release 环境的 OIDC 联合凭据。若已有其他合规 CA 签名方案，可使用原脚本支持的 WINDOWS_SIGNING_KEY / WINDOWS_SIGNING_PASSWORD Secrets；不要在聊天、Git 或日志粘贴私钥和证书密码。签名账户、身份验证和证书申请不能由代码伪造。

原有打包钩子签名应用和 DLL，Inno 签名工具签名安装器及卸载器。候选工作流再次检查 Release 文件和安装 EXE，并生成 manifest.json（EXE SHA-256、大小、证书及源提交）。这仍是候选资产，不自动发布 Release、不自动修改网站。

正式发布前必须在真实 Windows 进行安装、授权、连通、断开、智能/全局模式、撤销、重启恢复、卸载器签名和卸载清理验收。VPS 设备同步服务也必须上线；代码 CI 和签名成功都不能代替真实连接测试。验收通过后发布固定版本资产，再将网站下载元数据指向该资产。

下载中心不得使用 unsigned 预览作为正式包；不得使用 Artifact ZIP 的 SHA-256 代替安装 EXE 的 SHA-256。当前尚未提供签名凭据，也没有签名候选构建或正式发行。
