# 需求文档：跨平台音频素材管理软件

## 简介

一个跨平台桌面音频素材管理应用程序（支持 Windows 和 macOS），参考 Soundminer 的功能设计与交互风格。核心功能包括：音频素材的浏览、搜索、预览播放、元数据编辑，以及基于 UCS（Universal Category System）分类标准的素材分类管理。用户可以扫描本地磁盘上的音频文件建立素材库，通过 UCS 分类体系快速检索和组织素材，并在应用内实时预览音频波形与播放。

## 术语表

- **Asset_Manager**：素材管理软件主应用程序
- **Library_Scanner**：素材库扫描模块，负责扫描指定目录并索引音频文件
- **Metadata_Reader**：元数据读取模块，负责从音频文件中提取嵌入式元数据（BWF、iXML、ID3 等）
- **Metadata_Editor**：元数据编辑模块，负责将修改后的元数据写回音频文件
- **UCS_Engine**：UCS 分类引擎，负责基于 UCS 标准对素材进行分类、检索和过滤
- **Search_Engine**：搜索引擎，负责对素材库进行全文搜索和条件过滤
- **Audio_Player**：音频播放模块，负责素材的实时预览播放
- **Waveform_Renderer**：波形渲染模块，负责生成和显示音频波形图
- **Transfer_Manager**：素材传输模块，负责将素材复制或移动到目标位置
- **Database**：本地数据库，存储素材索引、元数据缓存和用户配置
- **UCS**：Universal Category System，音效行业通用分类标准，定义了 CatID、Category、SubCategory、CategoryFull 等层级分类字段
- **BWF**：Broadcast Wave Format，广播级 WAV 文件格式，包含 Description、Originator 等扩展元数据
- **iXML**：嵌入在音频文件中的 XML 元数据块，常用于专业音频工作流
- **Soundminer**：业界知名的音频素材管理软件，本项目的功能和交互参考对象
- **NAS_Connector**：NAS 连接模块，负责通过 SMB/AFP/NFS 协议连接网络附加存储设备，管理连接生命周期和状态监测
- **Cache_Manager**：缓存管理模块，负责管理从 NAS 下载到本地的元数据、波形数据和音频预览文件的缓存策略与存储空间
- **Playlist_Manager**：播放列表/收藏夹管理模块，负责创建、编辑、删除收藏夹/播放列表，以及管理收藏夹中的素材条目
- **History_Tracker**：历史记录追踪模块，负责记录用户最近播放的素材和最近搜索的关键词，并提供历史记录的查询和清除功能
- **Format_Converter**：音频格式转换模块，负责在素材传输过程中执行可选的音频格式、采样率和位深度转换
- **Tag_Manager**：自定义标签管理模块，负责创建、编辑、删除用户自定义标签，以及管理素材与标签的关联关系
- **Library_Exporter**：素材库导入导出模块，负责将素材库索引（元数据、分类、标签、收藏夹等）导出为可移植文件，以及从导出文件中导入恢复
- **Quick_Importer**：一键导入模块，负责通过拖拽或文件夹监控方式快速导入音频素材，自动完成元数据读取、波形缓存生成和 UCS 分类归入

## 需求

### 需求 1：跨平台桌面应用框架

**用户故事：** 作为音频工作者，我希望在 Windows 和 macOS 上使用同一款素材管理软件，以便在不同工作环境中保持一致的工作流程。

#### 验收标准

1. THE Asset_Manager SHALL 作为独立的跨平台桌面应用程序运行，支持 Windows 10+ 和 macOS 12+
2. WHEN 用户启动 Asset_Manager，THE Asset_Manager SHALL 在 5 秒内完成窗口加载并显示主界面
3. THE Asset_Manager SHALL 提供深色主题的图形用户界面，包含以下区域：顶部搜索栏、左侧分类导航面板、中部素材列表面板、底部音频预览与波形面板
4. THE Asset_Manager SHALL 支持窗口大小调整，各面板比例随窗口大小自适应
5. THE Asset_Manager SHALL 在退出时保存窗口位置、大小和面板布局状态，下次启动时恢复

### 需求 2：素材库扫描与索引

**用户故事：** 作为音频工作者，我希望将本地磁盘上的音频文件夹添加到素材库中，以便集中管理和检索所有音频素材。

#### 验收标准

1. WHEN 用户通过菜单或拖拽方式添加一个文件夹路径，THE Library_Scanner SHALL 递归扫描该文件夹下所有音频文件并建立索引
2. THE Library_Scanner SHALL 支持以下音频格式的索引：WAV、BWF、AIFF、MP3、FLAC、OGG、AAC、CAF
3. WHEN 扫描过程中发现新文件，THE Library_Scanner SHALL 调用 Metadata_Reader 提取元数据并存入 Database
4. WHEN 扫描过程中发现已索引文件的修改时间发生变化，THE Library_Scanner SHALL 重新读取该文件的元数据并更新 Database
5. WHEN 扫描过程中发现已索引文件不再存在于磁盘，THE Library_Scanner SHALL 将该文件在 Database 中标记为"离线"
6. THE Library_Scanner SHALL 在扫描过程中显示进度信息，包含已扫描文件数和当前扫描路径
7. THE Asset_Manager SHALL 支持管理多个素材库路径，用户可以添加、移除和重新扫描指定路径
8. WHILE Library_Scanner 正在执行扫描任务，THE Asset_Manager SHALL 保持界面响应，用户可以继续浏览和搜索已索引的素材

### 需求 3：音频元数据读取

**用户故事：** 作为音频工作者，我希望软件能自动读取音频文件中嵌入的元数据，以便查看素材的详细信息。

#### 验收标准

1. THE Metadata_Reader SHALL 从音频文件中读取以下基础属性：文件名、文件路径、文件大小、采样率、位深度、声道数、时长、音频格式
2. THE Metadata_Reader SHALL 从 WAV/BWF 文件中读取 BWF 扩展元数据：Description、Originator、OriginatorReference、OriginationDate、OriginationTime、TimeReference
3. THE Metadata_Reader SHALL 从音频文件中读取 iXML 元数据块（如存在）
4. THE Metadata_Reader SHALL 从音频文件中读取 UCS 相关元数据字段：CatID、Category、SubCategory、CategoryFull、FXName、CreatorID、SourceID、UserData
5. THE Metadata_Reader SHALL 从 MP3 文件中读取 ID3v2 标签，从 FLAC 文件中读取 Vorbis Comment
6. IF 某个元数据字段在音频文件中不存在，THEN THE Metadata_Reader SHALL 将该字段值设为空，不影响其他字段的读取

### 需求 4：UCS 分类体系

**用户故事：** 作为音效设计师，我希望素材按照 UCS 标准进行分类，以便使用行业通用的分类体系快速定位所需素材。

#### 验收标准

1. THE UCS_Engine SHALL 内置完整的 UCS 分类数据，包含所有标准 Category 和 SubCategory 定义
2. THE Asset_Manager SHALL 在左侧分类导航面板中以树形结构展示 UCS 分类层级：Category → SubCategory
3. WHEN 用户点击某个 UCS Category 节点，THE Asset_Manager SHALL 在素材列表面板中显示该分类下的所有素材（包含子分类）
4. WHEN 用户点击某个 UCS SubCategory 节点，THE Asset_Manager SHALL 在素材列表面板中仅显示该子分类下的素材
5. WHEN 音频文件的元数据中包含 CatID 字段，THE UCS_Engine SHALL 根据 CatID 自动将该素材归入对应的 UCS 分类
6. WHEN 音频文件的元数据中不包含 CatID 但包含 Category 和 SubCategory 文本字段，THE UCS_Engine SHALL 通过文本匹配将该素材归入对应的 UCS 分类
7. IF 音频文件的元数据中不包含任何 UCS 分类信息，THEN THE UCS_Engine SHALL 将该素材归入"未分类"节点
8. THE Asset_Manager SHALL 在每个分类节点旁显示该分类下的素材数量

### 需求 5：素材搜索与过滤

**用户故事：** 作为音频工作者，我希望通过关键词和条件快速搜索素材，以便在大量素材中高效找到所需文件。

#### 验收标准

1. WHEN 用户在搜索栏中输入关键词，THE Search_Engine SHALL 对素材的文件名、Description、FXName、Category、SubCategory、UserData 字段进行全文搜索，并在素材列表中显示匹配结果
2. THE Search_Engine SHALL 在用户停止输入 300 毫秒后自动执行搜索，无需手动点击搜索按钮
3. THE Search_Engine SHALL 支持以下过滤条件的组合：采样率、位深度、声道数、时长范围、文件格式、UCS Category、UCS SubCategory
4. WHEN 用户设置过滤条件，THE Search_Engine SHALL 将过滤条件与关键词搜索结果取交集后显示
5. THE Search_Engine SHALL 在搜索结果列表顶部显示匹配的素材总数
6. WHEN 素材库包含 100,000 条索引记录时，THE Search_Engine SHALL 在 500 毫秒内返回搜索结果

### 需求 6：素材列表展示

**用户故事：** 作为音频工作者，我希望素材列表以表格形式展示详细信息，并支持排序和列自定义，以便按需查看素材属性。

#### 验收标准

1. THE Asset_Manager SHALL 在素材列表面板中以表格形式展示素材，默认列包含：文件名、Duration、采样率、位深度、声道数、文件格式、Category、SubCategory、FXName、Description、来源、状态。其中"来源"列显示素材的存储来源（值为"本地"或 NAS 设备名称），"状态"列显示素材的可用状态（值为"在线"、"离线"或"缓存中"）
2. WHEN 用户点击表格列头，THE Asset_Manager SHALL 按该列进行升序或降序排序
3. THE Asset_Manager SHALL 支持用户通过右键列头菜单选择显示或隐藏特定列
4. THE Asset_Manager SHALL 支持用户拖拽调整列宽和列顺序
5. THE Asset_Manager SHALL 保存用户的列配置（显示/隐藏、宽度、顺序），下次启动时恢复
6. WHEN 素材列表包含大量记录时，THE Asset_Manager SHALL 使用虚拟滚动技术，仅渲染可视区域内的行，保持滚动流畅
7. THE Asset_Manager SHALL 在素材列表中通过图标或颜色标识区分素材的来源类型，本地素材和 NAS 素材使用不同的视觉标识
8. WHEN 素材状态为"离线"时，THE Asset_Manager SHALL 在该素材行使用半透明或灰色样式，直观提示用户该素材当前不可播放

### 需求 7：音频预览播放

**用户故事：** 作为音频工作者，我希望在素材列表中选中素材后能立即预览播放，以便快速试听素材内容。

#### 验收标准

1. WHEN 用户在素材列表中选中一条素材，THE Audio_Player SHALL 在底部预览面板中加载该素材并显示播放控件（播放/暂停、停止、音量调节、进度条）
2. WHEN 用户双击素材列表中的一条素材，THE Audio_Player SHALL 立即开始播放该素材
3. WHEN 用户按下空格键且素材列表有选中项，THE Audio_Player SHALL 切换播放/暂停状态
4. THE Audio_Player SHALL 支持从进度条任意位置开始播放（拖拽定位）
5. THE Audio_Player SHALL 在播放过程中实时显示当前播放时间和总时长
6. THE Audio_Player SHALL 支持播放 WAV、BWF、AIFF、MP3、FLAC、OGG、AAC、CAF 格式的音频文件
7. WHILE Audio_Player 正在播放一条素材，WHEN 用户选中另一条素材并触发播放，THE Audio_Player SHALL 停止当前播放并切换到新素材

### 需求 8：波形显示

**用户故事：** 作为音频工作者，我希望在预览面板中看到音频波形图，以便直观了解素材的动态特征和结构。

#### 验收标准

1. WHEN 用户选中一条素材，THE Waveform_Renderer SHALL 在底部预览面板中显示该素材的波形图
2. THE Waveform_Renderer SHALL 在 1 秒内完成波形图的生成和显示（针对 10 分钟以内的音频文件）
3. WHILE Audio_Player 正在播放，THE Waveform_Renderer SHALL 在波形图上显示一条随播放进度移动的播放位置指示线
4. WHEN 用户在波形图上点击某个位置，THE Audio_Player SHALL 跳转到该位置继续播放
5. THE Waveform_Renderer SHALL 支持多声道波形的分层显示（立体声显示左右声道）

### 需求 9：元数据编辑

**用户故事：** 作为音效设计师，我希望在软件中直接编辑素材的元数据并写回文件，以便维护素材的分类和描述信息。

#### 验收标准

1. WHEN 用户在素材列表中选中一条素材，THE Asset_Manager SHALL 在元数据面板中显示该素材的所有可编辑元数据字段
2. THE Metadata_Editor SHALL 支持编辑以下字段：Description、FXName、CatID、Category、SubCategory、CategoryFull、CreatorID、SourceID、UserData
3. WHEN 用户修改 CatID 字段，THE Metadata_Editor SHALL 自动填充对应的 Category、SubCategory、CategoryFull 字段
4. WHEN 用户点击"保存"按钮，THE Metadata_Editor SHALL 将修改后的元数据写回音频文件，并更新 Database 中的索引
5. THE Metadata_Editor SHALL 支持批量编辑：用户选中多条素材后，可以同时修改共同字段的值
6. IF 写入元数据时目标文件为只读或被其他程序锁定，THEN THE Metadata_Editor SHALL 显示错误提示，说明写入失败的原因和文件路径
7. WHEN 用户编辑 CatID 字段时，THE Metadata_Editor SHALL 提供 UCS CatID 的下拉自动补全列表

### 需求 10：素材传输（Spot/Transfer）

**用户故事：** 作为音频工作者，我希望将选中的素材快速复制到指定目标文件夹（如 DAW 项目的音频文件夹），以便将素材导入到当前工作项目中。

#### 验收标准

1. WHEN 用户选中一条或多条素材并执行"传输"操作，THE Transfer_Manager SHALL 将选中的素材文件复制到用户指定的目标文件夹
2. THE Asset_Manager SHALL 支持用户预设多个常用目标文件夹路径，通过快捷方式快速传输
3. THE Transfer_Manager SHALL 在传输过程中显示进度信息，包含已传输文件数和当前文件名
4. IF 目标文件夹中已存在同名文件，THEN THE Transfer_Manager SHALL 提示用户选择覆盖、跳过或重命名
5. THE Asset_Manager SHALL 支持通过拖拽将素材从素材列表拖放到操作系统文件管理器或 DAW 应用中

### 需求 11：用户偏好设置

**用户故事：** 作为音频工作者，我希望自定义软件的行为和外观，以便适配个人工作习惯。

#### 验收标准

1. THE Asset_Manager SHALL 提供设置界面，包含以下配置项：默认音频输出设备、素材库路径管理、传输目标文件夹管理、界面主题（深色/浅色）
2. WHEN 用户修改音频输出设备设置，THE Audio_Player SHALL 立即切换到新的输出设备
3. THE Asset_Manager SHALL 将所有用户偏好设置持久化存储到本地配置文件，下次启动时自动加载
4. THE Asset_Manager SHALL 支持键盘快捷键自定义，用户可以为常用操作绑定自定义快捷键

### 需求 12：数据库与性能

**用户故事：** 作为音频工作者，我希望软件能高效管理大量素材索引，以便在拥有数十万条素材的库中流畅操作。

#### 验收标准

1. THE Database SHALL 使用嵌入式数据库（如 SQLite）存储素材索引和元数据缓存，无需用户安装额外数据库服务
2. THE Database SHALL 对文件名、Description、FXName、Category、SubCategory 字段建立全文搜索索引
3. WHEN 素材库包含 500,000 条索引记录时，THE Asset_Manager SHALL 保持搜索响应时间在 1 秒以内
4. THE Database SHALL 支持增量更新，仅处理新增或变更的文件，避免全量重建索引
5. IF Database 文件损坏，THEN THE Asset_Manager SHALL 提示用户重建索引，并通过重新扫描素材库路径恢复数据

### 需求 13：NAS 网络存储连接与缓存

**用户故事：** 作为音频工作者，我希望将 NAS 上的音频素材纳入素材库管理，并通过智能缓存机制保证浏览和播放体验，以便在网络存储环境下高效工作。

#### 验收标准

1. THE NAS_Connector SHALL 支持通过 SMB、AFP、NFS 三种协议连接 NAS 设备，用户在设置界面中配置 NAS 地址、协议类型、端口、用户名和密码
2. WHEN 用户添加一个 NAS 连接并通过验证，THE NAS_Connector SHALL 将该连接配置持久化存储到本地配置文件，下次启动时自动尝试重新连接
3. WHEN NAS 连接建立成功，THE Library_Scanner SHALL 扫描 NAS 上用户指定的共享文件夹，将音频文件的元数据和文件索引信息存入 Database
4. WHEN NAS 连接建立成功且扫描完成，THE Cache_Manager SHALL 自动将已索引素材的元数据和波形数据缓存到本地存储，无需用户手动触发
5. WHILE NAS 连接处于断开状态，THE Asset_Manager SHALL 允许用户浏览和搜索已缓存的素材元数据和波形数据，并在素材列表中将来源为 NAS 的素材标记为"离线"状态
6. WHILE NAS 连接处于断开状态，WHEN 用户尝试播放一条未缓存音频数据的 NAS 素材，THE Audio_Player SHALL 显示提示信息"NAS 连接不可用，无法播放该素材"
7. THE NAS_Connector SHALL 每 30 秒检测一次 NAS 连接状态，WHEN 连接状态从"已连接"变为"断开"，THE Asset_Manager SHALL 在界面状态栏显示"NAS 连接已断开"的提示通知
8. WHEN NAS 连接状态从"断开"恢复为"已连接"，THE Asset_Manager SHALL 在界面状态栏显示"NAS 连接已恢复"的提示通知，并自动同步 NAS 上新增或变更的文件
9. WHEN 用户在素材列表中触发播放一条来源为 NAS 的素材，THE Cache_Manager SHALL 先将该音频文件缓存到本地临时目录，缓存完成后 THE Audio_Player SHALL 从本地缓存文件开始播放
10. THE Cache_Manager SHALL 在播放缓存过程中显示下载进度，WHEN 缓存的音频文件大小超过 50MB 时，THE Cache_Manager SHALL 支持边下载边播放（流式缓存）
11. THE Asset_Manager SHALL 在设置界面中提供缓存管理配置项：本地缓存目录路径、缓存空间上限（默认 10GB）、手动清除缓存按钮
12. WHEN 本地缓存空间使用量达到用户设定的上限，THE Cache_Manager SHALL 自动删除最久未访问的缓存文件，直到缓存空间使用量降至上限的 80% 以下
13. THE Asset_Manager SHALL 在设置界面中显示当前缓存空间使用量和缓存文件数量
14. IF NAS 连接验证失败（地址不可达、认证失败或协议不支持），THEN THE NAS_Connector SHALL 显示具体的错误原因，包含 NAS 地址和失败类型

### 需求 14：收藏夹与播放列表

**用户故事：** 作为音频工作者，我希望创建多个收藏夹/播放列表来组织常用素材，以便快速访问和管理不同项目或场景下的素材集合。

#### 验收标准

1. THE Playlist_Manager SHALL 支持用户创建多个收藏夹，每个收藏夹包含名称和创建时间属性
2. WHEN 用户在素材列表中右键点击一条素材并选择"添加到收藏夹"，THE Playlist_Manager SHALL 显示已有收藏夹列表供用户选择，并将该素材添加到选中的收藏夹中
3. WHEN 用户选中一条素材并按下自定义快捷键，THE Playlist_Manager SHALL 将该素材添加到用户指定的默认收藏夹中
4. WHEN 用户在收藏夹视图中选中一条素材并执行"从收藏夹移除"操作，THE Playlist_Manager SHALL 将该素材从当前收藏夹中移除，不影响素材在素材库中的索引
5. WHEN 用户右键点击一个收藏夹并选择"重命名"，THE Playlist_Manager SHALL 允许用户修改该收藏夹的名称
6. WHEN 用户右键点击一个收藏夹并选择"删除"，THE Playlist_Manager SHALL 删除该收藏夹及其中的素材关联记录，不影响素材在素材库中的索引
7. THE Asset_Manager SHALL 在左侧导航面板中显示所有收藏夹列表，位于 UCS 分类树下方
8. WHEN 用户点击左侧导航面板中的某个收藏夹，THE Asset_Manager SHALL 在素材列表面板中显示该收藏夹中的所有素材
9. WHEN 用户从素材列表面板拖拽一条或多条素材到左侧导航面板中的某个收藏夹节点上，THE Playlist_Manager SHALL 将拖拽的素材添加到该收藏夹中
10. THE Playlist_Manager SHALL 将所有收藏夹数据（名称、素材关联关系）持久化存储到 Database 中，下次启动时自动加载

### 需求 15：历史记录

**用户故事：** 作为音频工作者，我希望软件记录最近播放的素材和搜索关键词，以便快速回溯之前的操作和重新定位素材。

#### 验收标准

1. WHEN Audio_Player 开始播放一条素材，THE History_Tracker SHALL 将该素材记录到"最近播放"历史列表中，包含素材标识和播放时间
2. THE History_Tracker SHALL 保留最近 100 条播放记录，WHEN 记录数超过 100 条时，THE History_Tracker SHALL 自动删除最早的记录
3. WHEN 用户在搜索栏中执行一次搜索，THE History_Tracker SHALL 将搜索关键词记录到"最近搜索"历史列表中，包含关键词文本和搜索时间
4. THE History_Tracker SHALL 保留最近 50 条搜索记录，WHEN 记录数超过 50 条时，THE History_Tracker SHALL 自动删除最早的记录
5. THE Asset_Manager SHALL 在左侧导航面板中提供"最近播放"入口，WHEN 用户点击该入口，THE Asset_Manager SHALL 在素材列表面板中按播放时间倒序显示最近播放的素材
6. THE Asset_Manager SHALL 在左侧导航面板中提供"最近搜索"入口，WHEN 用户点击该入口，THE Asset_Manager SHALL 显示最近搜索的关键词列表，用户点击某条关键词后自动执行该搜索
7. WHEN 用户在"最近播放"或"最近搜索"视图中执行"清除历史记录"操作，THE History_Tracker SHALL 清空对应的历史记录列表
8. THE History_Tracker SHALL 将所有历史记录数据持久化存储到 Database 中，下次启动时自动加载

### 需求 16：音频格式转换

**用户故事：** 作为音频工作者，我希望在传输素材时可以选择性地进行格式转换，以便将素材转换为目标项目所需的音频规格。

#### 验收标准

1. WHEN 用户执行素材传输操作时，THE Transfer_Manager SHALL 提供可选的格式转换选项，用户可以选择是否在传输过程中执行格式转换
2. THE Format_Converter SHALL 支持以下采样率转换：192kHz、96kHz、88.2kHz、48kHz、44.1kHz、22.05kHz、16kHz，用户可以选择目标采样率
3. THE Format_Converter SHALL 支持以下位深度转换：32bit float、24bit、16bit、8bit，用户可以选择目标位深度
4. THE Format_Converter SHALL 支持以下文件格式之间的相互转换：WAV、AIFF、MP3、FLAC、OGG、AAC
5. THE Asset_Manager SHALL 在传输设置界面中支持用户创建和保存多个转换预设规则，每个预设包含目标格式、采样率和位深度配置
6. WHILE Format_Converter 正在执行格式转换，THE Asset_Manager SHALL 显示转换进度信息，包含当前文件名和完成百分比
7. WHEN 格式转换完成后，THE Format_Converter SHALL 将原始文件中的元数据（Description、FXName、CatID、Category、SubCategory、CategoryFull、CreatorID、SourceID、UserData）写入转换后的文件中
8. IF 格式转换过程中发生错误（如磁盘空间不足或不支持的转换组合），THEN THE Format_Converter SHALL 跳过当前文件并记录错误信息，继续处理剩余文件，转换完成后向用户显示错误汇总

### 需求 17：自定义标签系统

**用户故事：** 作为音频工作者，我希望为素材添加自定义标签进行个性化分类，以便在 UCS 标准分类之外按照个人工作流程灵活组织素材。

#### 验收标准

1. THE Tag_Manager SHALL 支持用户创建自定义标签，每个标签包含名称和颜色属性
2. WHEN 用户在素材列表中选中一条或多条素材并执行"添加标签"操作，THE Tag_Manager SHALL 显示已有标签列表供用户选择，并将选中的标签关联到选中的素材上
3. THE Tag_Manager SHALL 支持为每条素材关联多个自定义标签
4. THE Asset_Manager SHALL 在设置界面或标签管理面板中提供标签管理功能，支持创建新标签、重命名标签、删除标签和修改标签颜色
5. WHEN 用户删除一个标签，THE Tag_Manager SHALL 移除该标签与所有素材的关联关系，不影响素材在素材库中的索引
6. THE Asset_Manager SHALL 在左侧导航面板中显示所有自定义标签列表，WHEN 用户点击某个标签，THE Asset_Manager SHALL 在素材列表面板中显示关联该标签的所有素材
7. WHEN 用户在搜索栏中执行搜索时，THE Search_Engine SHALL 支持按自定义标签作为过滤条件，与关键词搜索结果取交集后显示
8. THE Tag_Manager SHALL 将所有标签数据（名称、颜色、素材关联关系）持久化存储到 Database 中

### 需求 18：素材库导入导出

**用户故事：** 作为音频工作者，我希望将素材库的索引数据导出并在另一台机器上导入恢复，以便在多台设备之间迁移工作环境或备份素材库配置。

#### 验收标准

1. WHEN 用户执行"导出素材库"操作，THE Library_Exporter SHALL 将素材库索引数据（元数据、UCS 分类、自定义标签、收藏夹、用户偏好设置）导出为一个独立文件，不包含音频文件本身
2. THE Library_Exporter SHALL 支持 JSON 和 SQLite 数据库文件两种导出格式，用户可以在导出时选择格式
3. WHEN 用户执行"导入素材库"操作并选择一个导出文件，THE Library_Exporter SHALL 解析该文件并将索引数据导入到当前素材库中
4. WHEN 导入过程中遇到素材文件路径，THE Library_Exporter SHALL 检查该路径在本地是否存在：如果文件存在则建立关联，如果文件不存在则将该素材标记为"离线"状态
5. THE Library_Exporter SHALL 在导入时支持选择性导入，用户可以选择仅导入以下数据类别中的一项或多项：素材元数据、UCS 分类、自定义标签、收藏夹
6. WHEN 导入的数据与当前素材库中的数据存在冲突（如同一文件路径的元数据不同），THE Library_Exporter SHALL 提示用户选择保留本地数据、使用导入数据或逐条手动确认
7. THE Library_Exporter SHALL 在导入和导出过程中显示进度信息，包含已处理记录数和总记录数

### 需求 19：一键导入素材

**用户故事：** 作为音频工作者，我希望通过拖拽文件夹或设置监控文件夹的方式快速导入素材，以便减少手动操作，高效扩充素材库。

#### 验收标准

1. WHEN 用户从操作系统文件管理器拖拽一个或多个文件夹到 Asset_Manager 主窗口，THE Quick_Importer SHALL 递归扫描拖入的文件夹，将所有支持格式的音频文件导入素材库
2. WHEN 用户从操作系统文件管理器拖拽一个或多个音频文件到 Asset_Manager 主窗口，THE Quick_Importer SHALL 将拖入的音频文件直接导入素材库
3. WHEN Quick_Importer 导入一个音频文件时，THE Quick_Importer SHALL 自动调用 Metadata_Reader 读取元数据、调用 Waveform_Renderer 生成波形缓存、调用 UCS_Engine 归入对应的 UCS 分类
4. THE Asset_Manager SHALL 在设置界面中支持用户添加一个或多个"监控文件夹"路径，THE Quick_Importer SHALL 持续监控这些文件夹的文件变化
5. WHEN 监控文件夹中新增一个音频文件，THE Quick_Importer SHALL 在 10 秒内检测到该文件并自动执行导入流程
6. WHEN 监控文件夹中一个已索引的音频文件被删除，THE Quick_Importer SHALL 将该文件在 Database 中标记为"离线"状态
7. WHILE Quick_Importer 正在执行导入任务，THE Asset_Manager SHALL 保持界面响应，用户可以继续浏览、搜索和播放已索引的素材
8. WHEN Quick_Importer 完成一次导入任务，THE Asset_Manager SHALL 显示导入结果摘要通知，包含新增素材数量、更新素材数量和导入失败数量

### 需求 20：数据库架构与全文索引（新增）

**用户故事：** 作为音频工作者，我希望数据库既易于部署又能支撑百万级素材检索，以便在本地大量素材下仍保持流畅体验。

#### 验收标准

1. THE Database SHALL 使用 SQLite 作为主数据库，并启用 FTS5 作为全文索引引擎
2. THE Database SHALL 以 WAL 模式运行（`journal_mode=WAL`），以支持扫描写入与搜索并发
3. THE Database SHALL 至少包含以下核心表或逻辑实体：assets、metadata、ucs_categories、tags、asset_tags、playlists、playlist_items
4. THE Database SHALL 为以下字段建立索引：file_path、mtime、format、sample_rate、bit_depth、channels、status、cat_id
5. THE FTS5 索引字段 SHALL 包含：filename、description、fxname、category、subcategory、userdata
6. THE Database SHALL 支持 `asset_type` 字段（audio/video/other），以便未来扩展非音频素材
7. WHEN 素材库规模达到 1,000,000 条记录且存储位于 SSD，THE Search_Engine SHALL 在 1 秒内返回搜索结果（基准配置：16GB 内存 + 现代 CPU）
8. THE Library_Scanner SHALL 采用批量事务写入（500~2000 条/批），以减少索引构建耗时
9. THE Database SHALL 不存储波形原始数据，波形缓存由 Cache_Manager 管理并可清理

