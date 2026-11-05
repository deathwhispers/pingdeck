# BatchPing 开发说明

面向维护者的技术文档。产品介绍与使用方式见 [README](../README.md)。

## 技术栈选型

| 方案 | 启动速度 | 内存 | 打包体验 | 系统权限 | 开发效率 |
| --- | --- | --- | --- | --- | --- |
| **Swift + SwiftUI（采用）** | 秒开 | **28MB（本机实测 footprint）** | `swift build` + 脚本组装 .app/dmg；上架需 Xcode | 无需 root | 单语言，无 IPC |
| Rust + Tauri + React | 稍慢（WebView 初始化） | ~70MB（典型值，未实测） | `cargo tauri build` 直接出 dmg | 无需 root | 需定义命令协议 + 异步桥 |
| Electron + TypeScript | ~1.5s+ | ~200MB（典型值，未实测） | electron-builder 出 dmg | 无需 root | 额外背一个 Chromium |

选 Swift 的理由：

1. **ICMP 部分三种方案没有差别**——都复用系统 `ping`，差异全部落在界面壳上。SwiftUI 用系统控件实现表格几乎零成本，Tauri / Electron 需要额外背 WebView（~40MB）与前后端序列化。
2. **CPU / 内存更低**：常驻监控时每个目标只有一个 `/sbin/ping` 子进程，发包节奏由内核定时器驱动，空闲时几乎不消耗 CPU。
3. **打包链路最短**：只依赖 Xcode Command Line Tools，不需要 Node / Rust 工具链。
4. **产品本身就是 macOS-only**，跨平台不是需求。

## 架构

```text
┌────────────────────────────── SwiftUI 界面层 (BatchPing) ──────────────────────────────┐
│  ContentView / TargetsTableView / TargetEditorSheet / BulkImportSheet / SettingsSheet  │
│  BatchPingViewModel：目标列表、排序、选中、UI 节流刷新、配置持久化触发                   │
└───────────────▲───────────────────────────────────────────────────────────┬───────────┘
                │ onStats(id, PingStats) 回调（引擎队列 → 主队列，4Hz 合并）   │ 命令
┌───────────────┴────────────── 核心逻辑层 (PingCore，平台无关、可单测）───────────────┐
│  PingEngine：并发调度（槽位管理）、轮换、启停、统计聚合                                   │
│  PingProcess：单个目标的 /sbin/ping 子进程封装，异步读 stdout/stderr，按行解析             │
│  PingLineParser：纯函数解析 ping 输出 → PingEvent（reply/timeout/unreachable/failure）   │
│  BulkImportParser / TargetValidator：批量导入解析与目标校验                               │
│  ConfigStore：JSON 配置读写 ~/Library/Application Support/BatchPing/config.json         │
│  CsvExporter：结果导出（带 UTF-8 BOM，Excel 友好）                                       │
└──────────────────────────────────────────────────────────────────────────────────────┘
                                  │
                            /sbin/ping -i <间隔> <目标>
```

关键设计：

- **低 CPU**：`ping` 进程常驻，由内核按 `-i` 间隔发包，而不是每轮重新拉起进程；界面侧对统计更新做 250ms 合并，避免高频重绘。
- **并发限制**：`PingEngine` 维护固定数量的运行槽位，目标数超过 `maxConcurrent` 时按 `rotationInterval` 轮换探测，保证所有目标都被覆盖。
- **丢包率不依赖 ping 的超时输出**：只使用 macOS `ping` 必定支持的 `-i` 参数（`-W` / `-t` 在不同 BSD 版本间语义不一致，传错会让 ping 直接报 usage 错误）。收发包计数以 `icmp_seq` 为准：`sent = 基准 + seq + 1`，回包序号跳号即说明中间丢包；进程重启导致 seq 归零时用基准值衔接。
- **停用即终止**：关闭某一行的启用开关会让引擎停止对应进程并把状态置为「已停用」，重新启用则重新入队。
- **错误处理**：解析 `ping` 的三类失败——目标无效（`cannot resolve host` → 状态「错误」并停止该目标进程）、网络不可达（`No route to host` → 状态「不可达」）、发包失败（`sendto:` → 计入丢包）。

## 目录结构

```text
.
├── Package.swift                  # SwiftPM：PingCore 库 + BatchPing 可执行 + 两个测试目标
├── Makefile                       # build / run / test / app / dmg
├── VERSION                        # 版本号唯一来源
├── CHANGELOG.md
├── README.md                      # 产品说明
├── docs/DEVELOPMENT.md            # 本文档
├── Sources/
│   ├── PingCore/                  # 与界面无关的核心逻辑
│   │   ├── Models.swift           # PingTarget / TargetStatus / PingStats / PingSettings
│   │   ├── PingParser.swift       # ping 输出解析（纯函数）
│   │   ├── PingProcess.swift      # ping 子进程封装 + 行缓冲
│   │   ├── PingEngine.swift       # 并发调度器
│   │   ├── BulkImport.swift       # 批量导入解析
│   │   ├── TargetValidator.swift  # 目标合法性校验
│   │   ├── ConfigStore.swift      # 配置持久化
│   │   └── CsvExporter.swift      # CSV 导出
│   └── BatchPing/                 # SwiftUI 界面层
│       ├── BatchPingApp.swift     # @main App + 菜单 + 单实例保护
│       ├── BatchPingViewModel.swift
│       ├── ContentView.swift      # 工具栏 / 状态栏 / 导出
│       ├── TargetsTableView.swift # 表格（List 原生多选 + 表头排序）
│       ├── TargetEditorSheet.swift
│       ├── BulkImportSheet.swift
│       └── SettingsSheet.swift
├── Tests/
│   ├── PingCoreTests/             # 解析、统计、CSV、批量导入、引擎调度
│   └── BatchPingTests/            # 界面层逻辑：选中、清空、导出范围、导入模式
└── scripts/
    ├── bundle.sh                  # 组装 .app（可指定 BIN_PATH / VERSION / 签名证书）
    ├── dmg.sh                     # 生成 DMG
    ├── make-icon.swift            # 脚本化渲染图标（仓库不放二进制资源）
    └── publish.sh                 # 首次推送到 GitHub
```

## 构建、测试与打包

前置条件：macOS 13+、Xcode Command Line Tools。

```bash
make build            # swift build -c release
make run              # 直接运行（无 .app bundle）
make test             # 单元测试
make app              # 组装 dist/BatchPing.app
make dmg              # 生成 dist/BatchPing-<VERSION>.dmg
```

打包脚本支持的环境变量：`BIN_PATH`、`APP_PATH`、`DMG_PATH`、`VERSION`、`DEVELOPER_ID_APPLICATION`。
**版本号唯一来源是仓库根目录的 `VERSION` 文件**，脚本与 CI 都从这里读取。

设置 `DEVELOPER_ID_APPLICATION` 时会使用该证书 + Hardened Runtime 签名，否则回退 ad-hoc 签名。

## 版本与发布

CI 工作流：[.github/workflows/build.yml](../.github/workflows/build.yml)

| 触发条件 | 行为 |
| --- | --- |
| 创建 PR 到 `main`（或重新打开） | 构建 + 测试 + 打包，上传 Artifact（不发布） |
| 往已有 PR 的分支继续提交 | 不触发 |
| 手动 Run workflow | `version` 留空则按 `VERSION` 文件构建；填 `0.0.2` 则按该版本打包并创建/更新 Release |

发布新版本的流程：

1. 更新 `VERSION` 与 `CHANGELOG.md`，合并到 `main`；
2. Actions → **Build** → **Run workflow**，`version` 填目标版本号（如 `0.0.1`）；
3. 流水线跑完后，Releases 页面会出现对应 tag，附带 `BatchPing-<版本>.dmg`。

### 可选 Secrets（开启 Apple 签名与公证）

不配置也能跑通全流程，产物为 ad-hoc 签名。配置后自动启用 Developer ID 签名 + 公证：

| Secret | 内容 |
| --- | --- |
| `DEVELOPER_ID_APPLICATION` | 证书名称，例如 `Developer ID Application: Your Name (TEAMID)` |
| `APPLE_CERTIFICATE_P12_BASE64` | 导出的 `.p12` 的 base64 文本 |
| `APPLE_CERTIFICATE_PASSWORD` | `.p12` 的密码 |
| `APPLE_ID` | Apple ID 邮箱 |
| `APPLE_TEAM_ID` | 10 位 Team ID |
| `APPLE_APP_SPECIFIC_PASSWORD` | Apple ID 的「app 专用密码」 |

```bash
# 导出 .p12（钥匙串访问 → 右键证书 → 导出）后转 base64
openssl base64 -A -in DeveloperIDApplication.p12
```

## 权限与系统限制

1. **不需要 root**：macOS 的 `/sbin/ping` 使用 SOCK_DGRAM ICMP，未特权用户即可使用。
2. **发包间隔下限**：非 root 用户约 0.2s，本工具下限设为 0.5s。
3. **未启用 App Sandbox**：所以可以创建子进程；代价是不能上架 Mac App Store（沙盒会禁止 fork/exec）。
4. **IPv6**：目标含 `:` 时自动改用 `/sbin/ping6`。
5. **单实例**：重复启动会激活已有窗口并退出，避免两个实例互相覆盖配置。

## 验证情况

| 项目 | 结果 |
| --- | --- |
| `swift build` | 0 error / 0 warning |
| `swift test` | 34 个用例全部通过 |
| 真实环境 | 环回 8 包 8 通；`192.0.2.1` 全部丢包；`nope.invalid` 正确报 `cannot resolve` |
| 打包 | `make app` / `make dmg` 正常，`CFBundleShortVersionString` 与 `VERSION` 一致，图标已嵌入 |
| 运行资源 | 空闲 CPU 0.0%，内存 footprint 约 28MB |

界面交互（点击、拖拽、弹窗）尚未纳入自动化测试，改动 UI 后需要人工点一遍。
