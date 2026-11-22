# cmp-app

Compose Multiplatform 起步工程，一套 Kotlin 代码同时构建 **Android / iOS / 桌面 / Web(Wasm)**。

| 组件 | 版本 |
| --- | --- |
| Kotlin | **2.4.21** |
| Compose Multiplatform | **1.13.0-rc01** |
| AndroidX Compose BOM | **2026.11.01**（仅约束 Android 侧，见下方说明） |
| Android Gradle Plugin | 9.2.1（编译 SDK 37.1） |
| Gradle | 9.5.0 **-all**（wrapper，腾讯云镜像分发，含源码与文档） |
| JDK | 17+（本机使用 25 运行 Gradle，产物 bytecode 为 17） |

> 说明：截至 2026-11，Compose Multiplatform 1.13 线上只发布到 `1.13.0-rc01`（Jetpack Compose 1.13 已 stable），
> 因此这里锁定 `1.13.0-rc01`；正式版发布后只需改 `gradle/libs.versions.toml` 里的 `compose` 一行。

### 关于 compose-bom

`androidx.compose:compose-bom:2026.11.01` 已接入 `androidApp` 模块，但它**不能替代** `org.jetbrains.compose.*`：

- BOM 管理的是 `androidx.compose.*` 构件，而 `androidx.compose.ui:ui` 只发布 android / jvmStubs / linuxx64Stubs
  变体，**没有 iOS、Wasm 产物**，放进 `commonMain` 会让 iOS/Wasm 直接解析失败。
- 所以 `commonMain` 仍用 JetBrains 坐标（`org.jetbrains.compose.*`，一套坐标覆盖四端）。
- BOM 的实际作用是统一 **Android 侧的 androidx 传递依赖版本**：本项目实测把传递进来的
  `ui:1.10.0/1.11.0-rc01/1.12.0` 全部提升到 `1.13.0`、`material3:1.3.1` 提升到 `1.5.0`，
  与 CMP 1.13.0-rc01 内部要求的版本一致。
- 注意 `platform()` 扩展在 KMP 的 `sourceSets { }` 里不可用（`Unresolved reference 'platform'`），
  只能在普通 Android 模块的 `dependencies { }` 中使用。

## 目录结构

```
cmp-app/
├── composeApp/          # KMP 共享模块：UI + 各平台 actual 实现
│   └── src/
│       ├── commonMain/  # App() 共享 UI、expect 声明
│       ├── androidMain/ # Android actual
│       ├── desktopMain/ # 桌面 actual
│       ├── iosMain/     # iOS actual + MainViewController
│       └── wasmJsMain/  # Web actual
├── androidApp/          # Android 应用壳（MainActivity）
├── desktopApp/          # 桌面应用壳（main + 打包 dmg）
├── webApp/              # Web 应用壳（wasmJs + index.html）
├── iosApp/              # Xcode 工程（SwiftUI 承载 Compose）
├── scripts/             # 辅助脚本（iOS 模拟器一键预览）
└── docs/                # 各端运行截图
```

## 依赖源

`settings.gradle.kts` 与 `gradle/wrapper/gradle-wrapper.properties` 均使用腾讯云镜像：

- Gradle 发行包：`https://mirrors.cloud.tencent.com/gradle/`（wrapper 使用 `gradle-9.5.0-all.zip`，
  即含源码与离线文档的完整版，约 229 MB；`distributionSha256Sum` 已锁官方哈希 `a3c4ba4a…391439`）
- Maven / Google / Gradle 插件门户：`https://mirrors.cloud.tencent.com/nexus/repository/maven-public/`、`.../gradle-plugins/`

腾讯云未命中的坐标会自动回落到官方 `google()` / `mavenCentral()`。

## 常用命令

```bash
# 桌面端：直接运行
./gradlew :desktopApp:run

# 桌面端：打包 dmg
./gradlew :desktopApp:packageDmg

# Web:开发服务器（默认 http://localhost:8080）
./gradlew :webApp:wasmJsBrowserDevelopmentRun

# Web:产出静态站点 build/dist/wasmJs/productionExecutable
./gradlew :webApp:build

# Android:安装到已连接设备 / 打 debug 包
./gradlew :androidApp:installDebug
./gradlew :androidApp:assembleDebug
```

iOS 两种跑法：

1. **Xcode 里跑**：`open iosApp/iosApp.xcodeproj`，在 Signing & Capabilities 里选好 Team（或直接改
   `iosApp/Configuration/Config.xcconfig` 的 `TEAM_ID`）后运行。Xcode 的 Run 会通过
   `gradlew :composeApp:embedAndSignAppleFrameworkForXcode` 自动编译 Kotlin Framework。
   跑模拟器不需要 Team，真机才需要。
2. **命令行跑模拟器（无需签名、自动截图）**：

   ```bash
   ./scripts/ios-sim-preview.sh                          # 默认 iPhone 17，截图到 docs/ios-simulator.png
   ./scripts/ios-sim-preview.sh "iPhone 17 Pro" /tmp/x.png
   ```

   首次需先装模拟器 runtime：`xcodebuild -downloadPlatform iOS`（约 8 GB）。

## 首次构建注意

- **Node / npm**：`gradle.properties` 中已设置 `kotlin.js.nodejs.download=false`、`kotlin.js.yarn=false`，
  构建 Web 时直接使用本机 Node 与 npm。项目根目录与 `webApp/` 下均放置了 `.npmrc`，把 npm 源指向
  腾讯云镜像（`https://mirrors.cloud.tencent.com/npm/`）；若仍拉包失败，可临时
  `export NPM_CONFIG_REGISTRY=https://mirrors.cloud.tencent.com/npm/` 再执行构建。
- **Android SDK**：AGP 会自动下载 `platforms;android-37.1` 与 `build-tools;36.0.0`，首次构建耗时较长；
  如自动安装卡住，请在 Android Studio 的 SDK Manager 中手动安装这两个组件。
- **Gradle 用的是 `-all` 发行包**：比 `-bin` 多带 `src/` 源码与 `docs/` 离线文档，解压后约 538 MB
  （`~/.gradle/wrapper/dists/gradle-9.5.0-all/`）。若之前跑过 `-bin` 版，可删掉
  `~/.gradle/wrapper/dists/gradle-9.5.0-bin/` 回收空间。IDE 里想跳进 Gradle API 源码就依赖这个包。
- **Kotlin/Native**：首次构建 iOS 会下载 LLVM 等工具链（约数百 MB）到 `~/.konan`。
- **npm 安装中断后 webpack 报 `Cannot find module .../@jridgewell/gen-mapping`**：说明 npm 缓存被写坏，
  删掉 `~/.kotlin/kotlin-npm-tooling/npm/*` 与 `webApp/build/js` 后重跑即可。
- **iOS 启动即闪退，日志报 `Info.plist doesn't have a valid CADisableMinimumFrameDurationOnPhone entry`**：
  Compose Multiplatform 1.13 新增了 plist 强制校验（`PlistSanityCheck`），缺这个键会直接抛
  `IllegalStateException`。本项目已在 `iosApp/iosApp/Info.plist` 中补上
  `<key>CADisableMinimumFrameDurationOnPhone</key><true/>`；自己新建 iOS 工程时务必一并添加。
- **iOS 构建报 `Unknown iOS simulator arch: 'x86_64'`**：因为 CMP 1.13 不再发布 `iosX64` 产物，
  Kotlin Framework 只有 arm64。用 `generic/platform=iOS Simulator` 时必须显式限制架构：
  `ARCHS=arm64 ONLY_ACTIVE_ARCH=YES VALID_ARCHS=arm64`（脚本里已处理）。

## 本机构建验证记录

| 目标 | 命令 | 结果 |
| --- | --- | --- |
| 桌面 | `./gradlew :desktopApp:run` | BUILD SUCCESSFUL，窗口正常启动、无异常退出（截图受 macOS 录屏权限限制未能抓取） |
| Android | `./gradlew :androidApp:assembleDebug` | BUILD SUCCESSFUL，产出 `androidApp/build/outputs/apk/debug/androidApp-debug.apk`（12 MB） |
| iOS Framework | `./gradlew :composeApp:linkDebugFrameworkIosSimulatorArm64` | BUILD SUCCESSFUL，产出 `ComposeApp.framework` |
| iOS 模拟器实机 | `./scripts/ios-sim-preview.sh` | BUILD SUCCEEDED → 装入 iPhone 17 (iOS 26.0.1) → 启动 → 渲染正常，截图 `docs/ios-simulator.png` |
| Web (打包) | `./gradlew :webApp:build` | BUILD SUCCESSFUL，产物在 `webApp/build/dist/wasmJs/productionExecutable/` |

Web 端实机渲染（Chrome + SwiftShader，截图见 `docs/web-wasm.png`）：
标题 "Compose Multiplatform"、平台行 "Web · WebAssembly"、卡片 "Kotlin 2.4.21 · Compose 1.13.0-rc01"
与 "点我 +1" 按钮均正常绘制，说明 Material3 主题与 wasm 运行时链路无问题。

iOS 模拟器实机渲染（截图见 `docs/ios-simulator.png`）：标题 "Compose Multiplatform"、平台行
"运行平台：iOS 26.0.1"、卡片 "Kotlin 2.4.21 · Compose 1.13.0-rc01"、"已点击 0 次" 与 "点我 +1"
按钮均正常绘制，Skia/Metal 渲染与状态管理在 iOS 侧一致。


## 包名与标识

| 位置 | 值 |
| --- | --- |
| Kotlin 包名（全部源码） | `com.dicek.app` |
| `composeApp` 的 Android namespace | `com.dicek.app.shared` |
| `androidApp` 的 namespace / applicationId | `com.dicek.app` |
| iOS `BUNDLE_ID`（`Config.xcconfig`） | `com.dicek.app` |

> `composeApp` 与 `androidApp` 的 Android namespace **必须不同**，否则 manifest merger 报
> "Namespace used in multiple modules"，因此库模块加 `.shared` 后缀。

## 平台说明

- **iosX64（Intel 模拟器）已移除**：Compose Multiplatform 1.13 不再发布该产物，只保留 `iosArm64` 与 `iosSimulatorArm64`。
- **iOS 模拟器 runtime 是独立下载项**：只装 Xcode 不等于有模拟器。`xcrun simctl list runtimes` 为空时，
  需要 `xcodebuild -downloadPlatform iOS`（约 8 GB），否则 xcodebuild 会报 `iOS 26.0 is not installed`。
- **Android 编译 SDK 37.1**：AGP 9 起用 `compileSdk { version = release(37) { minorApiLevel = 1 } }` 语法；本机 SDK 缺该平台时 AGP 会自动下载。
- **AGP 9 的 KMP 结构**：`composeApp` 用 `com.android.kotlin.multiplatform.library`，`androidApp` 用 `com.android.application`，两者不再共用一个模块。

## 代码入口

- 共享 UI：`composeApp/src/commonMain/kotlin/com/dicek/app/App.kt`
- 平台名：各 `Platform.*.kt` 实现 `expect fun platformName()`
