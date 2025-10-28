# 快速开始指南

## 🚀 快速上手

### 步骤0：配置Pixabay API Key（可选）

如果需要使用网络图片搜索功能：

1. 访问 https://pixabay.com/api/docs/
2. 注册账号并获取免费API Key
3. 打开 `entry/src/main/ets/constants/ApiConstants.ets`
4. 替换 `PIXABAY_API_KEY` 为你的API Key：
```typescript
static readonly PIXABAY_API_KEY = 'YOUR_API_KEY_HERE';
```

> **注意**：示例项目已提供测试API Key，可直接使用。但有每日配额限制。

### 步骤1：打开项目
1. 启动 **DevEco Studio**
2. 选择 **Open** 打开本项目文件夹
3. 等待项目索引完成（右下角进度条）

### 步骤2：配置模拟器
1. 点击顶部工具栏的 **Device Manager**
2. 选择或创建一个模拟器：
   - **推荐**：Phone模拟器（用于基础测试）
   - **可选**：Tablet模拟器（测试响应式布局）
   - **可选**：Foldable模拟器（测试折叠屏适配）

### 步骤3：运行应用
1. 点击工具栏的 **▶ Run** 按钮（或按 `Shift + F10`）
2. 等待编译完成
3. 应用自动安装并启动

### 步骤4：开始游戏
1. **选择模式**：自由交换模式（拖拽）或华容道模式（点击）
2. **选择难度**：3×3 / 4×4 / 5×5
3. **选择图片**：
   - 预设图片
   - 相册选择
   - 网络图片搜索（输入关键字如"自然"）
4. **开始游戏**：点击"开始游戏"按钮
5. **玩游戏**：
   - 自由交换：拖拽方块或点击两个方块交换
   - 华容道：点击相邻方块移动到空格
6. **完成拼图**：拼图完成后自动显示胜利对话框

---

## 📱 模拟器测试建议

### 基础测试（Phone模拟器）
```
设备：API 12 Phone
分辨率：360 × 780 vp
测试内容：
  ✓ 基础游戏流程
  ✓ 3×3、4×4、5×5难度
  ✓ 所有动画效果
  ✓ 偷看原图功能
```

### 响应式测试（Tablet模拟器）
```
设备：API 12 Tablet
分辨率：600 × 1024 vp
测试内容：
  ✓ 拼图区域自适应
  ✓ 保持正方形比例
```

### 折叠屏测试（Foldable模拟器）
```
设备：API 12 Foldable
折叠分辨率：360 × 780 vp
展开分辨率：720 × 780 vp
测试内容：
  ✓ 折叠状态：上下单列布局
  ✓ 展开状态：左右双列布局
  ✓ 实时切换动态适配
```

---

## 🖼️ 相册选择功能测试

### 模拟器环境
1. **拖拽图片到模拟器**：
   - 从电脑文件夹拖拽图片到模拟器窗口
   - 图片会自动保存到模拟器相册

2. **在APP中选择**：
   - 点击主页的"相册选择"按钮
   - 系统会拉起图片选择器
   - 选择刚才拖入的图片
   - 图片会被自动切割并用于拼图

### 真机环境
1. 直接从手机相册选择任意图片
2. 支持jpg、png等常见格式

---

## 🎮 游戏玩法技巧

### 基础玩法
- **移动规则**：只能点击与空格相邻的方块
- **相邻定义**：上、下、左、右四个方向（不包括斜角）
- **胜利条件**：所有方块回到正确位置

### 辅助功能
- **偷看原图**：长按"偷看原图"按钮，显示半透明原图，松开自动隐藏
- **重新开始**：重新打乱当前拼图，计时和步数清零
- **结束游戏**：直接显示正确答案，游戏结束

### 难度建议
- **新手**：从3×3开始，熟悉规则
- **进阶**：挑战4×4，需要一定策略
- **专家**：尝试5×5，需要耐心和技巧

---

## 🔧 常见问题

### Q1: 编译失败，提示找不到模块
**A:** 
1. 检查网络连接
2. 打开 `File → Settings → SDK`
3. 确保已下载 API 12 SDK
4. 点击 `File → Sync Project with Dependency Files`

### Q2: 模拟器启动失败
**A:**
1. 确保电脑开启了虚拟化支持（BIOS设置）
2. 在Device Manager中删除旧模拟器，重新创建
3. 尝试使用不同的模拟器类型

### Q3: 相册选择报错
**A:**
1. 检查 `module.json5` 中是否已添加权限：
   ```json
   "requestPermissions": [
     { "name": "ohos.permission.READ_IMAGEVIDEO" }
   ]
   ```
2. 在模拟器中授予APP相册权限
3. 确保模拟器相册中有图片

### Q4: 动画卡顿
**A:**
1. 尝试使用性能更好的模拟器
2. 降低难度（5×5改为3×3）
3. 在真机上测试（真机性能通常更好）

### Q5: 图片显示不正确
**A:**
1. 确保图片格式正确（jpg、png）
2. 检查图片尺寸（建议500×500以上）
3. 尝试其他图片

---

## 📊 功能清单

### 已实现功能 ✅

#### 核心功能
- [x] 多图片选择
- [x] 图片切割（3×3 / 4×4 / 5×5）
- [x] 数字标记
- [x] 华容道移动逻辑
- [x] 打乱算法（确保有解）
- [x] 自动胜利判断
- [x] 多页面设计

#### 进阶功能
- [x] 方块移动动画
- [x] 洗牌动画
- [x] 胜利动画
- [x] 计时器
- [x] 步数统计
- [x] 偷看原图
- [x] 重新开始
- [x] 结束游戏

#### 创新功能
- [x] 相册选择
- [x] 响应式布局
- [x] 折叠屏适配
- [x] 多难度系统
- [x] 参数化设计

---

## 🎯 演示重点

### 基础演示（3分钟）
1. **启动APP** → 展示主页界面
2. **选择难度** → 演示3×3、4×4切换
3. **选择图片** → 演示预设图片选择
4. **开始游戏** → 展示洗牌动画
5. **移动方块** → 展示移动动画
6. **完成拼图** → 展示胜利动画和对话框

### 进阶演示（2分钟）
1. **偷看原图** → 长按按钮演示
2. **相册选择** → 拖拽图片到模拟器，然后在APP中选择
3. **折叠屏适配** → 切换到Foldable模拟器，演示折叠/展开

---

## 🌐 网络图片功能使用

### Pixabay API Key获取步骤

1. **注册账号**
   - 访问：https://pixabay.com/
   - 点击右上角"Join"注册

2. **获取API Key**
   - 登录后访问：https://pixabay.com/api/docs/
   - 在页面中找到你的API Key（通常显示为一串数字）

3. **配置到项目**
   - 打开 `entry/src/main/ets/constants/ApiConstants.ets`
   - 替换 `PIXABAY_API_KEY` 的值

4. **使用功能**
   - 在主页点击"从网络搜索图片"
   - 输入关键字（如：nature, animal, city）
   - 选择搜索结果中的图片

### 使用技巧
- 中英文关键字都支持
- 每次搜索返回最多20张图片
- "随机"按钮可获取随机主题的图片
- 免费配额：每月5000次请求

---

## 💡 开发提示

### 修改API Key
编辑 `entry/src/main/ets/constants/ApiConstants.ets`：
```typescript
static readonly PIXABAY_API_KEY = '你的API_KEY';
```

### 修改难度选项
编辑 `entry/src/main/ets/constants/GameConstants.ets`：
```typescript
static readonly DIFFICULTY_OPTIONS = [
  { label: '简单 (3×3)', value: 3 },
  { label: '中等 (4×4)', value: 4 },
  { label: '困难 (5×5)', value: 5 },
  // 可以添加更多难度
  { label: '极难 (6×6)', value: 6 }
];
```

### 修改动画时长
编辑 `entry/src/main/ets/constants/GameConstants.ets`：
```typescript
static readonly ANIMATION_DURATION = {
  TILE_MOVE: 200,    // 改为300可以让动画更慢
  SHUFFLE: 50,
  WIN: 300,
  PEEK_FADE: 200
};
```

### 添加预设图片
1. 将图片放入 `entry/src/main/resources/base/media/`
2. 编辑 `entry/src/main/ets/constants/ImageAssets.ets`：
```typescript
static readonly PRESET_IMAGES = [
  // ... 已有图片
  {
    id: 4,
    name: '新图片',
    resource: $r('app.media.your_image_name')
  }
];
```

### 修改颜色主题
编辑 `entry/src/main/ets/constants/GameConstants.ets`：
```typescript
static readonly COLORS = {
  PRIMARY: '#1890FF',      // 主题色
  BACKGROUND: '#F5F5F5',   // 背景色
  TILE_BG: '#FFFFFF',      // 方块背景
  EMPTY_BG: '#E8E8E8',     // 空格背景
  TEXT: '#333333',         // 文字颜色
  TEXT_OVERLAY: '#FFFFFF'  // 叠加文字
};
```

---

## 📚 相关文档

- **README.md** - 项目概览和功能介绍
- **IMPLEMENTATION.md** - 详细技术实现文档
- **拼图游戏APP实验方案.md** - 完整实验方案

---

## 🎉 开始探索吧！

现在你已经掌握了所有必要的知识，可以开始运行和探索这个拼图游戏APP了！

如果遇到问题，请查看上面的"常见问题"部分，或参考详细的技术实现文档。

祝你玩得开心！🚀

