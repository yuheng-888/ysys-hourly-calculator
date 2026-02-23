# 发布与自动版本

本文件为内部发布说明，不面向普通用户。

## 自动打标签 / 自动版本

工作流：`.github/workflows/auto-tag.yml`

### 方式一：手动触发（推荐）
1. 打开 GitHub Actions
2. 选择 **Auto Tag**
3. 选择版本增量（patch / minor / major）
4. 运行后会自动创建新 tag（例如 `v3.3.1`）
5. tag 创建后，`release.yml` 会自动打包并发布

### 方式二：提交触发
在提交信息中包含 `[release]`，push 到 `main` 后会自动创建下一个 patch 版本。

## Release 工作流

工作流：`.github/workflows/release.yml`

- 自动构建 Windows（x64 / arm64）
- 自动构建 macOS PKG
- 自动生成 Release
- 自动附加截图（若存在）

### 附加截图
把截图命名为：`.github/release-assets/release-screenshot.png`
发布时会自动附加到 Release。

## Release Drafter（草稿更新日志）

工作流：`.github/workflows/release-drafter.yml`
配置：`.github/release-drafter.yml`

在 `main` 分支更新时自动生成 Draft Release，可作为发布前的更新日志参考。
