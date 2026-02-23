#!/bin/bash
# 时薪计算器 PKG 安装包构建脚本
# 用法: cd "autuo sound time v2" && bash make-pkg.sh

set -e

# 配置（支持环境变量覆盖）
APP_NAME="${APP_NAME_OVERRIDE:-时薪计算器-亿声永势 V3}"
PKG_NAME="${PKG_NAME_OVERRIDE:-时薪计算器-亿声永势-V3}"
PKG_BUNDLE_ID="${PKG_ID_OVERRIDE:-ysys.autuo-sound-time-v3.pkg}"
APP_BUNDLE_ID="${APP_BUNDLE_ID_OVERRIDE:-ysys.autuo-sound-time-v3}"
OLD_BUNDLE_ID="${OLD_BUNDLE_ID_OVERRIDE:-ysys.autuo-sound-time-v2}"
VERSION="3.3.0"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${PROJECT_DIR}/build/pkg-build"
ARCHIVE_PATH="${BUILD_DIR}/app.xcarchive"
PKG_ROOT="${BUILD_DIR}/pkg-root"
SCRIPTS_DIR="${BUILD_DIR}/scripts"
OUTPUT_PKG="${PROJECT_DIR}/${PKG_NAME}-${VERSION}.pkg"

echo "=== 时薪计算器 PKG 构建 ==="
echo ""

# 清理旧构建
echo "[1/6] 清理旧构建..."
rm -rf "${BUILD_DIR}"
rm -rf ~/Library/Developer/Xcode/DerivedData/autuo_sound_time_v2-*
mkdir -p "${BUILD_DIR}" "${PKG_ROOT}/Applications" "${SCRIPTS_DIR}"

# 重新生成应用图标
echo "[2/6] 生成应用图标..."
if command -v python3 &>/dev/null; then
    python3 "${PROJECT_DIR}/generate_icon.py"
else
    echo "  警告: 未找到 python3，跳过图标生成"
fi

# 编译 Release 版本
echo "[3/6] 编译 Release 版本..."
xcodebuild archive \
    -project "${PROJECT_DIR}/autuo sound time v2.xcodeproj" \
    -scheme "autuo sound time v2" \
    -configuration Release \
    -archivePath "${ARCHIVE_PATH}" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_ALLOWED=NO \
    2>&1 | tail -5

# 从 archive 中提取 .app
echo "[4/6] 提取应用..."
APP_PATH="${ARCHIVE_PATH}/Products/Applications/autuo sound time v2.app"
if [ ! -d "${APP_PATH}" ]; then
    APP_PATH=$(find "${ARCHIVE_PATH}" -name "*.app" -type d | head -1)
fi

if [ -z "${APP_PATH}" ] || [ ! -d "${APP_PATH}" ]; then
    echo "错误: 找不到编译后的 .app 文件"
    exit 1
fi


cp -R "${APP_PATH}" "${PKG_ROOT}/Applications/${APP_NAME}.app"
echo "  应用路径: ${PKG_ROOT}/Applications/${APP_NAME}.app"

# 保留 Assets.car，同时补齐完整 AppIcon.icns
TARGET_APP="${PKG_ROOT}/Applications/${APP_NAME}.app"
if [ -f "${TARGET_APP}/Contents/Resources/Assets.car" ]; then
    echo "  图标已包含在 Assets.car 中"
else
    echo "  警告: 未找到 Assets.car，可能会导致图标缺失"
fi

echo "  生成完整 AppIcon.icns..."
ICONSET_TMP="${BUILD_DIR}/AppIcon.iconset"
ASSET_SRC="${PROJECT_DIR}/autuo sound time v2/Assets.xcassets/AppIcon.appiconset"
ICNS_TMP="${BUILD_DIR}/AppIcon.icns"
mkdir -p "${ICONSET_TMP}"
for f in icon_16x16.png icon_16x16@2x.png icon_32x32.png icon_32x32@2x.png icon_128x128.png icon_128x128@2x.png icon_256x256.png icon_256x256@2x.png icon_512x512.png icon_512x512@2x.png; do
    cp "${ASSET_SRC}/${f}" "${ICONSET_TMP}/${f}"
done
iconutil -c icns "${ICONSET_TMP}" -o "${ICNS_TMP}"
cp "${ICNS_TMP}" "${TARGET_APP}/Contents/Resources/AppIcon.icns"
rm -rf "${ICONSET_TMP}" "${ICNS_TMP}"

if [ -f "${TARGET_APP}/Contents/Info.plist" ]; then
    # 同时设置 IconName（资产目录）和 IconFile（Finder icns）
    /usr/libexec/PlistBuddy -c "Set :CFBundleIconName AppIcon" "${TARGET_APP}/Contents/Info.plist" 2>/dev/null || \
        /usr/libexec/PlistBuddy -c "Add :CFBundleIconName string AppIcon" "${TARGET_APP}/Contents/Info.plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon.icns" "${TARGET_APP}/Contents/Info.plist" 2>/dev/null || \
        /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon.icns" "${TARGET_APP}/Contents/Info.plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier ${APP_BUNDLE_ID}" "${TARGET_APP}/Contents/Info.plist" 2>/dev/null || \
        /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string ${APP_BUNDLE_ID}" "${TARGET_APP}/Contents/Info.plist" 2>/dev/null || true
    echo "  Info.plist 已更新为 AppIcon（资产目录）+ AppIcon.icns"
fi

# 创建安装脚本
echo "[5/6] 创建安装脚本..."

# preinstall: 安装前关闭旧版本并清理
cat > "${SCRIPTS_DIR}/preinstall" << 'PREINSTALL'
#!/bin/bash
killall "__APP_NAME__" 2>/dev/null || true
sleep 1
rm -rf "/Applications/__APP_NAME__.app" 2>/dev/null || true
rm -rf "/Applications/__APP_NAME__.localized" 2>/dev/null || true
rm -rf /Library/Caches/com.apple.iconservices.store 2>/dev/null || true
exit 0
PREINSTALL
perl -pi -e "s/__APP_NAME__/${APP_NAME}/g" "${SCRIPTS_DIR}/preinstall"
chmod +x "${SCRIPTS_DIR}/preinstall"


# postinstall: 刷新图标缓存与 LaunchServices
cat > "${SCRIPTS_DIR}/postinstall" << 'POSTINSTALL'
#!/bin/bash
APP="/Applications/__APP_NAME__.app"
ALT_APP="/Applications/__APP_NAME__.localized/__APP_NAME__.app"
ALT_DIR="/Applications/__APP_NAME__.localized"
OLD_BUNDLE_ID="__OLD_BUNDLE_ID__"
APP_BUNDLE_ID="__APP_BUNDLE_ID__"

# 如果应用被错误安装到 .localized 目录，修正回 /Applications
if [ -d "${ALT_APP}" ]; then
    rm -f "${APP}" 2>/dev/null || true
    mv "${ALT_APP}" "${APP}" 2>/dev/null || true
    rm -rf "${ALT_DIR}" 2>/dev/null || true
fi

# 去除隔离标记
xattr -cr "${APP}" 2>/dev/null || true

# 清理可能残留的自定义图标文件与 FinderInfo（改为完全依赖 Info.plist/Assets）
ICON_R="${APP}/$(printf 'Icon\r')"
chflags nohidden "${ICON_R}" 2>/dev/null || true
rm -f "${ICON_R}" 2>/dev/null || true
xattr -d com.apple.FinderInfo "${APP}" 2>/dev/null || true

# 清理 iconservices 缓存（系统 + 所有用户）
rm -rf /Library/Caches/com.apple.iconservices.store 2>/dev/null || true
for user_dir in /Users/*; do
    [ -d "${user_dir}/Library/Caches" ] || continue
    rm -rf "${user_dir}/Library/Caches/com.apple.iconservices.store" 2>/dev/null || true
done
find /var/folders -name "com.apple.iconservices.store" -print0 2>/dev/null | xargs -0 rm -rf 2>/dev/null || true

# 清理 LaunchOS 图标缓存（避免第三方启动器不刷新）
for user_dir in /Users/*; do
    [ -d "${user_dir}" ] || continue
    rm -rf "${user_dir}/Library/Caches/app.remixdesign.LaunchOS" 2>/dev/null || true
    rm -rf "${user_dir}/Library/Application Support/LaunchOS/Cache" 2>/dev/null || true
done
killall "LaunchOS" 2>/dev/null || true

# 迁移旧 bundle id 的沙盒数据（如存在）
if [ "${OLD_BUNDLE_ID}" != "${APP_BUNDLE_ID}" ]; then
    for user_dir in /Users/*; do
        [ -d "${user_dir}" ] || continue
        old_container="${user_dir}/Library/Containers/${OLD_BUNDLE_ID}"
        new_container="${user_dir}/Library/Containers/${APP_BUNDLE_ID}"
        if [ -d "${old_container}" ] && [ ! -d "${new_container}" ]; then
            mv "${old_container}" "${new_container}" 2>/dev/null || true
        fi
        old_prefs="${user_dir}/Library/Preferences/${OLD_BUNDLE_ID}.plist"
        new_prefs="${user_dir}/Library/Preferences/${APP_BUNDLE_ID}.plist"
        if [ -f "${old_prefs}" ] && [ ! -f "${new_prefs}" ]; then
            mv "${old_prefs}" "${new_prefs}" 2>/dev/null || true
        fi
    done
fi

# 触发 macOS 重新读取应用信息（仅在 app 目录存在时）
if [ -d "${APP}" ]; then
    touch "${APP}" 2>/dev/null || true
fi

# 不再写入自定义图标（Icon\r/自定义 FinderInfo）

# 刷新 LaunchServices 数据库
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "${APP}" 2>/dev/null || true

# 注销同 bundle id 的其他副本（避免图标命中旧缓存）
mdfind "kMDItemCFBundleIdentifier == '${APP_BUNDLE_ID}'" 2>/dev/null | while IFS= read -r p; do
    [ "${p}" = "${APP}" ] && continue
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "${p}" 2>/dev/null || true
done
if [ "${OLD_BUNDLE_ID}" != "${APP_BUNDLE_ID}" ]; then
    mdfind "kMDItemCFBundleIdentifier == '${OLD_BUNDLE_ID}'" 2>/dev/null | while IFS= read -r p; do
        /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "${p}" 2>/dev/null || true
    done
fi

# 重启 iconservices / Dock / Finder 刷新图标
killall -9 iconservicesd 2>/dev/null || true
killall -9 iconservicesagent 2>/dev/null || true
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true

exit 0
POSTINSTALL
perl -pi -e "s/__APP_NAME__/${APP_NAME}/g; s/__APP_BUNDLE_ID__/${APP_BUNDLE_ID}/g; s/__OLD_BUNDLE_ID__/${OLD_BUNDLE_ID}/g" "${SCRIPTS_DIR}/postinstall"
chmod +x "${SCRIPTS_DIR}/postinstall"


# 构建 PKG
echo "[6/6] 构建 PKG 安装包..."
COMPONENT_PKG="${BUILD_DIR}/component.pkg"

pkgbuild \
    --root "${PKG_ROOT}" \
    --identifier "${PKG_BUNDLE_ID}" \
    --version "${VERSION}" \
    --install-location "/" \
    --scripts "${SCRIPTS_DIR}" \
    "${COMPONENT_PKG}"

cat > "${BUILD_DIR}/distribution.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>${APP_NAME}</title>
    <welcome file="welcome.html" mime-type="text/html"/>
    <options customize="never" require-scripts="false" hostArchitectures="x86_64,arm64"/>
    <choices-outline>
        <line choice="default"/>
    </choices-outline>
    <choice id="default" title="${APP_NAME}">
        <pkg-ref id="${PKG_BUNDLE_ID}"/>
    </choice>
    <pkg-ref id="${PKG_BUNDLE_ID}" version="${VERSION}" onConclusion="none">component.pkg</pkg-ref>
</installer-gui-script>
EOF

cat > "${BUILD_DIR}/welcome.html" << EOF
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="font-family: -apple-system, sans-serif; padding: 20px;">
<h2>时薪计算器 - 亿声永势 V3</h2>
<p>版本 ${VERSION}</p>
<p>为音频制作人设计的专业时薪计算工具。</p>
<ul>
<li>自动获取音频文件时长</li>
<li>支持时薪和分钟费率计算</li>
<li>手动输入工作时间</li>
<li>团队项目结算管理</li>
</ul>
<p style="color: #666; font-size: 12px;">安装时会自动替换旧版本。</p>
<p style="color: #666; font-size: 12px;">点击"继续"开始安装。</p>
</body>
</html>
EOF

productbuild \
    --distribution "${BUILD_DIR}/distribution.xml" \
    --resources "${BUILD_DIR}" \
    --package-path "${BUILD_DIR}" \
    "${OUTPUT_PKG}"

rm -rf "${BUILD_DIR}"

echo ""
echo "=== 构建完成 ==="
echo "安装包: ${OUTPUT_PKG}"
echo "大小: $(du -sh "${OUTPUT_PKG}" | cut -f1)"
echo ""
echo "双击 PKG 文件即可安装到 /Applications"
