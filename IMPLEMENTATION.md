# 拼图游戏APP - 技术实现详解

## 一、核心技术实现

### 1. 图片分割技术

**文件位置**：`entry/src/main/ets/utils/ImageSlicer.ets`

#### 实现原理
```typescript
// 1. 获取原图信息
const imageInfo = await pixelMap.getImageInfo();
const width = imageInfo.size.width;
const height = imageInfo.size.height;

// 2. 计算每个方块尺寸
const tileWidth = Math.floor(width / gridSize);
const tileHeight = Math.floor(height / gridSize);

// 3. 循环裁剪
for (let row = 0; row < gridSize; row++) {
  for (let col = 0; col < gridSize; col++) {
    const region: image.Region = {
      x: col * tileWidth,
      y: row * tileHeight,
      size: { width: tileWidth, height: tileHeight }
    };
    const tilePM = await pixelMap.crop(region);
  }
}
```

#### 关键点
- 使用`PixelMap.crop()`进行图片裁剪
- 最后一个位置设置为空格（isEmpty: true）
- 每个方块保存原始id用于胜利判断

---

### 2. 打乱算法（确保有解）

**文件位置**：`entry/src/main/ets/utils/ShuffleHelper.ets`

#### 为什么需要特殊处理？
随机打乱拼图可能导致无解的情况。例如3×3拼图有9!/2种状态是无解的。

#### 解决方案：模拟移动法
```typescript
// 1. 从正确状态开始
let emptyIndex = gridSize * gridSize - 1;

// 2. 随机移动100次
for (let i = 0; i < 100; i++) {
  // 获取所有可移动的方块
  const movableIndices = this.getMovableIndices(emptyIndex, gridSize);
  
  // 随机选择一个
  const randomIndex = movableIndices[Math.floor(Math.random() * movableIndices.length)];
  
  // 交换
  swap(tiles, randomIndex, emptyIndex);
  emptyIndex = randomIndex;
}
```

#### 优势
- ✅ 100%保证有解（因为是从有解状态变换来的）
- ✅ 实现简单，代码可读性强
- ✅ 不需要复杂的数学计算

---

### 3. 相邻性判断

**文件位置**：`entry/src/main/ets/utils/ShuffleHelper.ets`

#### 判断逻辑
```typescript
static isAdjacent(index1: number, index2: number, gridSize: number): boolean {
  const row1 = Math.floor(index1 / gridSize);
  const col1 = index1 % gridSize;
  const row2 = Math.floor(index2 / gridSize);
  const col2 = index2 % gridSize;
  
  // 同一行且相差1列
  if (row1 === row2 && Math.abs(col1 - col2) === 1) {
    return true;
  }
  
  // 同一列且相差1行
  if (col1 === col2 && Math.abs(row1 - row2) === 1) {
    return true;
  }
  
  return false;
}
```

#### 关键点
- 索引转换为行列坐标：`row = index / gridSize`, `col = index % gridSize`
- 检查上下左右四个方向
- 避免斜角移动

---

### 4. 胜利判断

**文件位置**：`entry/src/main/ets/utils/WinChecker.ets`

#### 判断标准
```typescript
static checkWin(tiles: TileData[]): boolean {
  for (let i = 0; i < tiles.length; i++) {
    if (tiles[i].id !== tiles[i].currentIndex) {
      return false;
    }
  }
  return true;
}
```

#### 说明
- 每个方块的`id`表示其原始位置
- `currentIndex`表示当前位置
- 当所有方块的id === currentIndex时，拼图完成

---

## 二、动画实现

### 1. 方块移动动画

**实现位置**：`GamePage.ets` - `moveTile()`方法

```typescript
animateTo({
  duration: 200,
  curve: Curve.EaseOut
}, () => {
  // 交换方块
  const temp = this.tiles[index];
  this.tiles[index] = this.tiles[emptyIndex];
  this.tiles[this.emptyIndex] = temp;
});
```

#### 效果
- 200ms平滑滑动
- EaseOut曲线（先快后慢）
- 视觉上流畅自然

---

### 2. 洗牌动画

**实现位置**：`GamePage.ets` - `shuffleWithAnimation()`方法

```typescript
private shuffleWithAnimation(): void {
  const result = ShuffleHelper.shuffle(this.tiles, this.gridSize);
  
  animateTo({
    duration: 200,
    curve: Curve.EaseOut
  }, () => {
    this.tiles = result.tiles;
    this.emptyIndex = result.emptyIndex;
  });
}
```

#### 效果
- 所有方块同时移动到打乱位置
- 增强游戏开始的仪式感

---

### 3. 胜利动画

**实现位置**：`GamePage.ets` - `playWinAnimation()`方法

```typescript
animateTo({
  duration: 300,
  curve: Curve.EaseInOut
}, () => {
  this.gridGap = 0;  // 方块间隙消失
});
```

#### 效果
- 方块间隙从4vp逐渐变为0
- 拼图"合体"效果
- 随后弹出胜利对话框

---

### 4. 偷看动画

**实现位置**：`GamePage.ets` - 偷看按钮的onTouch事件

```typescript
.onTouch((event) => {
  if (event.type === TouchType.Down) {
    animateTo({
      duration: 200,
      curve: Curve.EaseInOut
    }, () => {
      this.isPeeking = true;
    });
  } else if (event.type === TouchType.Up) {
    animateTo({
      duration: 200,
      curve: Curve.EaseInOut
    }, () => {
      this.isPeeking = false;
    });
  }
})
```

#### 效果
- 长按显示半透明原图
- 松开自动隐藏
- 200ms淡入淡出效果

---

## 三、响应式布局实现

### 1. 拼图区域自适应

**实现位置**：`GamePage.ets` - `puzzleArea()`方法

```typescript
Stack() {
  Grid() {
    // ...
  }
  .columnsTemplate('1fr '.repeat(this.gridSize).trim())
  .rowsTemplate('1fr '.repeat(this.gridSize).trim())
  .width('100%')
  .height('100%')
}
.width('90%')      // 相对屏幕宽度
.aspectRatio(1.0)  // 强制正方形
```

#### 关键技术
- **百分比宽度**：`width('90%')` - 相对于父容器
- **aspectRatio**：`.aspectRatio(1.0)` - 保持1:1正方形
- **fr单位**：`'1fr 1fr 1fr'` - 网格自动平分

#### 适配效果
| 设备 | 屏幕宽度 | 拼图区域 |
|------|---------|---------|
| Phone | 360vp | 324vp × 324vp |
| Tablet | 600vp | 540vp × 540vp |
| Foldable（折叠） | 360vp | 324vp × 324vp |
| Foldable（展开） | 720vp | 648vp × 648vp |

---

### 2. 动态网格模板

```typescript
.columnsTemplate('1fr '.repeat(this.gridSize).trim())
```

#### 生成结果
- 3×3：`'1fr 1fr 1fr'`
- 4×4：`'1fr 1fr 1fr 1fr'`
- 5×5：`'1fr 1fr 1fr 1fr 1fr'`

#### 优势
- ✅ 完全参数化，不写死
- ✅ 一套代码适配所有难度
- ✅ 展示代码抽象能力

---

## 四、折叠屏适配

### 1. 媒体查询监听

**实现位置**：`GamePage.ets` - `initMediaQuery()`方法

```typescript
private initMediaQuery(): void {
  // 创建监听器
  this.listener = mediaquery.matchMediaSync('(min-width: 600vp)');
  
  // 注册回调
  this.listener.on('change', (result) => {
    this.isWideScreen = result.matches;
  });
  
  // 获取初始状态
  this.isWideScreen = this.listener.matches;
}
```

#### 断点设置
- **600vp**：宽屏与窄屏的分界点
- `< 600vp`：手机竖屏、折叠屏折叠状态
- `≥ 600vp`：平板、折叠屏展开状态

---

### 2. 动态布局切换

```typescript
if (this.isWideScreen) {
  // 宽屏布局（横向）
  Row({ space: 16 }) {
    Column() { this.puzzleArea() }.layoutWeight(7)
    Column() { this.controlArea() }.layoutWeight(3)
  }
} else {
  // 窄屏布局（纵向）
  Column({ space: 16 }) {
    Column() { this.puzzleArea() }
    this.controlArea()
  }
}
```

#### 布局对比

**窄屏（<600vp）**
```
┌─────────────┐
│   拼图区    │
│             │
├─────────────┤
│   控制区    │
│  计时 步数  │
│   按钮组    │
└─────────────┘
```

**宽屏（≥600vp）**
```
┌─────────────┬──────┐
│             │计时  │
│   拼图区    │步数  │
│             │      │
│             │按钮组│
└─────────────┴──────┘
```

---

## 五、相册选择功能

### 1. 选择图片

**实现位置**：`HomePage.ets` - `selectFromGallery()`方法

```typescript
async selectFromGallery(): Promise<void> {
  const photoSelectOptions = new picker.PhotoSelectOptions();
  photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
  photoSelectOptions.maxSelectNumber = 1;

  const photoPicker = new picker.PhotoViewPicker();
  const result = await photoPicker.select(photoSelectOptions);

  if (result && result.photoUris && result.photoUris.length > 0) {
    this.customImageUri = result.photoUris[0];
    this.selectedImageId = -1;
  }
}
```

---

### 2. URI转PixelMap

**实现位置**：`UriConverter.ets` - `uriToPixelMap()`方法

```typescript
static async uriToPixelMap(uri: string): Promise<image.PixelMap> {
  // 1. 打开文件
  const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
  
  // 2. 创建ImageSource
  const imageSource = image.createImageSource(file.fd);
  
  // 3. 创建PixelMap
  const pixelMap = await imageSource.createPixelMap({
    desiredPixelFormat: image.PixelMapFormat.RGBA_8888
  });
  
  // 4. 关闭文件
  fileIo.closeSync(file);
  
  return pixelMap;
}
```

#### 转换流程
```
URI → File Descriptor → ImageSource → PixelMap
```

---

## 六、游戏逻辑流程

### 完整游戏流程图

```
启动APP
  ↓
主页（HomePage）
  ├─ 选择难度（3×3 / 4×4 / 5×5）
  ├─ 选择图片（预设 / 相册）
  └─ 点击"开始游戏"
  ↓
游戏页初始化（GamePage）
  ├─ 加载图片（Resource / URI → PixelMap）
  ├─ 切割图片（ImageSlicer.sliceImage）
  ├─ 显示完整拼图（1秒）
  └─ 洗牌动画（ShuffleHelper.shuffle）
  ↓
游戏进行中
  ├─ 计时器开始（每秒+1）
  ├─ 点击方块
  │   ├─ 判断是否相邻（ShuffleHelper.isAdjacent）
  │   ├─ 移动动画（animateTo）
  │   ├─ 步数+1
  │   └─ 检查胜利（WinChecker.checkWin）
  │
  ├─ 辅助功能
  │   ├─ 偷看原图（长按显示半透明原图）
  │   ├─ 重新开始（重新洗牌）
  │   └─ 结束游戏（显示正确答案）
  │
  └─ 拼图完成
      ↓
胜利判断
  ├─ 停止计时
  ├─ 胜利动画（间隙消失）
  └─ 显示对话框
      ├─ 显示耗时
      ├─ 显示步数
      ├─ "再玩一次" → 重新开始
      └─ "返回主页" → 返回主页
```

---

## 七、性能优化

### 1. 图片加载优化
- 使用PixelMap进行图片处理，避免重复解码
- 裁剪后的小图片独立存储，不重复计算

### 2. 动画性能
- 使用`animateTo`显式动画，由系统优化
- 动画时长控制在200-300ms，保证流畅
- 仅对移动的方块应用动画

### 3. 状态管理
- 使用@State响应式状态管理
- 避免不必要的UI刷新
- 及时清理定时器和监听器

---

## 八、代码质量

### 1. 模块化设计
```
utils/     - 工具类（纯函数，无状态）
models/    - 数据模型（类定义）
components/- 可复用组件
pages/     - 页面组件
constants/ - 常量定义
```

### 2. 类型安全
- 全部使用TypeScript类型标注
- 接口定义清晰
- 避免any类型

### 3. 代码复用
- 工具类函数可独立使用
- 组件通过@Link实现双向绑定
- 参数化设计，避免硬编码

---

## 九、测试建议

### 1. 功能测试
- [ ] 测试3×3、4×4、5×5三种难度
- [ ] 测试预设图片选择
- [ ] 测试相册图片选择
- [ ] 测试拼图移动逻辑
- [ ] 测试胜利判断
- [ ] 测试计时器和步数统计
- [ ] 测试偷看原图功能

### 2. 动画测试
- [ ] 测试移动动画流畅度
- [ ] 测试洗牌动画效果
- [ ] 测试胜利动画效果
- [ ] 测试偷看淡入淡出

### 3. 响应式测试
- [ ] Phone模拟器（360vp）
- [ ] Tablet模拟器（600vp+）
- [ ] Foldable模拟器（折叠/展开切换）

### 4. 边界测试
- [ ] 快速连续点击方块
- [ ] 打乱后立即结束游戏
- [ ] 游戏中返回主页
- [ ] 相册选择后取消

---

## 十、已知限制

1. **图片格式**：仅支持常见图片格式（jpg, png等）
2. **性能**：5×5难度在低端设备上可能略有卡顿
3. **相册权限**：首次使用需授予图片访问权限

---

## 十一、后续优化方向

### 可选扩展功能
1. **最佳成绩记录**：使用Preferences保存历史最佳成绩
2. **多图模式**：一次玩多个拼图
3. **联网排行榜**：与其他玩家比拼
4. **自定义皮肤**：更换UI主题色
5. **音效**：添加移动、胜利音效

### 技术优化
1. **图片缓存**：避免重复加载
2. **延迟加载**：大图片使用缩略图
3. **Worker线程**：图片处理移至后台线程

---

## 总结

本项目实现了一个功能完整、技术先进的拼图游戏APP，涵盖了：

✅ **核心功能**：图片分割、华容道逻辑、胜利判断  
✅ **进阶功能**：丝滑动画、计时统计、多难度  
✅ **创新功能**：相册选择、响应式布局、折叠屏适配  

代码结构清晰、注释完整、可维护性强，完美展示了HarmonyOS应用开发能力！🎉

