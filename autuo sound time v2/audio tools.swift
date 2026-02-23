//
//  AudioTools.swift
//  AutoSoundTimeV2
//
//  Created by 陆玉缘 on 2025/7/5.
//

import Foundation
import SwiftUI
import AVFoundation
import AppKit
import UniformTypeIdentifiers

// MARK: - 自定义按钮样式（靛蓝/紫色渐变主题）
struct RoundedBorderedButtonStyle: ButtonStyle {
    // 圆角半径
    var cornerRadius: CGFloat = 12
    // 按下时的缩放比例
    var pressedScale: CGFloat = 0.96
    // 按下时的透明度
    var pressedOpacity: Double = 0.9
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.indigo, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.indigo.opacity(0.08))
                    )
            )
            .foregroundColor(.indigo)
            // 添加微妙阴影增加层次感
            .shadow(color: .indigo.opacity(0.15), radius: 4, y: 2)
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct RoundedBorderedProminentButtonStyle: ButtonStyle {
    // 圆角半径
    var cornerRadius: CGFloat = 12
    // 按下时的缩放比例
    var pressedScale: CGFloat = 0.96
    // 按下时的透明度
    var pressedOpacity: Double = 0.9
    // 背景色（保留兼容性但默认使用渐变）
    var backgroundColor: Color = .indigo
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                // 使用靛蓝到紫色的渐变背景
                LinearGradient(
                    colors: [.indigo, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            )
            .foregroundColor(.white)
            // 渐变阴影增强立体感
            .shadow(color: .indigo.opacity(0.3), radius: 6, y: 3)
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// 侧边栏按钮样式（带选中指示条）
struct SidebarButtonStyle: ButtonStyle {
    var isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(12)
            .background(isSelected ? Color.indigo.opacity(0.08) : Color.clear)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - TimeInterval 扩展（全局作用域，格式化时长显示）
extension TimeInterval {
    var fullFormattedDuration: String {
        let seconds = Int(self)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secondsRemaining = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secondsRemaining)
    }
}

// MARK: - 全局枚举定义
enum CalculationMethod: String, CaseIterable, Hashable, Codable {
    case hourly = "时薪计算"
    case minute = "分钟计算"
    case manual = "手动输入金额"
}

enum DurationUnit: String, CaseIterable, Hashable {
    case hour = "小时"
    case minute = "分钟"
}

// MARK: - 智能时间输入解析器（共享工具，消除手动模式和团队结算的重复逻辑）
struct SmartTimeParser {
    /// 解析智能输入字符串，返回 (hours, minutes, seconds) 字符串元组
    static func parse(_ input: String, isHourMode: Bool) -> (hours: String, minutes: String, seconds: String) {
        let digits = input.filter { "0123456789".contains($0) }
        
        guard !digits.isEmpty else {
            return ("", "", "")
        }
        
        var h = "", m = "", s = ""
        
        switch digits.count {
        case 1, 2:
            // 1-2位数字视为秒数
            s = digits
            m = "0"
            h = "0"
        case 3:
            // 3位数字：第1位为分钟，后2位为秒
            let idx = digits.index(digits.startIndex, offsetBy: 1)
            m = String(digits[..<idx])
            s = String(digits[idx...])
            h = "0"
        case 4:
            // 4位数字：前2位为分钟，后2位为秒
            let idx = digits.index(digits.startIndex, offsetBy: 2)
            m = String(digits[..<idx])
            s = String(digits[idx...])
            h = "0"
        case 5:
            // 5位数字：第1位为小时，中间2位为分钟，后2位为秒
            let hIdx = digits.index(digits.startIndex, offsetBy: 1)
            let mIdx = digits.index(hIdx, offsetBy: 2)
            h = String(digits[..<hIdx])
            m = String(digits[hIdx..<mIdx])
            s = String(digits[mIdx...])
        default:
            // 6位及以上：后4位为分秒，前面全部为小时
            let hIdx = digits.index(digits.startIndex, offsetBy: digits.count - 4)
            let mIdx = digits.index(hIdx, offsetBy: 2)
            h = String(digits[..<hIdx])
            m = String(digits[hIdx..<mIdx])
            s = String(digits[mIdx...])
        }
        
        return (h, m, s)
    }
    
    /// 格式化预览时间字符串
    static func formatPreview(hours: String, minutes: String, seconds: String, isHourMode: Bool) -> String {
        let h = Int(hours) ?? 0
        let m = Int(minutes) ?? 0
        let s = Int(seconds) ?? 0
        
        if isHourMode {
            return "\(h)小时 \(m)分钟 \(s)秒"
        } else {
            // 分钟模式下将小时折算为分钟
            let totalMinutes = m + (h * 60)
            return "\(totalMinutes)分钟 \(s)秒"
        }
    }
}

// MARK: - 数据模型和工具
// 标记为 @MainActor 确保 Swift 6 严格并发安全
@MainActor
class AudioFileModel: Identifiable, ObservableObject {
    let id = UUID()
    let url: URL
    let fileName: String
    let fileSize: UInt64
    @Published var duration: TimeInterval = 0
    @Published var isProcessed = false
    
    init(url: URL) {
        self.url = url
        self.fileName = url.lastPathComponent
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            self.fileSize = attributes[.size] as? UInt64 ?? 0
        } catch {
            self.fileSize = 0
        }
    }
    
    var durationString: String {
        duration.fullFormattedDuration
    }
    
    var sizeString: String {
        ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
    }
    
    // nonisolated 允许从非主线程调用，内部通过 MainActor.run 更新 UI 属性
    nonisolated func loadDuration() async {
        let asset = AVURLAsset(url: url)
        do {
            let durationInSeconds = try await asset.load(.duration).seconds
            await MainActor.run {
                duration = durationInSeconds
                isProcessed = true
            }
        } catch {
            await MainActor.run {
                duration = 0
                isProcessed = false
            }
        }
    }
}

// 手动模式的时间条目模型
struct TimeEntryModel: Identifiable {
    let id = UUID()
    let hours: Double
    let minutes: Double
    let seconds: Double
    let unit: DurationUnit
    let rate: Double
    let salary: Double
    let totalSeconds: TimeInterval
    
    var formattedTime: String {
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", Int(hours), Int(minutes), Int(seconds))
        } else {
            return String(format: "%02d:%02d", Int(minutes), Int(seconds))
        }
    }
}

// 团队结算条目模型（支持 Codable 持久化存储）
struct SettlementEntry: Identifiable, Codable {
    let id: UUID
    let cid: UUID
    let projectName: String
    let producer: String
    let date: Date
    let duration: TimeInterval
    let amount: Double
    let calculationMethod: CalculationMethod
    
    // 默认初始化器，自动生成 UUID
    init(id: UUID = UUID(), cid: UUID = UUID(), projectName: String, producer: String, date: Date, duration: TimeInterval, amount: Double, calculationMethod: CalculationMethod) {
        self.id = id
        self.cid = cid
        self.projectName = projectName
        self.producer = producer
        self.date = date
        self.duration = duration
        self.amount = amount
        self.calculationMethod = calculationMethod
    }
    
    // 格式化日期（计算属性，不参与 Codable 编解码）
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - 应用设置（持久化存储）
class AppSettings: ObservableObject {
    @AppStorage("showAutoMode") var showAutoMode = true
    @AppStorage("showManualMode") var showManualMode = true
    @AppStorage("showTeamMode") var showTeamMode = true
    @AppStorage("selectedTab") var selectedTab: String = "auto"
    @AppStorage("enableSmartInput") var enableSmartInput = true
    @AppStorage("showDurationInSeconds") var showDurationInSeconds = true
    // 费率记忆：保存上次使用的费率
    @AppStorage("lastHourlyRate") var lastHourlyRate: String = ""
    @AppStorage("lastMinuteRate") var lastMinuteRate: String = ""
}

// MARK: - 共享应用状态（支持 JSON 持久化到 UserDefaults）
class AppState: ObservableObject {
    @Published var teamSettlementEntries: [SettlementEntry] = [] {
        didSet {
            // 仅在初始化完成后才保存，避免 loadEntries 触发多余写入
            if isLoaded { saveEntries() }
        }
    }
    @Published var showSettingsView = false
    @Published var showAboutView = false
    
    private let entriesKey = "teamSettlementEntries"
    private var isLoaded = false
    
    init() {
        loadEntries()
        isLoaded = true
    }
    
    // 将结算条目序列化为 JSON 并存入 UserDefaults
    private func saveEntries() {
        if let data = try? JSONEncoder().encode(teamSettlementEntries) {
            UserDefaults.standard.set(data, forKey: entriesKey)
        }
    }
    
    // 从 UserDefaults 读取并反序列化结算条目
    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let entries = try? JSONDecoder().decode([SettlementEntry].self, from: data) {
            teamSettlementEntries = entries
        }
    }
}

// MARK: - 主应用入口
@main
struct AudioDurationCalculatorApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var appSettings = AppSettings()
    
    var body: some Scene {
        WindowGroup {
            MainContentView()
                .environmentObject(appState)
                .environmentObject(appSettings)
                .sheet(isPresented: $appState.showSettingsView) {
                    SettingsView()
                        .environmentObject(appState)
                        .environmentObject(appSettings)
                }
                .sheet(isPresented: $appState.showAboutView) {
                    AboutView()
                }
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(after: .appInfo) {
                Divider()
                
                Button("设置") {
                    appState.showSettingsView = true
                }
                .keyboardShortcut(",", modifiers: [.command])
                
                Button("关于") {
                    appState.showAboutView = true
                }
            }
            
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .undoRedo) { }
            
            // 全局快捷键绑定
            CommandGroup(before: .windowArrangement) {
                Button("自动模式") {
                    appSettings.selectedTab = "auto"
                }
                .keyboardShortcut("1", modifiers: [.command])
                
                Button("手动模式") {
                    appSettings.selectedTab = "manual"
                }
                .keyboardShortcut("2", modifiers: [.command])
                
                Button("团队模式") {
                    appSettings.selectedTab = "team"
                }
                .keyboardShortcut("3", modifiers: [.command])
                
                Divider()
                
                Button("添加文件") {
                    if appSettings.selectedTab == "auto" {
                        NotificationCenter.default.post(name: .addFilesNotification, object: nil)
                    }
                }
                .keyboardShortcut("o", modifiers: [.command])
                
                Button("计算时长") {
                    if appSettings.selectedTab == "auto" {
                        NotificationCenter.default.post(name: .calculateDurationsNotification, object: nil)
                    }
                }
                .keyboardShortcut("c", modifiers: [.command])
            }
        }
    }
}

// 通知名称扩展
extension Notification.Name {
    static let addFilesNotification = Notification.Name("AddFilesNotification")
    static let calculateDurationsNotification = Notification.Name("CalculateDurationsNotification")
}

// MARK: - 设置视图（卡片式分组 + 开关样式优化）
struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var appSettings: AppSettings
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 手动标题栏，替代 NavigationView 的 toolbar
            HStack {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(RoundedBorderedButtonStyle())
                
                Spacer()
                
                Text("应用设置")
                    .font(.headline)
                
                Spacer()
                
                Button("完成") {
                    dismiss()
                }
                .buttonStyle(RoundedBorderedProminentButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 界面设置卡片
                    settingsCard(title: "界面设置", icon: "rectangle.3.group") {
                        VStack(spacing: 12) {
                            settingsToggle("显示自动模式", isOn: $appSettings.showAutoMode)
                            Divider()
                            settingsToggle("显示手动模式", isOn: $appSettings.showManualMode)
                            Divider()
                            settingsToggle("显示团队模式", isOn: $appSettings.showTeamMode)
                        }
                    }
                    
                    // 智能输入设置卡片
                    settingsCard(title: "智能输入设置", icon: "lightbulb.fill") {
                        VStack(spacing: 12) {
                            settingsToggle("启用智能输入", isOn: $appSettings.enableSmartInput)
                            Text("启用后，输入连续数字会自动转换为分钟和秒")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Divider()
                            
                            settingsToggle("显示秒数", isOn: $appSettings.showDurationInSeconds)
                            Text("在手动输入时显示秒数字段")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // 高级选项卡片
                    settingsCard(title: "高级选项", icon: "gearshape.2") {
                        VStack(spacing: 12) {
                            Button("亿声永势工具集") {
                                if let url = URL(string: "https://yh.ysys.chat/") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .buttonStyle(RoundedBorderedButtonStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // 重置按钮
                    Button("重置所有设置") {
                        resetSettings()
                    }
                    .buttonStyle(RoundedBorderedButtonStyle())
                }
                .padding(20)
            }
        }
        .frame(width: 420)
    }
    
    // 设置卡片容器
    private func settingsCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(
                    LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
                )
            
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
    
    // 统一的开关样式
    private func settingsToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .toggleStyle(.switch)
            .tint(.indigo)
    }
    
    private func resetSettings() {
        appSettings.showAutoMode = true
        appSettings.showManualMode = true
        appSettings.showTeamMode = true
        appSettings.selectedTab = "auto"
        appSettings.enableSmartInput = true
        appSettings.showDurationInSeconds = true
    }
}

// MARK: - 关于视图（紧凑排版 + 渐变背景 + SF Symbol 图标列表）
struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 右上角关闭按钮
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            
            VStack(spacing: 12) {
                // 应用图标带渐变背景圆
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [.indigo.opacity(0.2), .purple.opacity(0.15)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                        .resizable()
                        .frame(width: 76, height: 76)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                
                // 应用名称渐变文字
                Text("时薪计算器")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                
                Text("版本 3.3.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("为音频制作人设计的专业工具")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider()
                    .padding(.vertical, 4)
                
                // 功能列表使用 SF Symbol 图标
                VStack(alignment: .leading, spacing: 7) {
                    Text("功能特点")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                    
                    featureRow(icon: "waveform.circle.fill", text: "自动计算多个音频文件的总时长", color: .indigo)
                    featureRow(icon: "dollarsign.circle.fill", text: "支持时薪和分钟费率计算", color: .green)
                    featureRow(icon: "hand.tap.fill", text: "手动输入工作时间计算薪资", color: .orange)
                    featureRow(icon: "person.3.fill", text: "团队项目结算管理", color: .purple)
                    featureRow(icon: "lightbulb.fill", text: "智能时间输入功能", color: .yellow)
                    featureRow(icon: "square.and.arrow.down", text: "CSV 导出团队结算数据", color: .blue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                
                Divider()
                    .padding(.vertical, 4)
                
                // 版权信息自动计算年份
                Text("© \(Calendar.current.component(.year, from: Date())) 亿声永势工作室")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("访问官网") {
                    if let url = URL(string: "https://yh.ysys.chat/") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(RoundedBorderedButtonStyle())
                .padding(.top, 2)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .frame(width: 380)
    }
    
    // 功能行组件
    private func featureRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
                .font(.system(size: 13))
            Text(text)
                .font(.caption)
        }
    }
}


// MARK: - 主视图（侧边栏 + 内容区域）
struct MainContentView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var appSettings: AppSettings
    
    @State private var sidebarCollapsed = false
    @State private var triggerCalculation = false
    // 侧边栏悬停状态
    @State private var hoveredTab: Tab? = nil
    
    enum Tab: String, CaseIterable {
        case auto
        case manual
        case team
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧边栏
            if !sidebarCollapsed {
                sidebar
                    .frame(width: 210)
                    .transition(.move(edge: .leading))
                    .animation(.easeInOut, value: sidebarCollapsed)
            }
            
            // 主内容区域
            VStack(spacing: 0) {
                // 顶部控制栏
                HStack {
                    // 侧边栏切换按钮
                    Button(action: {
                        withAnimation {
                            sidebarCollapsed.toggle()
                        }
                    }) {
                        Image(systemName: sidebarCollapsed ? "sidebar.right" : "sidebar.left")
                            .font(.system(size: 16, weight: .bold))
                            .padding(8)
                            .background(Color.indigo.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 10)
                    
                    Spacer()
                    
                    // 设置按钮
                    Button(action: {
                        appState.showSettingsView = true
                    }) {
                        Image(systemName: "gearshape")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 10)
                }
                .frame(height: 40)
                
                // 内容区域根据选中标签切换
                Group {
                    switch appSettings.selectedTab {
                    case Tab.auto.rawValue:
                        AutoModeCalculatorView(triggerCalculation: $triggerCalculation)
                    case Tab.manual.rawValue:
                        ManualModeCalculatorView()
                    case Tab.team.rawValue:
                        TeamSettlementView()
                    default:
                        AutoModeCalculatorView(triggerCalculation: $triggerCalculation)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(appSettings.selectedTab)
            }
        }
        .frame(minWidth: 850, minHeight: 600)
        .onOpenURL { url in
            handleURLScheme(url: url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .calculateDurationsNotification)) { _ in
            triggerCalculation = true
        }
    }
    
    // 侧边栏视图（渐变头部 + 选中指示条）
    private var sidebar: some View {
        VStack(spacing: 0) {
            // 侧边栏顶部渐变标题
            HStack(spacing: 8) {
                Image(systemName: "music.note.house.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(
                        LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                Text("音频工具")
                    .font(.headline)
                    .foregroundStyle(
                        LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.indigo.opacity(0.1), .purple.opacity(0.05)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            
            // 标签按钮列表
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        if shouldShowTab(tab) {
                            tabButton(tab: tab)
                                .padding(.horizontal, 8)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Spacer()
            
            // 底部版本信息
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("时薪计算器")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text("v3.3.0")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.bottom, 12)
        }
        .frame(maxHeight: .infinity)
        .background(Color(.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .trailing
        )
    }
    
    private func shouldShowTab(_ tab: Tab) -> Bool {
        switch tab {
        case .auto: return appSettings.showAutoMode
        case .manual: return appSettings.showManualMode
        case .team: return appSettings.showTeamMode
        }
    }
    
    // 侧边栏标签按钮（带选中指示条和悬停效果）
    private func tabButton(tab: Tab) -> some View {
        let title: String
        let systemImage: String
        
        switch tab {
        case .auto:
            title = "自动获取时长"
            systemImage = "waveform"
        case .manual:
            title = "手动计算薪资"
            systemImage = "hand.point.up.left.fill"
        case .team:
            title = "团队结算"
            systemImage = "person.3.fill"
        }
        
        let isSelected = appSettings.selectedTab == tab.rawValue
        let isHovered = hoveredTab == tab
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                appSettings.selectedTab = tab.rawValue
            }
        }) {
            HStack(spacing: 0) {
                // 选中时显示左侧指示条
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        isSelected
                        ? AnyShapeStyle(LinearGradient(colors: [.indigo, .purple], startPoint: .top, endPoint: .bottom))
                        : AnyShapeStyle(Color.clear)
                    )
                    .frame(width: 3, height: 20)
                    .padding(.trailing, 8)
                
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                    .frame(width: 24)
                    .foregroundColor(isSelected ? .indigo : .secondary)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .padding(.leading, 6)
                
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.trailing, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.indigo.opacity(0.08) : (isHovered ? Color.indigo.opacity(0.04) : Color.clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredTab = hovering ? tab : nil
            }
        }
    }
    
    // URL Scheme 处理
    private func handleURLScheme(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            return
        }
        
        for queryItem in queryItems {
            if queryItem.name == "files", let filesString = queryItem.value {
                let filePaths = filesString.split(separator: ",").map { String($0) }
                let urls = filePaths.compactMap { URL(string: $0) }
                
                appSettings.selectedTab = Tab.auto.rawValue
                
                NotificationCenter.default.post(name: .processFilesNotification, object: urls)
                break
            }
        }
    }
}

extension Notification.Name {
    static let processFilesNotification = Notification.Name("ProcessFilesNotification")
}


// MARK: - 自动模式视图（音频文件导入 + 时长计算）
struct AutoModeCalculatorView: View {
    @Binding var triggerCalculation: Bool
    
    @State private var audioFiles: [AudioFileModel] = []
    @State private var totalDuration: TimeInterval = 0
    @State private var isCalculating = false
    @State private var hourlyRate: String = ""
    @State private var minuteRate: String = ""
    @State private var calculatedSalary: Double = 0
    @State private var showProgress = false
    @State private var processedCount = 0
    @State private var selectedTimeUnit: DurationUnit = .minute
    @State private var showSettlementOptions = false
    @State private var projectName: String = ""
    @State private var producer: String = ""
    @State private var calculationStartDate = Date()
    @State private var showFileImporter = false
    @State private var showImportSuccess = false
    @State private var importedFileCount = 0
    @State private var showSettlementSuccess = false
    
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var appSettings: AppSettings
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerView
                
                if showProgress {
                    progressView
                }
                
                if showImportSuccess {
                    importSuccessView
                }
                
                // 团队结算成功横幅（靛蓝色调 + 左侧强调条）
                if showSettlementSuccess {
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.indigo)
                            .frame(width: 4)
                            .padding(.vertical, 4)
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.indigo)
                                .font(.title2)
                            
                            Text("已成功添加到团队结算")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Button {
                                showSettlementSuccess = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary.opacity(0.6))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                    .background(Color.indigo.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .indigo.opacity(0.1), radius: 3, y: 1)
                    .padding(.bottom, 6)
                    .transition(.opacity)
                    .animation(.easeInOut, value: showSettlementSuccess)
                }
                
                fileListSection
                
                controlButtons
                
                calculationSection
                
                settlementOptionsSection
                
                Spacer()
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .fileImporter(isPresented: $showFileImporter,
                      allowedContentTypes: [.audio, .folder],
                      allowsMultipleSelection: true) { result in
            handleFileSelection(result: result)
        }
        .onChange(of: triggerCalculation) {
            if (triggerCalculation){
                calculateDurations()
                triggerCalculation = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .addFilesNotification)) { _ in
            showFileImporter = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .processFilesNotification)) { notification in
            if let urls = notification.object as? [URL] {
                processFiles(urls: urls)
            }
        }
        // 从设置中恢复上次使用的费率
        .onAppear {
            if hourlyRate.isEmpty { hourlyRate = appSettings.lastHourlyRate }
            if minuteRate.isEmpty { minuteRate = appSettings.lastMinuteRate }
        }
    }
    
    // 头部视图（带装饰图标和渐变标题）
    private var headerView: some View {
        HStack(spacing: 16) {
            // 装饰图标带渐变背景圆
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.indigo.opacity(0.15), .purple.opacity(0.1)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 52, height: 52)
                
                Image(systemName: "waveform.badge.plus")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("自动获取音频时长")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                
                Text("拖放或导入音频文件，自动计算总时长和薪资 · 支持批量处理")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.bottom, 10)
    }
    
    // 进度视图（靛蓝色调 + 脉冲动画文字）
    private var progressView: some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(processedCount), total: Double(audioFiles.count))
                .progressViewStyle(.linear)
                .tint(.indigo)
                .frame(height: 8)
            
            HStack {
                Text("处理文件中...")
                    .font(.footnote)
                    .foregroundColor(.indigo)
                    .opacity(0.8)
                
                Spacer()
                
                Text("\(processedCount)/\(audioFiles.count)")
                    .font(.footnote.monospacedDigit())
                    .foregroundColor(.indigo)
                    .fontWeight(.medium)
            }
            
            if processedCount > 0 && processedCount < audioFiles.count {
                Text("大约剩余 \(estimatedRemainingTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .indigo.opacity(0.08), radius: 4, y: 2)
    }
    
    // 导入成功横幅（柔和绿色 + 左侧强调条）
    private var importSuccessView: some View {
        HStack(spacing: 0) {
            // 左侧绿色强调条
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.green)
                .frame(width: 4)
                .padding(.vertical, 4)
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("成功导入 \(importedFileCount) 个音频文件")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button {
                    showImportSuccess = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(Color.green.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .green.opacity(0.1), radius: 3, y: 1)
        .padding(.bottom, 6)
        .transition(.opacity)
        .animation(.easeInOut, value: showImportSuccess)
    }
    
    // 预估剩余时间
    private var estimatedRemainingTime: String {
        guard processedCount > 0 else { return "计算中..." }
        
        let elapsed = Date().timeIntervalSince(calculationStartDate)
        let perFileTime = elapsed / Double(processedCount)
        let remainingFiles = audioFiles.count - processedCount
        let remainingTime = TimeInterval(remainingFiles) * perFileTime
        
        if remainingTime < 60 {
            return "\(Int(remainingTime))秒"
        } else {
            return "\(Int(remainingTime/60))分钟"
        }
    }
    
    // 文件列表区域
    private var fileListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("音频文件列表")
                    .font(.headline)
                
                Spacer()
                
                Text("\(audioFiles.count) 个文件")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.indigo.opacity(0.08))
                    .clipShape(Capsule())
            }
            
            if audioFiles.isEmpty {
                emptyStateView
            } else {
                List {
                    Section(header:
                        HStack {
                            Text("文件")
                            Spacer()
                            Text("时长")
                                .frame(width: 80, alignment: .trailing)
                            Text("大小")
                                .frame(width: 80, alignment: .trailing)
                            Text("操作")
                                .frame(width: 60, alignment: .trailing)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ) {
                        ForEach(Array(audioFiles.enumerated()), id: \.element.id) { index, file in
                            HStack {
                                // 状态图标使用多色渲染
                                Image(systemName: file.isProcessed ?
                                      "waveform.circle.fill" : "exclamationmark.triangle.fill")
                                    .symbolRenderingMode(.multicolor)
                                    .foregroundColor(file.isProcessed ? .green : .orange)
                                
                                Text(file.fileName)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text(file.durationString)
                                    .monospacedDigit()
                                    .font(.subheadline)
                                    .frame(width: 80, alignment: .trailing)
                                
                                Text(file.sizeString)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(width: 80, alignment: .trailing)
                                
                                Button(action: {
                                    deleteAudioFile(id: file.id)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red.opacity(0.7))
                                }
                                .buttonStyle(.plain)
                                .frame(width: 60, alignment: .trailing)
                            }
                            .padding(.vertical, 6)
                            // 交替行背景色
                            .listRowBackground(index % 2 == 0 ? Color.clear : Color.indigo.opacity(0.02))
                        }
                    }
                }
                .listStyle(.plain)
                .frame(height: 250)
            }
        }
    }
    
    // 空状态视图（虚线边框 + 渐变图标）
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            // 图标带渐变背景圆
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.indigo.opacity(0.12), .purple.opacity(0.08)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
                    )
            }
            
            Text("拖放音频文件到这里")
                .font(.headline)
            
            Text("支持 MP3, WAV, AIFF, FLAC, M4A 等格式")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(Color.indigo.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        // 虚线边框
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                .foregroundColor(.indigo.opacity(0.3))
        )
        // 拖放处理
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            for provider in providers {
                provider.loadObject(ofClass: NSURL.self) { reading, error in
                    if let url = reading as? URL {
                        DispatchQueue.main.async {
                            self.processFiles(urls: [url])
                        }
                    }
                }
            }
            return true
        }
    }
    
    // 控制按钮行
    private var controlButtons: some View {
        HStack {
            Button(action: {
                showFileImporter = true
            }) {
                Label("添加文件", systemImage: "plus")
                    .frame(minWidth: 120)
            }
            .buttonStyle(RoundedBorderedButtonStyle())
            
            Button(action: calculateDurations) {
                Label("获取时长", systemImage: "timer")
                    .frame(minWidth: 120)
            }
            .buttonStyle(RoundedBorderedButtonStyle())
            .disabled(audioFiles.isEmpty || isCalculating)
            
            Button(action: clearFiles) {
                Label("清空列表", systemImage: "trash")
                    .frame(minWidth: 120)
            }
            .buttonStyle(RoundedBorderedButtonStyle())
            .disabled(audioFiles.isEmpty)
            
            Spacer()
        }
    }
    
    // 薪资计算区域（卡片式 + 渐变绿色薪资显示）
    private var calculationSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("薪资计算器")
                .font(.headline)
            
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("总时长")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(totalDuration.fullFormattedDuration)
                        .font(.title)
                        .monospacedDigit()
                        .frame(minWidth: 150, alignment: .leading)
                }
                
                // 分隔线
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 60)
                    .padding(.horizontal, 4)
                
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading) {
                        Text("计算单位")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $selectedTimeUnit) {
                            ForEach(DurationUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                    
                    HStack(alignment: .bottom, spacing: 15) {
                        VStack(alignment: .leading) {
                            Text("费率（元/\(selectedTimeUnit.rawValue))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("输入费率", text: selectedTimeUnit == .hour ? $hourlyRate : $minuteRate)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 120)
                        }
                        
                        Button(action: calculateSalary) {
                            Label("计算薪资", systemImage: "dollarsign.circle")
                                .frame(minWidth: 120)
                        }
                        .buttonStyle(RoundedBorderedProminentButtonStyle())
                        .tint(.indigo)
                        .disabled(totalDuration == 0)
                    }
                }
                
                // 分隔线
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 60)
                    .padding(.horizontal, 4)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("预估薪资")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("¥\(calculatedSalary, specifier: "%.2f")")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        )
                        .padding(.vertical, 5)
                        .frame(minWidth: 150, alignment: .leading)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }
    
    // 团队结算选项区域
    private var settlementOptionsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("团队结算选项")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        showSettlementOptions.toggle()
                    }
                }) {
                    Image(systemName: showSettlementOptions ? "chevron.up" : "chevron.down")
                        .foregroundColor(.indigo)
                }
            }
            
            if showSettlementOptions {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("项目名称")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("输入项目名称", text: $projectName)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 200)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("制作人")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("输入制作人", text: $producer)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 200)
                        }
                        
                        Button("添加到团队结算") {
                            addToTeamSettlement()
                        }
                        .buttonStyle(RoundedBorderedProminentButtonStyle())
                        .tint(.indigo)
                        .disabled(projectName.isEmpty || producer.isEmpty || totalDuration == 0)
                    }
                    
                    if !appState.teamSettlementEntries.isEmpty {
                        Text("已添加的结算条目")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 10)
                        
                        List(Array(appState.teamSettlementEntries.prefix(3))) { entry in
                            HStack {
                                Text(entry.projectName)
                                    .frame(width: 120, alignment: .leading)
                                
                                Text(entry.producer)
                                    .frame(width: 100, alignment: .leading)
                                
                                Text(entry.duration.fullFormattedDuration)
                                    .frame(width: 100, alignment: .leading)
                                
                                Text("¥\(entry.amount, specifier: "%.2f")")
                                    .frame(width: 100, alignment: .trailing)
                                    .foregroundColor(.green)
                            }
                        }
                        .frame(height: 100)
                        
                        if appState.teamSettlementEntries.count > 3 {
                            Text("还有 \(appState.teamSettlementEntries.count - 3) 条记录...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Spacer()
                            Button("查看全部") {
                                appSettings.selectedTab = "team"
                            }
                            .buttonStyle(RoundedBorderedButtonStyle())
                        }
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
            }
        }
    }
    
    // MARK: - 自动模式业务逻辑方法
    
    func handleFileSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                _ = url.startAccessingSecurityScopedResource()
            }
            
            processFiles(urls: urls)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                for url in urls {
                    url.stopAccessingSecurityScopedResource()
                }
            }
        case .failure(let error):
            print("文件导入错误: \(error.localizedDescription)")
        }
    }
    
    func processFiles(urls: [URL]) {
        var newFilesAdded = 0
        
        for url in urls {
            var isDirectory: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
            
            if isDirectory.boolValue {
                if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey]) {
                    for case let fileURL as URL in enumerator {
                        if isSupportedAudioFile(fileURL) {
                            addFile(url: fileURL)
                            newFilesAdded += 1
                        }
                    }
                }
            } else if isSupportedAudioFile(url) {
                addFile(url: url)
                newFilesAdded += 1
            }
        }
        
        if newFilesAdded > 0 {
            importedFileCount = newFilesAdded
            showImportSuccess = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showImportSuccess = false
                }
            }
            
            calculateDurations()
        }
    }
    
    private func addFile(url: URL) {
        guard !audioFiles.contains(where: { $0.url == url }) else { return }
        let file = AudioFileModel(url: url)
        audioFiles.append(file)
    }
    
    private func isSupportedAudioFile(_ url: URL) -> Bool {
        let supportedExtensions = ["mp3", "wav", "aiff", "flac", "m4a", "aac", "ogg"]
        return supportedExtensions.contains(url.pathExtension.lowercased())
    }
    
    func calculateDurations() {
        guard !audioFiles.isEmpty else { return }
        isCalculating = true
        showProgress = true
        processedCount = 0
        totalDuration = 0
        calculatedSalary = 0
        calculationStartDate = Date()
        
        let filesToProcess = audioFiles
        
        Task {
            var calculatedTotal: TimeInterval = 0
            var processedFiles = [AudioFileModel]()
            
            await withTaskGroup(of: (AudioFileModel, TimeInterval).self) { group in
                for file in filesToProcess {
                    group.addTask {
                        let processedFile = file
                        // 在主线程上读取 @MainActor 隔离的属性
                        let alreadyProcessed = await MainActor.run { file.isProcessed }
                        if !alreadyProcessed {
                            await processedFile.loadDuration()
                        }
                        let dur = await MainActor.run { processedFile.duration }
                        return (processedFile, dur)
                    }
                }
                
                for await (file, duration) in group {
                    calculatedTotal += duration
                    processedFiles.append(file)
                    
                    await MainActor.run {
                        processedCount += 1
                    }
                }
            }
            
            await MainActor.run {
                if self.audioFiles.count == filesToProcess.count {
                    self.audioFiles = processedFiles
                } else {
                    for (index, file) in self.audioFiles.enumerated() {
                        if let processedFile = processedFiles.first(where: { $0.id == file.id }) {
                            self.audioFiles[index] = processedFile
                        }
                    }
                }
                
                self.totalDuration = calculatedTotal
                self.calculateSalary()
                self.isCalculating = false
                self.showProgress = false
            }
        }
    }
    
    private func calculateSalary() {
        let rateString = selectedTimeUnit == .hour ? hourlyRate : minuteRate
        
        guard let rate = Double(rateString), rate > 0 else {
            calculatedSalary = 0
            return
        }
        
        if selectedTimeUnit == .hour {
            let hours = totalDuration / 3600
            calculatedSalary = hours * rate
            // 保存费率到设置，下次打开自动恢复
            appSettings.lastHourlyRate = hourlyRate
        } else {
            let minutes = totalDuration / 60
            calculatedSalary = minutes * rate
            // 保存费率到设置，下次打开自动恢复
            appSettings.lastMinuteRate = minuteRate
        }
    }
    
    private func clearFiles() {
        audioFiles.removeAll()
        totalDuration = 0
        calculatedSalary = 0
        showProgress = false
    }
    
    private func deleteAudioFile(id: UUID) {
        audioFiles.removeAll { $0.id == id }
        recalculateTotalDuration()
        calculateSalary()
    }
    
    private func recalculateTotalDuration() {
        totalDuration = audioFiles.reduce(0) { $0 + $1.duration }
    }
    
    private func addToTeamSettlement() {
        let method: CalculationMethod = selectedTimeUnit == .hour ? .hourly : .minute
        
        let entry = SettlementEntry(
            projectName: projectName,
            producer: producer,
            date: Date(),
            duration: totalDuration,
            amount: calculatedSalary,
            calculationMethod: method
        )
        
        appState.teamSettlementEntries.append(entry)
        projectName = ""
        producer = ""
        
        // 使用 SwiftUI 横幅替代 NSAlert，避免阻塞主线程
        showSettlementSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showSettlementSuccess = false
            }
        }
    }
}


// MARK: - 手动模式视图（手动输入时间 + 薪资计算）
struct ManualModeCalculatorView: View {
    @EnvironmentObject private var appSettings: AppSettings
    
    @State private var timeEntries: [TimeEntryModel] = []
    @State private var selectedUnit: DurationUnit = .minute
    @State private var hours: String = ""
    @State private var minutes: String = ""
    @State private var seconds: String = ""
    @State private var rate: String = ""
    @State private var totalSalary: Double = 0
    @State private var showAddEntrySheet = false
    @State private var smartInput: String = ""
    @State private var previewTime: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerView
                
                unitSelector
                
                entriesList
                
                calculationResult
                
                controlButtons
                
                Spacer()
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showAddEntrySheet) {
            addEntrySheet
        }
        // 从设置中恢复上次使用的费率
        .onAppear {
            if rate.isEmpty {
                rate = selectedUnit == .hour ? appSettings.lastHourlyRate : appSettings.lastMinuteRate
            }
        }
    }
    
    // 头部视图（带装饰图标和渐变标题）
    private var headerView: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.indigo.opacity(0.15), .purple.opacity(0.1)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 52, height: 52)
                
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("手动计算薪资")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                
                Text("为有声书或其他项目手动输入工作时长")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.bottom, 10)
    }
    
    // 时间单位选择器
    private var unitSelector: some View {
        VStack(alignment: .leading) {
            Text("时间单位")
                .font(.headline)
            
            Picker("时间单位", selection: $selectedUnit) {
                ForEach(DurationUnit.allCases, id: \.self) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 300)
        }
    }
    
    // 时间条目列表
    private var entriesList: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("时间条目")
                    .font(.headline)
                
                Spacer()
                
                Text("\(timeEntries.count) 个条目")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.indigo.opacity(0.08))
                    .clipShape(Capsule())
            }
            
            if timeEntries.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(timeEntries) { entry in
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.indigo)
                            
                            VStack(alignment: .leading) {
                                Text(entry.formattedTime)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text("费率: \(entry.rate, specifier: "%.2f")元/\(entry.unit.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("¥\(entry.salary, specifier: "%.2f")")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 8)
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteEntry(id: entry.id)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .frame(height: 200)
            }
        }
    }
    
    // 空状态视图（虚线边框 + 渐变图标）
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.indigo.opacity(0.12), .purple.opacity(0.08)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
                    )
            }
            
            Text("添加时间条目")
                .font(.headline)
            
            Text("点击下方按钮添加您的工作时间")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(Color.indigo.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                .foregroundColor(.indigo.opacity(0.3))
        )
    }
    
    // 计算结果卡片
    private var calculationResult: some View {
        VStack(alignment: .leading) {
            Text("计算结果")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("总薪资")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("¥\(totalSalary, specifier: "%.2f")")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        )
                }
                .frame(minWidth: 180)
                
                // 分隔线
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 50)
                    .padding(.horizontal, 8)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("总时长")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(totalDuration.fullFormattedDuration)
                        .font(.title)
                        .monospacedDigit()
                }
                .frame(minWidth: 150)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("条目数量")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(timeEntries.count)")
                        .font(.title)
                }
                .frame(minWidth: 100)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }
    
    // 控制按钮
    private var controlButtons: some View {
        HStack {
            Button(action: {
                showAddEntrySheet = true
            }) {
                Label("添加条目", systemImage: "plus")
                    .frame(minWidth: 120)
            }
            .buttonStyle(RoundedBorderedButtonStyle())
            
            Button(action: clearEntries) {
                Label("清空所有", systemImage: "trash")
                    .frame(minWidth: 120)
            }
            .buttonStyle(RoundedBorderedButtonStyle())
            .disabled(timeEntries.isEmpty)
            
            Spacer()
        }
    }
    
    // 添加条目弹窗
    private var addEntrySheet: some View {
        VStack(spacing: 0) {
            // 手动标题栏，替代 NavigationView 的 toolbar
            HStack {
                Button("取消") {
                    showAddEntrySheet = false
                    resetForm()
                }
                .buttonStyle(RoundedBorderedButtonStyle())
                
                Spacer()
                
                Text("添加时间条目")
                    .font(.headline)
                
                Spacer()
                
                // 占位，保持标题居中
                Button("取消") {}
                    .opacity(0)
                    .buttonStyle(RoundedBorderedButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            // 表单内容
            Form {
                Section(header: Text("时间输入")) {
                    if appSettings.enableSmartInput {
                        VStack(alignment: .leading, spacing: 15) {
                            Label("智能输入模式", systemImage: "lightbulb.fill")
                                .font(.headline)
                                .foregroundColor(.indigo)
                            
                            HStack {
                                TextField("输入时间 (如 112233)", text: $smartInput)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: smartInput) {
                                        processSmartInput(smartInput)
                                    }
                            }
                            
                            if !previewTime.isEmpty {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("解析结果:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text(previewTime)
                                        .font(.title3)
                                        .foregroundColor(.primary)
                                        .padding(10)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.indigo.opacity(0.08))
                                        .cornerRadius(8)
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("输入格式示例:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading) {
                                            Text("• 123 → 1分23秒")
                                            Text("• 1234 → 12分34秒")
                                        }
                                        VStack(alignment: .leading) {
                                            Text("• 112233 → 11:22:33")
                                            Text("• 123456 → 12:34:56")
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    } else {
                        HStack(spacing: 10) {
                            if selectedUnit == .hour {
                                VStack(alignment: .leading) {
                                    Text("小时")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("", text: $hours)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 60)
                                        .multilineTextAlignment(.center)
                                        .onChange(of: hours) {
                                            hours = hours.filter { "0123456789".contains($0) }
                                            updatePreviewTime()
                                        }
                                }
                            }
                            
                            VStack(alignment: .leading) {
                                Text("分钟")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                TextField("", text: $minutes)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)
                                    .multilineTextAlignment(.center)
                                    .onChange(of: minutes) {
                                        minutes = minutes.filter { "0123456789".contains($0) }
                                        updatePreviewTime()
                                    }
                            }
                            
                            VStack(alignment: .leading) {
                                Text("秒")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                TextField("", text: $seconds)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)
                                    .multilineTextAlignment(.center)
                                    .onChange(of: seconds) {
                                        seconds = seconds.filter { "0123456789".contains($0) }
                                        updatePreviewTime()
                                    }
                            }
                        }
                    }
                }
                
                Section(header: Text("费率设置")) {
                    TextField("费率（元/\(selectedUnit.rawValue))", text: $rate)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: rate) {
                            let filtered = rate.filter { "0123456789.".contains($0) }
                            if filtered.components(separatedBy: ".").count <= 2 {
                                rate = filtered
                            }
                        }
                }
                
                Section {
                    Button("添加条目") {
                        addEntry()
                    }
                    .buttonStyle(RoundedBorderedProminentButtonStyle())
                    .disabled(
                        appSettings.enableSmartInput ?
                        (smartInput.isEmpty || rate.isEmpty) :
                        ((selectedUnit == .hour && hours.isEmpty && minutes.isEmpty && seconds.isEmpty) ||
                         (selectedUnit == .minute && minutes.isEmpty && seconds.isEmpty) ||
                         rate.isEmpty)
                    )
                }
            }
            .padding()
        }
        .frame(minWidth: 450, minHeight: 500)
    }
    
    // 总时长计算属性
    private var totalDuration: TimeInterval {
        timeEntries.reduce(0) { total, entry in
            total + entry.totalSeconds
        }
    }
    
    // MARK: - 手动模式业务逻辑方法
    
    private func deleteEntry(id: UUID) {
        timeEntries.removeAll { $0.id == id }
        calculateTotalSalary()
    }
    
    private func clearEntries() {
        timeEntries.removeAll()
        totalSalary = 0
    }
    
    private func calculateTotalSalary() {
        totalSalary = timeEntries.reduce(0) { $0 + $1.salary }
    }
    
    private func resetForm() {
        hours = ""
        minutes = ""
        seconds = ""
        rate = ""
        smartInput = ""
        previewTime = ""
    }
    
    // 智能输入解析（使用共享解析器）
    private func processSmartInput(_ input: String) {
        let result = SmartTimeParser.parse(input, isHourMode: selectedUnit == .hour)
        hours = result.hours
        minutes = result.minutes
        seconds = result.seconds
        updatePreviewTime()
    }
    
    // 预览时间显示（使用共享格式化器）
    private func updatePreviewTime() {
        previewTime = SmartTimeParser.formatPreview(
            hours: hours, minutes: minutes, seconds: seconds,
            isHourMode: selectedUnit == .hour
        )
    }
    
    // 添加条目
    private func addEntry() {
        let hoursValue = Double(hours) ?? 0
        let minutesValue = Double(minutes) ?? 0
        let secondsValue = Double(seconds) ?? 0
        let totalSeconds = hoursValue * 3600 + minutesValue * 60 + secondsValue
        
        let valueInUnit: Double
        if selectedUnit == .hour {
            valueInUnit = totalSeconds / 3600
        } else {
            valueInUnit = totalSeconds / 60
        }
        
        guard let rateValue = Double(rate) else { return }
        let salary = valueInUnit * rateValue
        
        let entry = TimeEntryModel(
            hours: hoursValue,
            minutes: minutesValue,
            seconds: secondsValue,
            unit: selectedUnit,
            rate: rateValue,
            salary: salary,
            totalSeconds: totalSeconds
        )
        
        timeEntries.append(entry)
        calculateTotalSalary()
        
        // 保存费率到设置，下次打开自动恢复
        if selectedUnit == .hour {
            appSettings.lastHourlyRate = rate
        } else {
            appSettings.lastMinuteRate = rate
        }
        
        resetForm()
        showAddEntrySheet = false
    }
}


// MARK: - 团队结算视图（表格 + 汇总卡片）
struct TeamSettlementView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var appSettings: AppSettings
    
    @State private var uiState = UIState()
    @State private var showCopySuccess = false
    @State private var showDeleteConfirmation = false
    @State private var showExportSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerView
                
                HStack {
                    Button(action: {
                        uiState.showAddEntrySheet = true
                    }) {
                        Label("添加结算条目", systemImage: "plus")
                            .frame(minWidth: 150)
                    }
                    .buttonStyle(RoundedBorderedProminentButtonStyle())
                    .tint(.indigo)
                    
                    Button(action: copyToClipboard) {
                        Label("一键复制", systemImage: "doc.on.doc")
                            .frame(minWidth: 150)
                    }
                    .buttonStyle(RoundedBorderedButtonStyle())
                    .disabled(appState.teamSettlementEntries.isEmpty)
                    
                    Button(action: exportCSV) {
                        Label("导出 CSV", systemImage: "square.and.arrow.down")
                            .frame(minWidth: 150)
                    }
                    .buttonStyle(RoundedBorderedButtonStyle())
                    .disabled(appState.teamSettlementEntries.isEmpty)
                    
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Label("清空所有条目", systemImage: "trash")
                            .frame(minWidth: 150)
                    }
                    .buttonStyle(RoundedBorderedButtonStyle())
                    .disabled(appState.teamSettlementEntries.isEmpty)
                    
                    Spacer()
                }
                .padding(.bottom, 10)
                
                if appState.teamSettlementEntries.isEmpty {
                    emptyStateView
                } else {
                    entriesList
                    calculationSummary
                }
                
                Spacer()
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $uiState.showAddEntrySheet) {
            addEntrySheet
        }
        .alert("复制成功", isPresented: $showCopySuccess) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("团队结算信息已复制到剪贴板")
        }
        .alert("确认清空", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                clearAllEntries()
            }
        } message: {
            Text("确定要清空所有 \(appState.teamSettlementEntries.count) 条结算记录吗？此操作不可撤销。")
        }
        .alert("导出成功", isPresented: $showExportSuccess) {
            Button("确定", role: .cancel) { }
        } message: {
            Text("CSV 文件已成功保存")
        }
        // 从设置中恢复上次使用的费率
        .onAppear {
            if uiState.hourlyRate.isEmpty {
                uiState.hourlyRate = appSettings.lastHourlyRate
            }
        }
    }

    // 头部视图（带装饰图标和渐变标题）
    private var headerView: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.indigo.opacity(0.15), .purple.opacity(0.1)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 52, height: 52)
                
                Image(systemName: "person.3.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("团队结算管理")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                
                Text("管理团队项目结算，一键复制结算信息")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.bottom, 10)
    }
    
    // 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.indigo.opacity(0.12), .purple.opacity(0.08)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.3.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
                    )
            }
            
            Text("暂无结算条目")
                .font(.headline)
            
            Text("点击上方按钮添加结算条目")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .background(Color.indigo.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                .foregroundColor(.indigo.opacity(0.3))
        )
    }

    // 结算条目列表（表头靛蓝背景 + 交替行色）
    private var entriesList: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("结算条目")
                    .font(.headline)
                
                Spacer()
                
                Text("\(appState.teamSettlementEntries.count) 个条目")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.indigo.opacity(0.08))
                    .clipShape(Capsule())
            }
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    // 表头行
                    headerRow
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .background(Color.indigo.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    // 数据行
                    ForEach(Array(appState.teamSettlementEntries.enumerated()), id: \.element.id) { index, entry in
                        entryRow(entry: entry)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 8)
                            .background(index % 2 == 0 ? Color.clear : Color.indigo.opacity(0.02))
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteEntry(id: entry.id)
                                } label: {
                                    Label("删除条目", systemImage: "trash")
                                }
                            }
                        
                        // 行间分隔线
                        if index < appState.teamSettlementEntries.count - 1 {
                            Divider()
                                .padding(.horizontal, 8)
                        }
                    }
                }
            }
            .frame(height: 300)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // 表头行
    private var headerRow: some View {
        HStack {
            Text("CID").frame(width: 80, alignment: .leading)
            Text("日期").frame(width: 100, alignment: .leading)
            Text("项目名称").frame(width: 150, alignment: .leading)
            Text("制作人").frame(width: 100, alignment: .leading)
            Text("计算方式").frame(width: 100, alignment: .leading)
            Text("工作时长").frame(width: 100, alignment: .trailing)
            Text("应结金额").frame(width: 100, alignment: .trailing)
            Text("操作").frame(width: 60, alignment: .trailing)
        }
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundColor(.indigo.opacity(0.8))
    }

    // 数据行
    private func entryRow(entry: SettlementEntry) -> some View {
        HStack {
            Text(String(entry.cid.uuidString.prefix(8)))
                .font(.caption)
                .frame(width: 80, alignment: .leading)
            
            Text(entry.date, style: .date)
                .font(.caption)
                .frame(width: 100, alignment: .leading)
            
            Text(entry.projectName)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
            
            Text(entry.producer)
                .lineLimit(1)
                .frame(width: 100, alignment: .leading)
            
            Text(entry.calculationMethod.rawValue)
                .frame(width: 100, alignment: .leading)
            
            Text(entry.duration.fullFormattedDuration)
                .monospacedDigit()
                .frame(width: 100, alignment: .trailing)
            
            Text("¥\(entry.amount, specifier: "%.2f")")
                .foregroundColor(.green)
                .fontWeight(.medium)
                .frame(width: 100, alignment: .trailing)
            
            Button(action: {
                deleteEntry(id: entry.id)
            }) {
                Image(systemName: "trash")
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
            .frame(width: 60, alignment: .trailing)
        }
        .padding(.vertical, 5)
    }
    
    // 汇总卡片（渐变背景）
    private var calculationSummary: some View {
        VStack(alignment: .leading) {
            Text("结算汇总")
                .font(.headline)
                .padding(.top, 10)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("总金额")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("¥\(totalAmount, specifier: "%.2f")")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        )
                }
                .frame(width: 180)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("总时长")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(totalDuration.fullFormattedDuration)
                        .font(.title)
                        .monospacedDigit()
                }
                .frame(width: 180)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("条目数量")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(appState.teamSettlementEntries.count)")
                        .font(.title)
                }
                .frame(width: 120)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [.indigo.opacity(0.06), .purple.opacity(0.04)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .indigo.opacity(0.08), radius: 4, y: 2)
        }
    }

    // 计算属性
    private var totalDuration: TimeInterval {
        appState.teamSettlementEntries.reduce(0) { $0 + $1.duration }
    }
    
    private var totalAmount: Double {
        appState.teamSettlementEntries.reduce(0) { $0 + $1.amount }
    }
    
    // 添加结算条目弹窗
    private var addEntrySheet: some View {
        VStack(spacing: 0) {
            // 手动标题栏，替代 NavigationView 的 toolbar
            HStack {
                Button("取消") {
                    uiState.showAddEntrySheet = false
                    resetForm()
                }
                .buttonStyle(RoundedBorderedButtonStyle())
                
                Spacer()
                
                Text("添加结算条目")
                    .font(.headline)
                
                Spacer()
                
                // 占位，保持标题居中
                Button("取消") {}
                    .opacity(0)
                    .buttonStyle(RoundedBorderedButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            // 表单内容
            Form {
                Section(header: Text("项目信息")) {
                    TextField("项目名称", text: $uiState.projectName)
                    TextField("制作人", text: $uiState.producer)
                    DatePicker("日期", selection: $uiState.date, displayedComponents: .date)
                }
                
                Section(header: Text("计算方式")) {
                    Picker("计算方式", selection: $uiState.calculationMethod) {
                        ForEach(CalculationMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: uiState.calculationMethod) {
                        if appSettings.enableSmartInput && !uiState.smartInput.isEmpty {
                            processSmartInputForAll(with: uiState.smartInput)
                        } else {
                            updatePreviewTime()
                        }
                    }
                }
                
                if uiState.calculationMethod != .manual {
                    Section(header: Text("工作时长")) {
                        if appSettings.enableSmartInput {
                            VStack(alignment: .leading, spacing: 15) {
                                Label("智能输入模式", systemImage: "lightbulb.fill")
                                    .font(.headline)
                                    .foregroundColor(.indigo)
                                
                                HStack {
                                    TextField("输入时间 (如 112233)", text: $uiState.smartInput)
                                        .textFieldStyle(.roundedBorder)
                                        .onChange(of: uiState.smartInput) {
                                            processSmartInputForAll(with: uiState.smartInput)
                                        }
                                }
                                
                                if !uiState.previewTime.isEmpty {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text("解析结果:")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        Text(uiState.previewTime)
                                            .font(.title3)
                                            .foregroundColor(.primary)
                                            .padding(10)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.indigo.opacity(0.08))
                                            .cornerRadius(8)
                                    }
                                } else {
                                    Text("输入格式示例: 112233 → 11小时22分33秒")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            HStack(spacing: 10) {
                                if uiState.calculationMethod == .hourly {
                                    VStack(alignment: .leading) {
                                        Text("小时")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        TextField("", text: $uiState.durationHours)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 60)
                                            .multilineTextAlignment(.center)
                                            .onChange(of: uiState.durationHours) {
                                                updatePreviewTime()
                                            }
                                    }
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("分钟")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("", text: $uiState.durationMinutes)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 60)
                                        .multilineTextAlignment(.center)
                                        .onChange(of: uiState.durationMinutes) {
                                            updatePreviewTime()
                                        }
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("秒")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("", text: $uiState.durationSeconds)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 60)
                                        .multilineTextAlignment(.center)
                                        .onChange(of: uiState.durationSeconds) {
                                            updatePreviewTime()
                                        }
                                }
                            }
                        }
                    }
                }

                if uiState.calculationMethod != .manual {
                    Section(header: Text("费率设置")) {
                        if uiState.calculationMethod == .hourly {
                            TextField("时薪（元/小时）", text: $uiState.hourlyRate)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: uiState.hourlyRate) {
                                    let filtered = uiState.hourlyRate.filter { "0123456789.".contains($0) }
                                    if filtered.components(separatedBy: ".").count <= 2 {
                                        uiState.hourlyRate = filtered
                                    }
                                }
                        } else {
                            TextField("分钟费率（元/分钟）", text: $uiState.hourlyRate)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: uiState.hourlyRate) {
                                    let filtered = uiState.hourlyRate.filter { "0123456789.".contains($0) }
                                    if filtered.components(separatedBy: ".").count <= 2 {
                                        uiState.hourlyRate = filtered
                                    }
                                }
                        }
                    }
                }
                
                if uiState.calculationMethod == .manual {
                    Section(header: Text("结算金额")) {
                        TextField("金额", text: $uiState.amount)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: uiState.amount) {
                                let filtered = uiState.amount.filter { "0123456789.".contains($0) }
                                if filtered.components(separatedBy: ".").count <= 2 {
                                    uiState.amount = filtered
                                }
                            }
                    }
                }
                
                Section {
                    Button("添加条目") {
                        addSettlementEntry()
                    }
                    .buttonStyle(RoundedBorderedProminentButtonStyle())
                    .disabled(uiState.projectName.isEmpty || uiState.producer.isEmpty ||
                              (uiState.calculationMethod != .manual &&
                               (uiState.durationHours.isEmpty &&
                                uiState.durationMinutes.isEmpty &&
                                uiState.durationSeconds.isEmpty)) ||
                              (uiState.calculationMethod != .manual && uiState.hourlyRate.isEmpty) ||
                              (uiState.calculationMethod == .manual && uiState.amount.isEmpty))
                }
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 600)
    }

    // MARK: - 团队结算业务逻辑方法
    
    private func addSettlementEntry() {
        var entryAmount = 0.0
        var entryDuration = 0.0
        
        if uiState.calculationMethod != .manual {
            let hoursValue = Double(uiState.durationHours) ?? 0
            let minutesValue = Double(uiState.durationMinutes) ?? 0
            let secondsValue = Double(uiState.durationSeconds) ?? 0
            entryDuration = hoursValue * 3600 + minutesValue * 60 + secondsValue
            
            if let rateValue = Double(uiState.hourlyRate) {
                if uiState.calculationMethod == .hourly {
                    entryAmount = (entryDuration / 3600) * rateValue
                    // 保存时薪费率到设置
                    appSettings.lastHourlyRate = uiState.hourlyRate
                } else {
                    entryAmount = (entryDuration / 60) * rateValue
                    // 保存分钟费率到设置
                    appSettings.lastMinuteRate = uiState.hourlyRate
                }
            }
        } else {
            entryAmount = Double(uiState.amount) ?? 0
        }
        
        let entry = SettlementEntry(
            projectName: uiState.projectName,
            producer: uiState.producer,
            date: uiState.date,
            duration: entryDuration,
            amount: entryAmount,
            calculationMethod: uiState.calculationMethod
        )
        
        appState.teamSettlementEntries.append(entry)
        uiState.showAddEntrySheet = false
        resetForm()
    }
    
    private func deleteEntry(id: UUID) {
        appState.teamSettlementEntries.removeAll { $0.id == id }
    }
    
    private func clearAllEntries() {
        appState.teamSettlementEntries.removeAll()
    }
    
    // 导出 CSV 文件（NSSavePanel 选择保存位置）
    private func exportCSV() {
        let panel = NSSavePanel()
        panel.title = "导出团队结算 CSV"
        panel.nameFieldStringValue = "团队结算.csv"
        panel.allowedContentTypes = [UTType.commaSeparatedText]
        panel.canCreateDirectories = true
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            // 构建 CSV 内容，使用 BOM 确保 Excel 正确识别 UTF-8
            var csv = "\u{FEFF}"
            csv += "CID,项目名称,制作人,日期,计算方式,工作时长,应结金额\n"
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .none
            
            for entry in appState.teamSettlementEntries {
                let cid = String(entry.cid.uuidString.prefix(8))
                let dateString = dateFormatter.string(from: entry.date)
                // CSV 字段中的逗号和引号需要转义
                let projectName = entry.projectName.replacingOccurrences(of: "\"", with: "\"\"")
                let producer = entry.producer.replacingOccurrences(of: "\"", with: "\"\"")
                
                csv += "\(cid),\"\(projectName)\",\"\(producer)\",\(dateString),\(entry.calculationMethod.rawValue),\(entry.duration.fullFormattedDuration),¥\(String(format: "%.2f", entry.amount))\n"
            }
            
            // 追加汇总行
            csv += ",,,,,\(totalDuration.fullFormattedDuration),¥\(String(format: "%.2f", totalAmount))\n"
            
            do {
                try csv.write(to: url, atomically: true, encoding: .utf8)
                DispatchQueue.main.async {
                    showExportSuccess = true
                }
            } catch {
                print("CSV 导出失败: \(error.localizedDescription)")
            }
        }
    }
    
    private func resetForm() {
        uiState = UIState()
    }

    // 复制到剪贴板
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        var text = "项目名称\t制作人\t日期\t计算方式\t工作时长\t应结金额\n"
        
        for entry in appState.teamSettlementEntries {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .none
            let dateString = dateFormatter.string(from: entry.date)
            
            text += "\(entry.projectName)\t"
            text += "\(entry.producer)\t"
            text += "\(dateString)\t"
            text += "\(entry.calculationMethod.rawValue)\t"
            text += "\(entry.duration.fullFormattedDuration)\t"
            text += "¥\(String(format: "%.2f", entry.amount))\n"
        }
        
        text += "\n总计:\t\t\t\t"
        text += "\(totalDuration.fullFormattedDuration)\t"
        text += "¥\(String(format: "%.2f", totalAmount))"
        
        pasteboard.setString(text, forType: .string)
        showCopySuccess = true
    }

    // 智能输入解析（使用共享解析器，团队结算版本额外处理进位）
    private func processSmartInputForAll(with input: String) {
        let isHourMode = uiState.calculationMethod == .hourly
        let result = SmartTimeParser.parse(input, isHourMode: isHourMode)
        uiState.durationHours = result.hours
        uiState.durationMinutes = result.minutes
        uiState.durationSeconds = result.seconds
        
        // 输入为空时清除预览
        if input.filter({ "0123456789".contains($0) }).isEmpty {
            uiState.previewTime = ""
            return
        }
        
        processCarryOver()
        updatePreviewTime()
    }

    // 进位处理（秒→分→时）
    private func processCarryOver() {
        if let seconds = Int(uiState.durationSeconds), seconds >= 60 {
            let additionalMinutes = seconds / 60
            uiState.durationSeconds = String(format: "%02d", seconds % 60)
            
            if let currentMinutes = Int(uiState.durationMinutes) {
                uiState.durationMinutes = String(currentMinutes + additionalMinutes)
            } else {
                uiState.durationMinutes = String(additionalMinutes)
            }
        }
        
        if let minutes = Int(uiState.durationMinutes), minutes >= 60 {
            let additionalHours = minutes / 60
            uiState.durationMinutes = String(format: "%02d", minutes % 60)
            
            if let currentHours = Int(uiState.durationHours) {
                uiState.durationHours = String(currentHours + additionalHours)
            } else {
                uiState.durationHours = String(additionalHours)
            }
        }
    }
    
    // 预览时间更新
    private func updatePreviewTime() {
        let hoursValue = Int(uiState.durationHours) ?? 0
        let minutesValue = Int(uiState.durationMinutes) ?? 0
        let secondsValue = Int(uiState.durationSeconds) ?? 0
        let totalSeconds = hoursValue * 3600 + minutesValue * 60 + secondsValue
        
        switch uiState.calculationMethod {
        case .minute:
            let totalMinutes = totalSeconds / 60
            let remainingSeconds = totalSeconds % 60
            uiState.previewTime = "预览: \(totalMinutes)分钟 \(remainingSeconds)秒"
        case .hourly:
            let previewHours = totalSeconds / 3600
            let remainingSeconds = totalSeconds % 3600
            let previewMinutes = remainingSeconds / 60
            let previewSeconds = remainingSeconds % 60
            uiState.previewTime = "预览: \(previewHours)小时 \(previewMinutes)分钟 \(previewSeconds)秒"
        case .manual:
            uiState.previewTime = ""
        }
    }
}

// MARK: - UI状态模型（团队结算弹窗表单状态）
struct UIState {
    var showAddEntrySheet = false
    var calculationMethod: CalculationMethod = .hourly
    var projectName: String = ""
    var producer: String = ""
    var date: Date = Date()
    var durationHours: String = ""
    var durationMinutes: String = ""
    var durationSeconds: String = ""
    var amount: String = ""
    var hourlyRate: String = ""
    var smartInput: String = ""
    var previewTime: String = ""
}
