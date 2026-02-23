# ysys-hourly-calculator

跨平台时薪计算器（macOS + Windows），支持自动读取音频时长、手动计算与团队结算。

**适合人群**  
音频制作人、工作室、需要按时长/分钟结算的个人或团队。

**功能一览**  
1. 自动读取音频文件时长并计算金额  
2. 手动输入时长/金额并累计  
3. 团队结算：记录项目、制作人、日期和金额  
4. 费率记忆与设置开关

**目录说明**  
1. macOS 项目：`autuo sound time v2/`  
2. 打包脚本：`make-pkg.sh`  
3. Windows 工程：`windows/AutuoSoundTimeV3/`  
4. Windows 说明：`windows/README.md`

**macOS 使用（小白版）**  
前提：已安装 Xcode（从 App Store 安装即可）。

1. 打开终端，进入项目目录  
```
cd "<你的项目目录>"
```
2. 生成安装包  
```
bash make-pkg.sh
```
3. 安装  
双击生成的 `时薪计算器-亿声永势-V3-3.3.0.pkg`，按提示安装即可。

**macOS 进阶说明**  
1. 安装包默认会覆盖旧版本  
2. 图标、缓存问题已在脚本中处理  
3. 如果只需要运行不打包，可用 Xcode 直接 Run

**Windows 使用（小白版）**  
方式一：下载 GitHub Actions 生成的成品（推荐）。

1. 打开 GitHub 仓库页面  
2. 进入 **Actions**  
3. 选择 **Build Windows App**  
4. 点击 **Run workflow**  
5. 等待完成后，在 Artifacts 下载  
6. 选择你的系统版本  
   - `AutuoSoundTimeV3-win-x64`（大多数 Windows）  
   - `AutuoSoundTimeV3-win-arm64`（ARM 设备）  
7. 解压后直接运行 `.exe`

方式二：本地自己编译（开发者用）

1. 在 Windows 安装 **Visual Studio 2022** 或 **.NET 8 SDK**  
2. 打开 PowerShell，进入目录  
```
cd .\windows\AutuoSoundTimeV3
```
3. 生成发布版  
```
dotnet restore
dotnet publish -c Release -r win-x64 --self-contained true /p:PublishSingleFile=true
```
4. 成品在  
```
windows/AutuoSoundTimeV3/bin/Release/net8.0-windows/win-x64/publish
```

**常见问题**  
1. Windows 版为什么不能在 macOS 直接编译？  
因为 WPF 只支持 Windows，需要在 Windows 或 GitHub Actions 上构建。

2. 为什么 Actions 下载的是文件夹？  
因为是完整的运行目录，解压后直接双击 `.exe` 即可。

**说明**  
README 面向使用者，尽量保持简洁。  
如果需要构建/发布说明，请查看项目内部文档。
