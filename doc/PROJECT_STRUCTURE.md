# 项目文件结构说明

> **项目名称**：拼图游戏APP  
> **开发平台**：HarmonyOS  
> **开发语言**：ArkTS

---

## 📁 完整目录结构

```
Puzzle/
├── entry/src/main/
│   ├── ets/                                # ArkTS源代码
│   │   ├── pages/                          # 页面文件
│   │   │   ├── EntryPage.ets              # 入口页面
│   │   │   ├── ThemeSelectionPage.ets     # 主题选择页
│   │   │   ├── CharacterSelectionPage.ets # 角色选择页
│   │   │   ├── ImageSelectionPage.ets     # 图片选择页
│   │   │   └── GamePage.ets               # 游戏页面
│   │   │
│   │   ├── components/                     # 自定义组件
│   │   │   ├── DifficultyDialog.ets       # 难度选择弹窗
│   │   │   ├── NetworkImageSelector.ets   # 网络图片选择器
│   │   │   └── SoundButton.ets            # 声音控制按钮
│   │   │
│   │   ├── models/                         # 数据模型
│   │   │   ├── TileData.ets               # 方块数据类
│   │   │   └── GameState.ets              # 游戏状态类
│   │   │
│   │   ├── utils/                          # 工具类
│   │   │   ├── ImageSlicer.ets            # 图片切割工具
│   │   │   ├── ShuffleHelper.ets          # 打乱算法
│   │   │   ├── WinChecker.ets             # 胜利判断
│   │   │   ├── UriConverter.ets           # URI转换工具
│   │   │   ├── ScreenStateManager.ets     # 屏幕状态管理
│   │   │   ├── AudioManager.ets           # 音频管理器
│   │   │   ├── ImageCropper.ets           # 图片裁剪工具
│   │   │   ├── ImageCache.ets             # 图片缓存
│   │   │   ├── NetworkImageService.ets    # 网络图片服务
│   │   │   └── GameStorage.ets            # 游戏数据存储
│   │   │
│   │   ├── constants/                      # 常量定义
│   │   │   ├── GameConstants.ets          # 游戏常量
│   │   │   ├── DesignConstants.ets        # 设计规范常量
│   │   │   ├── ImageAssets.ets            # 图片资源配置
│   │   │   └── ApiConstants.ets           # API配置
│   │   │
│   │   ├── formability/                    # 卡片扩展能力
│   │   │   └── PuzzleFormAbility.ets      # 卡片Ability
│   │   │
│   │   ├── widget/pages/                   # 卡片页面
│   │   │   └── WidgetCard.ets             # 卡片布局页面
│   │   │
│   │   └── entryability/                   # 入口能力
│   │       └── EntryAbility.ets           # 应用入口Ability
│   │
│   └── resources/                          # 资源文件
│       ├── base/
│       │   ├── element/
│       │   │   └── string.json            # 字符串资源
│       │   ├── media/                      # 媒体资源
│       │   └── profile/
│       │       ├── main_pages.json        # 路由配置
│       │       └── form_config.json       # 卡片配置
│       └── rawfile/                        # 原始文件
│           ├── images/                     # 图片资源
│           │   ├── background/            # 背景图片
│           │   ├── laite/                 # 莱特角色图片
│           │   ├── weiweian/              # 薇薇安角色图片
│           │   ├── bangbu/                # 邦布图片
│           │   └── icon/                  # 图标文件
│           ├── music/                      # 音乐文件
│           │   ├── 主题背景音乐.mp3
│           │   ├── 莱特.mp3
│           │   ├── 薇薇安.mp3
│           │   ├── 邦布.mp3
│           │   └── 网络与相册.mp3
│           └── fonts/                      # 字体文件
│               └── Muyao-Softbrush.ttf
│
├── doc/                                    # 技术文档
│   ├── 编译与构建问题解决方案.md
│   ├── UI布局与屏幕适配解决方案.md
│   ├── 网络与图片处理解决方案.md
│   ├── 卡片功能实现与修复方案.md
│   └── 拼图游戏音频系统实现文档.md
│
├── README.md                               # 项目说明
├── PROJECT_STRUCTURE.md                    # 本文件
└── design-summary.txt                      # 设计文档
```

---

## 📊 文件统计

### 代码文件统计

| 类型 | 数量 | 说明 |
|-----|------|------|
| 页面文件 | 5 | Entry, Theme, Character, Image, Game |
| 组件文件 | 3+ | Dialog, Selector, Button等 |
| 工具类 | 10+ | ImageSlicer, AudioManager等 |
| 数据模型 | 2 | TileData, GameState |
| 常量配置 | 4 | Game, Design, Image, Api |
| Ability | 2 | EntryAbility, PuzzleFormAbility |
| **总计** | **26+** | **ArkTS文件** |

### 资源文件统计

| 类型 | 数量 | 说明 |
|-----|------|------|
| 背景图片 | 3 | 主页、主题选择、其他页面 |
| 角色图片 | 14 | 莱特6张、薇薇安8张 |
| 邦布图片 | 9 | 邦布专辑图片 |
| 图标文件 | 4+ | 返回、主题、声音、静音 |
| 音乐文件 | 5 | 背景音乐、角色音乐 |
| 字体文件 | 1 | 木瑶软笔字体 |

### 文档文件统计

| 类型 | 数量 | 说明 |
|-----|------|------|
| 项目文档 | 3 | README, PROJECT_STRUCTURE, design-summary |
| 技术文档 | 5 | 编译、UI、网络、卡片、音频解决方案 |
| **总计** | **8** | **Markdown/Text文件** |

---

## 🔍 核心文件说明

### 页面文件（Pages）

#### EntryPage.ets
- **功能**：应用入口页面
- **内容**："开始拼图"按钮
- **跳转**：→ ThemeSelectionPage

#### ThemeSelectionPage.ets
- **功能**：主题选择页面
- **内容**：角色专辑、邦布专辑、网络随机、相册上传
- **跳转**：→ CharacterSelectionPage / ImageSelectionPage

#### CharacterSelectionPage.ets
- **功能**：角色选择页面
- **内容**：莱特、薇薇安角色切换
- **跳转**：→ ImageSelectionPage

#### ImageSelectionPage.ets
- **功能**：图片选择页面
- **内容**：根据来源显示不同图片（角色/邦布/网络/相册）
- **特性**：网络图片预加载、图片裁剪
- **跳转**：→ GamePage

#### GamePage.ets
- **功能**：游戏主页面
- **内容**：拼图游戏、功能按钮、计时器、步数统计
- **特性**：双模式切换、偷看答案、重新开始
- **行数**：~500行（最复杂的页面）

---

### 工具类（Utils）

#### ScreenStateManager.ets
- **功能**：折叠屏状态检测与管理
- **特性**：三屏/双屏/单屏识别、方向控制
- **关键技术**：双事件协调、过渡状态保护

#### AudioManager.ets
- **功能**：音频管理器（单例模式）
- **特性**：背景音乐播放、音量控制、进度记忆
- **关键技术**：AVPlayer状态机、Preferences持久化

#### ImageCropper.ets
- **功能**：图片裁剪工具
- **特性**：中心裁剪为正方形
- **应用**：确保所见即所得

#### ImageCache.ets
- **功能**：图片缓存（静态全局缓存）
- **特性**：跨页面传递PixelMap
- **应用**：网络图片、相册图片缓存

#### UriConverter.ets
- **功能**：URI/URL转换为PixelMap
- **特性**：支持相册URI、网络URL、rawfile路径
- **关键技术**：HTTP请求、重试机制

#### GameStorage.ets
- **功能**：游戏数据持久化存储
- **特性**：Preferences存储、卡片ID管理
- **应用**：游戏进度保存、卡片状态管理

#### ImageSlicer.ets
- **功能**：图片切割为N×N方块
- **输入**：PixelMap、gridSize
- **输出**：TileData数组

#### ShuffleHelper.ets
- **功能**：打乱算法
- **特性**：模拟移动法确保有解
- **模式**：华容道模式、交换模式

#### WinChecker.ets
- **功能**：胜利条件判断
- **逻辑**：检查每个方块是否在正确位置

#### NetworkImageService.ets
- **功能**：网络图片搜索服务
- **API**：Pixabay API、国内免费API
- **特性**：关键字搜索、随机图片

---

### 常量配置（Constants）

#### GameConstants.ets
```typescript
- GAME_MODE: { SLIDE, SWAP }         // 游戏模式
- DIFFICULTY_OPTIONS: [3, 4, 5]      // 难度选项
- ANIMATION_DURATION: 200            // 动画时长
- GRID_GAP: 4                        // 方块间隙
```

#### DesignConstants.ets
```typescript
- THEME_BUTTON: {...}                // 主题选择按钮尺寸
- GAME_WIDE_BUTTON: {...}            // 游戏页宽按钮
- GAME_SMALL_BUTTON: {...}           // 游戏页小按钮
- BACK_BUTTON: {...}                 // 返回按钮配置
- 支持三种屏幕状态：TRIPLE, DOUBLE, SINGLE
```

#### ImageAssets.ets
```typescript
- CHARACTERS: { laite, weiweian }    // 角色信息
- BANGBU_IMAGES: [...]               // 邦布图片列表
- BACKGROUNDS: {...}                 // 背景图片路径
- ICONS: {...}                       // 图标路径
```

#### ApiConstants.ets
```typescript
- PIXABAY_API_KEY: string            // Pixabay API密钥
- BING_IMAGE_URL: string             // 必应壁纸API
- RANDOM_IMAGE_APIS: [...]           // 随机图片API列表
```

---

## 🎯 功能模块映射

### 屏幕适配相关
```
ScreenStateManager.ets       # 屏幕状态检测
DesignConstants.ets          # 响应式尺寸配置
所有页面文件                  # 使用响应式布局
```

### 网络图片相关
```
UriConverter.ets             # URL→PixelMap转换
ImageCropper.ets             # 图片裁剪
ImageCache.ets               # 图片缓存
NetworkImageService.ets      # 网络图片服务
ImageSelectionPage.ets       # 网络图片预加载
```

### 音频系统相关
```
AudioManager.ets             # 音频管理器
SoundButton.ets              # 声音控制按钮
所有页面文件                  # 集成背景音乐
EntryAbility.ets             # 生命周期管理
```

### 卡片功能相关
```
PuzzleFormAbility.ets        # 卡片Ability
WidgetCard.ets               # 卡片布局
GameStorage.ets              # 数据持久化
GamePage.ets                 # 游戏状态保存
EntryAbility.ets             # 卡片更新触发
```

### 游戏逻辑相关
```
GamePage.ets                 # 游戏主逻辑
ImageSlicer.ets              # 图片切割
ShuffleHelper.ets            # 打乱算法
WinChecker.ets               # 胜利判断
TileData.ets                 # 方块数据模型
GameState.ets                # 游戏状态模型
```

---

## 📈 代码行数估算

| 文件类型 | 行数 | 占比 |
|---------|------|------|
| GamePage.ets | ~500 | 20% |
| 其他页面文件（4个） | ~800 | 32% |
| 工具类（10个） | ~800 | 32% |
| 组件、模型、常量 | ~400 | 16% |
| **总计** | **~2500行** | **100%** |

---

## 🗂️ 依赖关系

### 页面依赖层次
```
EntryPage
  └─> ThemeSelectionPage
        ├─> CharacterSelectionPage
        │     └─> ImageSelectionPage (角色图片)
        ├─> ImageSelectionPage (邦布/网络/相册)
        └─> GamePage
```

### 工具类依赖
```
GamePage
  ├─> ImageSlicer (图片切割)
  ├─> ShuffleHelper (打乱)
  ├─> WinChecker (胜利判断)
  ├─> ScreenStateManager (屏幕状态)
  ├─> AudioManager (音频)
  ├─> GameStorage (数据存储)
  └─> ImageCache (图片缓存)

ImageSelectionPage
  ├─> UriConverter (URI转换)
  ├─> ImageCropper (图片裁剪)
  ├─> ImageCache (图片缓存)
  ├─> NetworkImageService (网络图片)
  └─> AudioManager (音频)
```

---

## 📂 资源文件说明

### 图片资源结构
```
images/
├── background/              # 背景图片（3张）
│   ├── 主页面背景图.jpg
│   ├── 主题选择页面背景.jpg
│   └── 其余页面背景图.png
│
├── laite/                   # 莱特角色（6张）
│   ├── 角色显示图.png
│   └── 莱特拼图1-5.jpg
│
├── weiweian/                # 薇薇安角色（8张）
│   ├── 角色显示图.png
│   └── 薇薇安拼图1-7.jpg
│
├── bangbu/                  # 邦布（9张）
│   └── 邦布图片1-9.jpg
│
└── icon/                    # 图标（4+张）
    ├── 返回.png
    ├── 主题.png
    ├── 声音.png
    └── 静音.png
```

### 音乐资源
```
music/
├── 主题背景音乐.mp3         # 入口页、主题选择、角色选择
├── 莱特.mp3                # 选择莱特后的页面
├── 薇薇安.mp3              # 选择薇薇安后的页面
├── 邦布.mp3                # 选择邦布后的页面
└── 网络与相册.mp3           # 网络随机/相册上传后的页面
```

---

## 📚 技术文档说明

### /doc 目录文档

#### 编译与构建问题解决方案.md
- **内容**：修复160+个ArkTS编译错误
- **覆盖**：类型错误、静态方法、构建配置
- **价值**：完整的编译问题排查指南

#### UI布局与屏幕适配解决方案.md
- **内容**：折叠屏适配、双屏布局修复
- **覆盖**：屏幕状态检测、像素转换、UI规范化
- **价值**：三折叠屏完整适配方案

#### 网络与图片处理解决方案.md
- **内容**：网络图片显示、图片裁剪
- **覆盖**：PixelMap预加载、网络检查、API适配
- **价值**：网络图片完整解决方案

#### 卡片功能实现与修复方案.md
- **内容**：卡片实时更新、双重保存机制
- **覆盖**：AppStorage、Preferences、时序问题
- **价值**：卡片零延迟同步方案

#### 拼图游戏音频系统实现文档.md
- **内容**：音频系统完整实现
- **覆盖**：AVPlayer、音量控制、进度记忆
- **价值**：音频系统完整开发指南

---

## ✅ 完成度检查

### 核心功能
- [x] 页面文件（5个）
- [x] 游戏逻辑（完整）
- [x] 图片处理（切割、裁剪）
- [x] 屏幕适配（三种状态）

### 进阶功能
- [x] 网络图片（搜索、预加载）
- [x] 音频系统（5首音乐、控制）
- [x] 卡片功能（实时更新）
- [x] 动画效果（丝滑）

### 文档完整性
- [x] README.md（项目概览）
- [x] PROJECT_STRUCTURE.md（本文件）
- [x] 5个技术解决方案文档
- [x] design-summary.txt（设计文档）

---

## 🎉 项目完成度：100%

所有功能已完整实现，代码结构清晰，文档完整详细！

---

**最后更新日期**：2025年11月8日  
**文档版本**：v2.0
