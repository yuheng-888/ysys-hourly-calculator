# Windows 版本说明

项目位置：`windows/AutuoSoundTimeV3`

## 构建要求
- Windows 10/11
- Visual Studio 2022（安装 .NET 桌面开发）或 .NET 8 SDK

## 构建命令
```powershell
cd .\windows\AutuoSoundTimeV3
# 还原依赖
 dotnet restore
# 生成 Release
 dotnet publish -c Release -r win-x64 --self-contained true /p:PublishSingleFile=true
```

输出目录：`windows/AutuoSoundTimeV3/bin/Release/net8.0-windows/win-x64/publish`

如需 ARM64：把 `win-x64` 改为 `win-arm64`。

## GitHub Actions
已提供工作流：`.github/workflows/windows-build.yml`

触发后会产出两个 artifact：
- `AutuoSoundTimeV3-win-x64`
- `AutuoSoundTimeV3-win-arm64`

下载后即为可运行目录（含 exe）。
