# BatchPing for macOS

批量 Ping 多个 IP / 域名，以表格形式实时展示连通率与延迟，类似 Windows 上的 PingInfoView。

## 一、技术栈选型

| 方案 | 启动速度 | 内存 | 打包体验 | 系统权限 | 开发效率 |
| --- | --- | --- | --- | --- | --- |
| **Swift + SwiftUI（采用）** | 秒开 | **28MB（本机实测 footprint）** | `swift build` + 脚本组装 .app/dmg；上架需 Xcode | 无需 root | 单语言，无 IPC |
| Rust + Tauri + React | 稍慢（WebView 初始化） | ~70MB（典型值，未实测） | `cargo tauri build` 直接出 dmg | 无需 root | 需定义命令协议 + 异步桥 |
| Electron + TypeScript | ~1.5s+ | ~200MB（典型值，未实测） | electron-builder 出 dmg | 无需 root | 额外背一个 Chromium |

选 Swift 的理由：

1. **ICMP 部分三种方案没有差别**——需求允许使用系统 `ping` 命令，所以差异全部落在界面壳上。SwiftUI 用系统控件实现表格几乎零成本，而 Tauri / Electron 需要额外背 WebView（~40MB）与前后端序列化。
2. **CPU / 内存更低**：常驻监控时每个目标只有一个 `/sbin/ping` 子进程，发包节奏由内核定时器驱动，空闲时几乎不消耗 CPU；界面没有 WebView 常驻开销。
3. **打包链路最短**：只依赖 Xcode Command Line Tools（`swift build`），不需要 Node / Rust / Python 工具链，也不会在打包时拉取几百 MB 依赖。
4. **产品本身就是 macOS-only**，跨平台不是需求，Rust+Tauri 的唯一优势用不上。

## 二、整体架构

```text
┌────────────────────────────── SwiftUI 界面层 (BatchPing) ──────────────────────────────┐
│  ContentView / TargetsTableView / TargetEditorSheet / SettingsSheet                   │
│  BatchPingViewModel：目标列表、排序、UI 节流刷新、配置持久化触发                      │
└───────────────▲───────────────────────────────────────────────────────────┬───────────┘
                │ onStats(id, PingStats) 回调（引擎队列 → 主队列，4Hz 合并）   │ 命令
┌───────────────┴────────────── 核心逻辑层 (PingCore，平台无关、可单测）───────────────┐
│  PingEngine：并发调度（信号量式槽位管理）、轮换、启停、统计聚合                          │
│  PingProcess：单个目标的 /sbin/ping 子进程封装，异步读 stdout/stderr，按行解析           │
│  PingLineParser：纯函数解析 ping 输出 → PingEvent（reply/timeout/unreachable/failure） │
│  ConfigStore：JSON 配置读写 ~/Library/Application Support/BatchPing/config.json       │
│  CsvExporter：结果导出（带 UTF-8 BOM，Excel 友好）                                     │
└──────────────────────────────────────────────────────────────────────────────────────┘
                                  │
                            /sbin/ping -i <间隔> <目标>
```

关键设计：

- **低 CPU**：`ping` 进程常驻，由内核按 `-i` 间隔发包，而不是每轮重新拉起进程；界面侧对统计更新做 250ms 合并，避免高频重绘。
- **并发限制**：`PingEngine` 维护固定数量的运行槽位，目标数超过 `maxConcurrent` 时，按 `rotationInterval` 轮换探测，保证所有目标都被覆盖。
- **丢包率不依赖 ping 的超时输出**：只使用 macOS `ping` 必定支持的 `-i` 参数（`-W` / `-t` 在不同 BSD 版本间语义不一致，传错会让 ping 直接报 usage 错误）。收发包计数以 `icmp_seq` 为准：`sent = 基准 + seq + 1`，回包序号跳号即说明中间丢包；进程重启导致 seq 归零时用基准值衔接。
- **错误处理**：解析 `ping` 的三类失败——目标无效（`cannot resolve host` → 状态「错误」并停止该目标进程）、网络不可达（`No route to host` → 状态「不可达」）、发包失败（`sendto:` → 计入丢包）。权限不足时系统 ping 会输出 `Operation not permitted`，同样以「错误」呈现并在悬浮提示中给出原始信息。

## 三、目录结构

```text
.
├── Package.swift                  # SwiftPM 包定义（PingCore 库 + BatchPing 可执行 + 测试）
├── Makefile                       # build / run / test / app / dmg
├── README.md
├── Sources/
│   ├── PingCore/                  # 与界面无关的核心逻辑
│   │   ├── Models.swift           # PingTarget / TargetStatus / PingStats / PingSettings
│   │   ├── PingParser.swift       # ping 输出解析（纯函数）
│   │   ├── PingProcess.swift      # ping 子进程封装 + 行缓冲
│   │   ├── PingEngine.swift       # 并发调度器
│   │   ├── ConfigStore.swift      # 配置持久化
│   │   └── CsvExporter.swift      # CSV 导出
│   └── BatchPing/                 # SwiftUI 界面层
│       ├── BatchPingApp.swift     # @main App
│       ├── BatchPingViewModel.swift
│       ├── ContentView.swift      # 工具栏 / 表格 / 状态栏 / CSV 导出
│       ├── TargetsTableView.swift # 表格
│       ├── TargetEditorSheet.swift
│       └── SettingsSheet.swift
├── Tests/PingCoreTests/           # 解析器、统计、CSV 单元测试
└── scripts/
    ├── bundle.sh                  # 生成 dist/BatchPing.app
    └── dmg.sh                     # 生成 dist/BatchPing-1.0.0.dmg
```

## 四、构建与运行

前置条件：macOS 13+，已安装 Xcode Command Line Tools（`xcode-select --install`）。

```bash
# 构建（release）
swift build -c release

# 运行（开发模式）
swift run BatchPing
# 或
make run

# 运行单元测试
swift test
# 或
make test
```

## 五、打包成 macOS 应用

```bash
make app     # 构建 + 组装 dist/BatchPing.app（含 Info.plist，ad-hoc 签名）
make dmg     # 进一步生成 dist/BatchPing-1.0.0.dmg
open dist/BatchPing-1.0.0.dmg
```

脚本做的事情：

1. `swift build -c release` 产出无 bundle 的可执行文件；
2. 用 `scripts/make-icon.swift` 脚本化渲染图标（仓库里不放二进制资源），`iconutil` 打成 `.icns`；
3. 手工组装 `BatchPing.app/Contents/{MacOS,Resources}` 与 `Info.plist`（SwiftUI 应用必须有 Info.plist 才能正确显示为窗口应用）；
4. `codesign` 签名：默认 ad-hoc，设置 `DEVELOPER_ID_APPLICATION` 环境变量则改用该证书 + Hardened Runtime；
5. `hdiutil create` 制作 DMG。

脚本支持的环境变量：`BIN_PATH`（可执行文件路径）、`APP_PATH`（.app 输出路径）、`DMG_PATH`（DMG 输出路径）、`DEVELOPER_ID_APPLICATION`（签名证书）。

**正式分发（对外发布 / 免 Gatekeeper 拦截）**需要：

- 苹果开发者账号 + Developer ID Application 证书；
- `codesign --options runtime --timestamp` 签名，并开启 Hardened Runtime；
- `xcrun notarytool submit ... --wait` 公证，`xcrun stapler staple` 装订公证票据。

若要上架 Mac App Store，必须启用 App Sandbox——**沙盒会禁止进程 fork/exec，无法调用 `/sbin/ping`**，届时需改为在沙盒内用 `Network.framework` + `NWConnection`（仅支持 TCP/UDP）或申请 `com.apple.security.network.client` 之外的内核扩展权限；本实现按「非沙盒、直接分发」设计。

## 六、权限与系统限制说明

1. **不需要 root / 管理员权限**。macOS 的 `/sbin/ping` 使用 SOCK_DGRAM ICMP，未特权用户即可使用（不像 Linux 需要 `setuid` 或 `cap_net_raw`）。
2. **发包间隔下限**：macOS 下非 root 用户的最小间隔约 0.2s，本工具下限设为 0.5s（设置面板 0.5–10s）。
3. **应用未启用 App Sandbox**，因此可以创建子进程；代价是不能直接上架 Mac App Store（见上）。
4. **首次运行的网络权限**：本工具只发起 ICMP 出站请求，不监听端口，macOS 不会弹网络权限对话框。
5. **IPv6**：目标含 `:` 时自动改用 `/sbin/ping6`。
6. **配置文件位置**：`~/Library/Application Support/BatchPing/config.json`，目标列表与设置在下次启动时自动加载。

## 七、功能对照

| 需求 | 实现位置 |
| --- | --- |
| 添加 / 删除 / 编辑目标 | 工具栏「添加 / 编辑 / 删除」+ 每行启用开关 |
| 批量 Ping、独立状态 | `PingEngine` 每目标一个进程，`TargetStatus` 独立状态 |
| 表格列 | 目标 / 状态 / 最新 / 平均 / 最小 / 最大 / 丢包率 / 最后响应时间 |
| 开始 / 停止 / 刷新 / 清空 | 工具栏按钮 |
| 并发限制 | 设置项「最大并发数」+「轮换周期」 |
| 导出 CSV | 工具栏「导出 CSV」，带 UTF-8 BOM |
| 深色模式 | 全部使用系统语义色，自动跟随系统外观 |
| 后台低 CPU | 内核定时发包 + 250ms UI 合并刷新 |
| 配置保存 | `ConfigStore` 写 JSON，启动自动加载 |
| 使用系统能力 | 复用 `/sbin/ping` / `/sbin/ping6`，无第三方依赖 |

## 八、本机验证结果

| 项目 | 结果 |
| --- | --- |
| `swift build` | 通过，0 error / 0 warning |
| `swift test` | 13 个用例全部通过（解析器、统计、CSV、配置序列化、真实 ping 集成） |
| 真实环境验证 | 环回 8 包 8 通；`192.0.2.1` 7 发包 0 回包、丢包率 100%；`nope.invalid` 正确报 `cannot resolve` |
| `make app` / `make dmg` | 生成 `BatchPing.app`（ad-hoc 签名）与 `BatchPing-1.0.0.dmg` |
| 运行资源 | 空闲 CPU **0.0%**，内存 footprint **28MB**（RSS 约 100MB，含共享框架页） |

尚未由本机自动化验证的部分：界面交互（点击添加 / 开始 / 导出等）。本机终端没有「屏幕录制」和「辅助功能」权限，无法截图或脚本点击，需人工点一遍确认。

## 九、GitHub Actions 自动构建

工作流：[.github/workflows/build.yml](.github/workflows/build.yml)

首次推送（建仓 + 首次提交 + 推送到公开仓库 `pingman`）：

```bash
gh auth login          # 若尚未登录
bash scripts/publish.sh
```

| 触发条件 | 行为 |
| --- | --- |
| push 到 `main` / 提 PR 到 `main` | 构建 + 测试 + 打包 + 上传 Artifact |
| 推送 `v*` 标签 | 同上，并额外创建 GitHub Release 附带 DMG |
| 手动触发 | 同上 |

流水线步骤：`xcodebuild build` → `swift test` → 导入签名证书 → `scripts/bundle.sh` 组装 `.app` → `notarytool` 公证并 `stapler` 装订 → `scripts/dmg.sh` 制作 DMG → 上传 Artifact →（打标签时）创建 Release。

### 可选 Secrets

不配置任何 Secret 也能跑通全流程，只是产物为 ad-hoc 签名、无公证（其他人机器上首次打开需右键打开或 `xattr -d com.apple.quarantine`）。配置后自动启用 Developer ID 签名 + 公证：

| Secret | 内容 |
| --- | --- |
| `DEVELOPER_ID_APPLICATION` | 证书名称，例如 `Developer ID Application: Your Name (TEAMID)` |
| `APPLE_CERTIFICATE_P12_BASE64` | 导出的 `.p12` 的 base64 文本 |
| `APPLE_CERTIFICATE_PASSWORD` | `.p12` 的密码 |
| `APPLE_ID` | Apple ID 邮箱 |
| `APPLE_TEAM_ID` | 10 位 Team ID |
| `APPLE_APP_SPECIFIC_PASSWORD` | Apple ID 的「app 专用密码」 |

准备证书：

```bash
# 1. 导出 .p12（钥匙串访问 → 右键证书 → 导出）
# 2. 转成 base64 单行文本，粘进 APPLE_CERTIFICATE_P12_BASE64
openssl base64 -A -in DeveloperIDApplication.p12
```

### 本地复现 CI 的每一步

```bash
xcodebuild build -scheme BatchPing -configuration Release \
  -destination "generic/platform=macOS" -derivedDataPath .build/xcode CODE_SIGNING_ALLOWED=NO
swift test
BIN_PATH="$PWD/.build/xcode/Build/Products/Release/BatchPing" bash scripts/bundle.sh
bash scripts/dmg.sh
```

工作流里做了兼容处理：先用 `xcodebuild -list -json` 找 `BatchPing` scheme，找不到就自动回退到 `swift build -c release`，产物路径通过 `BIN_PATH` 传给打包脚本，两条路径都能出包。
