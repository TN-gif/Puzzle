import { router, font, display } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { TileData } from '../models/TileData';
import { ImageSlicer } from '../utils/ImageSlicer';
import { ShuffleHelper } from '../utils/ShuffleHelper';
import { WinChecker } from '../utils/WinChecker';
import { UriConverter } from '../utils/UriConverter';
import { SoundService } from '../utils/SoundService';
import { GameStorage, SavedGameState } from '../utils/GameStorage';
import { GameConstants } from '../constants/GameConstants';
import { DesignConstants } from '../constants/DesignConstants';
import { ScreenState, ScreenStateManager } from '../utils/ScreenStateManager';
import { WinDialog } from '../components/WinDialog';
import { DifficultyDialog } from '../components/DifficultyDialog';
import { ImageCache } from '../utils/ImageCache';
import { formProvider, formBindingData } from '@kit.FormKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { audioManager } from '../utils/AudioManager';
import { SoundButton } from '../components/SoundButton';

/**
 * 路由参数接口
 */
interface GamePageParams {
  gameMode: string;
  gridSize: number;
  imageResource: Resource | string;
  isCustomImage: boolean;
  isNetworkImage: boolean;
  useCachedImage?: boolean;  // 是否使用缓存的裁剪后图片
  fromPage?: string;  // 来源页面
  source?: string;  // 图片来源（用于音乐播放）
  characterId?: string;  // 角色ID（用于音乐播放）
}

/**
 * 卡片数据接口
 */
interface FormDataContent {
  title: string;
  gameMode: string;
  gridSize: string;
  moveCount: number;
  timeElapsed: string;
  hasActiveGame: boolean;
}

/**
 * 位置接口
 */
interface Position {
  x: number;
  y: number;
}

/**
 * 图片尺寸接口
 */
interface ImageSize {
  x: number;
  y: number;
  width: number;
  height: number;
}

/**
 * 按钮尺寸接口
 */
interface ButtonSize {
  width: number;
  height: number;
}

/**
 * 按钮位置配置接口
 */
interface GameButtonPositions {
  mode: Position;
  difficulty: Position;
  peek: Position;
  restart: Position;
  image: ImageSize;
  back: Position;
}

/**
 * 游戏页：拼图游戏核心逻辑
 */
@Entry
@Component
struct GamePage {
  // 路由参数
  @State gameMode: string = GameConstants.GAME_MODE.SWAP;
  @State gridSize: number = 3;
  @State imageResource: Resource | string = '';
  @State isCustomImage: boolean = false;
  @State isNetworkImage: boolean = false;
  @State useCachedImage: boolean = false;  // 是否使用缓存的裁剪后图片
  @State fromPage: string = '';  // 来源页面
  @State source: string = '';  // 图片来源（用于音乐播放）
  @State characterId: string = '';  // 角色ID（用于音乐播放）
  
  // 🔥 卡片跳转监听
  @StorageProp('widgetTargetPage') widgetTargetPage: string = '';
  @StorageProp('widgetTargetPageTimestamp') widgetTargetPageTimestamp: number = 0;
  private lastProcessedTimestamp: number = 0;  // 记录已处理的跳转请求

  // 游戏状态
  @State tiles: TileData[] = [];
  @State emptyIndex: number = 8;
  @State moveCount: number = 0;
  @State timeElapsed: number = 0;
  @State isPlaying: boolean = false;
  @State originalPixelMap: image.PixelMap | null = null;

  // UI状态
  @State isPeeking: boolean = false;
  @State gridGap: number = GameConstants.GRID_GAP;
  @State draggedTileIndex: number = -1;
  @State selectedTileIndex: number = -1;
  @State screenState: ScreenState = ScreenState.TRIPLE;
  @State isDragging: boolean = false;  // 是否正在拖拽
  @State dragStartX: number = 0;  // 拖拽起始X坐标
  @State dragStartY: number = 0;  // 拖拽起始Y坐标
  @State dragOffsetX: number = 0;  // 拖拽X偏移
  @State dragOffsetY: number = 0;  // 拖拽Y偏移
  
  // Grid组件的实际位置和尺寸（通过onAreaChange动态获取）
  @State gridPositionX: number = 0;  // Grid在屏幕上的X坐标
  @State gridPositionY: number = 0;  // Grid在屏幕上的Y坐标
  @State gridActualSize: number = 0;  // Grid的实际尺寸
  
  // 实际屏幕尺寸（用于响应式缩放）
  @State actualWidth: number = 1107;
  @State actualHeight: number = 776;
  
  // 偷看答案前的状态保存
  private savedTilesBeforePeek: TileData[] = [];
  private savedEmptyIndexBeforePeek: number = -1;

  // 定时器
  private timerInterval: number = -1;
  private screenManager: ScreenStateManager = ScreenStateManager.getInstance();

  // 胜利对话框
  private winDialogController: CustomDialogController = new CustomDialogController({
    builder: WinDialog({
      moveCount: this.moveCount,
      timeElapsed: this.timeElapsed,
      onPlayAgain: () => {
        this.restartGame();
      },
      onBackHome: () => {
        this.goBackHome();
      }
    }),
    autoCancel: false,
    customStyle: true
  });

  // 难度选择对话框
  private difficultyDialogController: CustomDialogController = new CustomDialogController({
    builder: DifficultyDialog({
      selectedDifficulty: this.gridSize,
      onDifficultySelected: (difficulty: number) => {
        this.changeDifficulty(difficulty);
      }
    }),
    autoCancel: true,
    customStyle: true
  });

  async aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as GamePageParams;

    if (params) {
      this.gameMode = params.gameMode || GameConstants.GAME_MODE.SWAP;
      this.gridSize = params.gridSize || 3;
      this.imageResource = params.imageResource;
      this.isCustomImage = params.isCustomImage || false;
      this.isNetworkImage = params.isNetworkImage || false;
      this.useCachedImage = params.useCachedImage || false;
      this.fromPage = params.fromPage || '';
      this.source = params.source || '';
      this.characterId = params.characterId || '';
    }
    
    // 🔥 官方确认方案：检测无效启动并双数据源清除
    if (!params || !this.imageResource) {
      console.warn('[GamePage] ⚠️ 检测到无效启动（应用被清除后从卡片启动）');
      console.info('[GamePage] 📊 启动诊断信息:');
      console.info('[GamePage]   - 路由参数: %{public}s', params ? 'exists' : 'null');
      console.info('[GamePage]   - 图片资源: %{public}s', this.imageResource ? 'exists' : 'null');
      
      const lastLaunchTime = AppStorage.get<number>('lastLaunchTime') || 0;
      const currentTime = Date.now();
      console.info('[GamePage]   - 启动时间差: %{public}d ms', currentTime - lastLaunchTime);
      
      console.info('[GamePage] 🧹 开始清理残留数据（双数据源同步清除）...');
      
      // 🔥 关键：同时清除 AppStorage（内存）和 preferences（磁盘）
      AppStorage.setOrCreate('currentGameState', null);
      await GameStorage.clearGameState();
      
      console.info('[GamePage] ✅ 数据清理完成');
      
      // 🔥 立即更新所有卡片（显示"开始新游戏"）
      await this.updateAllFormsAfterClear();
      
      console.info('[GamePage] 🏠 返回主页');
      
      router.replaceUrl({
        url: 'pages/EntryPage'
      }).catch((err: Error) => {
        console.error('[GamePage] ❌ 返回主页失败:', err);
      });
      
      return;  // 阻止继续执行
    }

    // 监听屏幕状态变化
    this.screenManager.addListener((state: ScreenState) => {
      this.screenState = state;
      this.updateScreenSize();
    });
    this.screenState = this.screenManager.getCurrentState();
    this.updateScreenSize();

    // 注册自定义字体
    font.registerFont({
      familyName: 'Muyao-Softbrush',
      familySrc: `/resources/rawfile/${DesignConstants.CUSTOM_FONT_PATH}`
    });

    // 播放背景音乐
    this.playBackgroundMusic();

    // 初始化游戏
    await this.initGame();
    
    // 🔥 新增：检查是否有卡片跳转请求
    this.checkWidgetNavigation();
  }
  
  // 更新实际屏幕尺寸
  private updateScreenSize(): void {
    const displayClass = display.getDefaultDisplaySync();
    this.actualWidth = displayClass.width;
    this.actualHeight = displayClass.height;
    console.info(`[GamePage] 实际屏幕尺寸: ${this.actualWidth}×${this.actualHeight}`);
  }
  
  /**
   * 根据来源播放对应的背景音乐
   */
  private playBackgroundMusic(): void {
    let musicPath = '';
    
    if (this.source === 'network' || this.source === 'gallery') {
      // 网络随机或相册上传
      musicPath = 'music/网络与相册.mp3';
    } else if (this.source === 'bangbu') {
      // 邦布专辑
      musicPath = 'music/邦布.mp3';
    } else if (this.source === 'character') {
      // 角色专辑：根据 characterId 选择音乐
      if (this.characterId === 'laite') {
        musicPath = 'music/莱特.mp3';
      } else if (this.characterId === 'weiweian') {
        musicPath = 'music/薇薇安.mp3';
      }
    }
    
    if (musicPath) {
      audioManager.playBGM(musicPath);
      console.info(`[GamePage] 播放背景音乐: ${musicPath}`);
    }
  }

  /**
   * 实时保存当前游戏状态
   * 🔥 强硬手段：同时保存到 AppStorage（内存，立即生效）和 preferences（持久化，异步）
   */
  private saveCurrentGameState(): void {
    if (this.isPlaying && (this.moveCount > 0 || this.timeElapsed > 0)) {
      // 🔥 使用显式类型声明，符合 ArkTS 规范
      const gameState: SavedGameState = {
        gameMode: this.gameMode,
        gridSize: this.gridSize,
        moveCount: this.moveCount,
        timeElapsed: this.timeElapsed,
        isPlaying: this.isPlaying,
        timestamp: Date.now()  // 🔥 添加时间戳，用于过期检测
      };
      
      // 🔥 关键1：立即同步到 AppStorage（内存，零延迟）
      AppStorage.setOrCreate('currentGameState', gameState);
      console.info('[GamePage] ⚡ AppStorage已更新: 步数=' + this.moveCount + ', 用时=' + this.timeElapsed);
      
      // 🔥 关键2：异步保存到 preferences（持久化备份）
      GameStorage.saveGameState(gameState);
    }
  }

  aboutToDisappear() {
    // 页面销毁时再次保存（确保状态最新）
    this.saveCurrentGameState();

    // 清理定时器
    if (this.timerInterval !== -1) {
      clearInterval(this.timerInterval);
    }

    // 移除监听器
    this.screenManager.removeListener((state: ScreenState) => {
      this.screenState = state;
    });
  }
  
  // 🔥 新增：页面显示时检查卡片跳转
  onPageShow() {
    console.info('[GamePage] 📺 页面显示，检查卡片跳转请求...');
    this.checkWidgetNavigation();
    
    // 确保音乐播放
    audioManager.resumeBGM();
  }
  
  // 🔥 新增方法：检查并处理卡片跳转（带时间戳校验）
  private checkWidgetNavigation(): void {
    // 只处理新的跳转请求（通过时间戳判断，避免重复跳转）
    if (this.widgetTargetPage && 
        this.widgetTargetPageTimestamp > 0 && 
        this.widgetTargetPageTimestamp !== this.lastProcessedTimestamp) {
      
      console.info(`[GamePage] 🎯 检测到卡片跳转请求:`);
      console.info(`[GamePage]   - 目标页面: ${this.widgetTargetPage}`);
      console.info(`[GamePage]   - 请求时间戳: ${this.widgetTargetPageTimestamp}`);
      console.info(`[GamePage]   - 上次处理时间戳: ${this.lastProcessedTimestamp}`);
      
      // 如果目标页面不是当前页面，则跳转
      if (this.widgetTargetPage !== 'pages/GamePage') {
        console.info(`[GamePage] 🚀 执行跳转到: ${this.widgetTargetPage}`);
        
        // 🔥 关键：先用局部变量保存目标页面（防止清空AppStorage后丢失）
        const targetPageToNavigate = this.widgetTargetPage;
        
        // 🔥 官方建议：记录已处理的时间戳
        this.lastProcessedTimestamp = this.widgetTargetPageTimestamp;
        
        // 清除标记，避免重复跳转
        AppStorage.setOrCreate('widgetTargetPage', '');
        AppStorage.setOrCreate('widgetTargetPageTimestamp', 0);
        
        // 执行跳转（延迟确保页面完全加载）
        setTimeout(() => {
          router.pushUrl({
            url: targetPageToNavigate
          }).then(() => {
            console.info(`[GamePage] ✅ 跳转成功: ${targetPageToNavigate}`);
          }).catch((err: Error) => {
            console.error(`[GamePage] ❌ 跳转失败: ${err.message}`);
          });
        }, 100);
      } else {
        console.info(`[GamePage] ℹ️ 目标页面是当前页面，忽略跳转`);
        // 记录已处理并清除标记
        this.lastProcessedTimestamp = this.widgetTargetPageTimestamp;
        AppStorage.setOrCreate('widgetTargetPage', '');
        AppStorage.setOrCreate('widgetTargetPageTimestamp', 0);
      }
    } else {
      console.info('[GamePage] ℹ️ 无待处理的卡片跳转请求');
    }
  }

  // 初始化游戏
  private async initGame(): Promise<void> {
    try {
      console.info('[GamePage] 开始初始化游戏');
      console.info(`[GamePage] isNetworkImage: ${this.isNetworkImage}, isCustomImage: ${this.isCustomImage}`);
      console.info(`[GamePage] useCachedImage: ${this.useCachedImage}`);
      console.info(`[GamePage] imageResource: ${this.imageResource}`);
      
      // 加载图片
      let pixelMap: image.PixelMap;
      
      // 优先检查是否使用缓存的裁剪后图片
      if (this.useCachedImage && ImageCache.has()) {
        console.info('[GamePage] ✅ 使用缓存的裁剪后图片（所见即所得）');
        pixelMap = ImageCache.get()!;
        console.info('[GamePage] 缓存图片获取成功');
      } else if (this.isNetworkImage && typeof this.imageResource === 'string') {
        // 网络图片
        console.info('[GamePage] 加载网络图片:', this.imageResource);
        pixelMap = await UriConverter.urlToPixelMap(this.imageResource);
        console.info('[GamePage] 网络图片加载成功');
      } else if (this.isCustomImage && typeof this.imageResource === 'string') {
        // 相册图片或rawfile图片
        if (this.imageResource.startsWith('file://') || this.imageResource.startsWith('content://')) {
          console.info('[GamePage] 加载相册图片:', this.imageResource);
        pixelMap = await UriConverter.uriToPixelMap(this.imageResource);
          console.info('[GamePage] 相册图片加载成功');
        } else if (this.imageResource.startsWith('http://') || this.imageResource.startsWith('https://')) {
          // 如果是http开头但被标记为customImage，按网络图片处理
          console.info('[GamePage] 加载网络图片(标记为custom):', this.imageResource);
          pixelMap = await UriConverter.urlToPixelMap(this.imageResource);
          console.info('[GamePage] 网络图片加载成功');
        } else {
          // rawfile路径
          console.info('[GamePage] 加载rawfile图片:', this.imageResource);
          pixelMap = await UriConverter.rawfileToPixelMap(this.imageResource);
          console.info('[GamePage] rawfile图片加载成功');
        }
      } else {
        // 预设图片
        console.info('[GamePage] 加载预设图片');
        pixelMap = await UriConverter.resourceToPixelMap(this.imageResource as Resource);
        console.info('[GamePage] 预设图片加载成功');
      }

      console.info('[GamePage] 图片加载完成，开始切割');
      this.originalPixelMap = pixelMap;

      // 切割图片（根据游戏模式决定是否创建空格）
      const createEmpty = (this.gameMode === GameConstants.GAME_MODE.HUARONG);
      const tilesData = await ImageSlicer.sliceImage(pixelMap, this.gridSize, createEmpty);
      this.tiles = tilesData;
      this.emptyIndex = this.gridSize * this.gridSize - 1;
      
      console.info(`[GamePage] 图片切割完成，共 ${this.tiles.length} 个方块`);

      // 显示完整拼图1秒后开始洗牌
      setTimeout(() => {
        this.shuffleWithAnimation();
      }, 1000);

    } catch (error) {
      console.error('[GamePage] 初始化游戏失败:', error);
      console.error('[GamePage] 错误详情:', JSON.stringify(error));
      
      // 可以在这里添加用户提示
      // 比如使用Toast或Dialog告知用户图片加载失败
    }
  }

  // 带动画的洗牌
  private shuffleWithAnimation(): void {
    if (this.gameMode === GameConstants.GAME_MODE.HUARONG) {
      // 华容道模式：使用传统洗牌
      const result = ShuffleHelper.shuffle(this.tiles, this.gridSize);
      
      animateTo({
        duration: GameConstants.ANIMATION_DURATION.TILE_MOVE,
        curve: Curve.EaseOut
      }, () => {
        this.tiles = result.tiles;
        this.emptyIndex = result.emptyIndex;
      });
    } else {
      // 交换模式：完全随机打乱
      const shuffledTiles = ShuffleHelper.shuffleForSwapMode(this.tiles, this.gridSize);
      
      animateTo({
        duration: GameConstants.ANIMATION_DURATION.TILE_MOVE,
        curve: Curve.EaseOut
      }, () => {
        this.tiles = shuffledTiles;
      });
    }

    // 洗牌完成后开始计时
    setTimeout(() => {
      this.startTimer();
    }, GameConstants.ANIMATION_DURATION.TILE_MOVE);
  }

  // 开始计时
  private startTimer(): void {
    this.isPlaying = true;
    this.timerInterval = setInterval(() => {
      if (this.isPlaying) {
        this.timeElapsed++;
        // 每秒保存一次状态，确保时间也能实时同步到卡片
        this.saveCurrentGameState();
      }
    }, 1000);
  }

  // 点击方块
  private onTileClick(index: number): void {
    if (!this.isPlaying) return;
    if (this.tiles[index].isEmpty) return;
    
    // 交换模式：固定的提示方块不能被点击
    if (this.gameMode === GameConstants.GAME_MODE.SWAP && this.tiles[index].isHint) {
      return;
    }

    if (this.gameMode === GameConstants.GAME_MODE.HUARONG) {
      // 华容道模式：检查是否相邻
      if (ShuffleHelper.isAdjacent(index, this.emptyIndex, this.gridSize)) {
        this.moveTile(index);
      }
    } else {
      // 交换模式：选择方块用于交换
      if (this.selectedTileIndex === -1) {
        this.selectedTileIndex = index;
      } else {
        if (this.selectedTileIndex !== index) {
          this.swapTiles(this.selectedTileIndex, index);
        }
        this.selectedTileIndex = -1;
      }
    }
  }

  // 交换两个方块（交换模式）
  private swapTiles(index1: number, index2: number): void {
    // 检查是否为固定的提示方块
    if (this.tiles[index1].isHint || this.tiles[index2].isHint) {
      return;
    }
    
    SoundService.playMoveSound();

    animateTo({
      duration: GameConstants.ANIMATION_DURATION.TILE_MOVE,
      curve: Curve.EaseOut
    }, () => {
      const temp = this.tiles[index1];
      this.tiles[index1] = this.tiles[index2];
      this.tiles[index2] = temp;

      this.tiles[index1].currentIndex = index1;
      this.tiles[index2].currentIndex = index2;

      this.moveCount++;
      
      // 🔥 关键：每次移动后立即保存状态，确保按Home键时能读取到最新进度
      this.saveCurrentGameState();
    });

    setTimeout(() => {
      this.checkWin();
    }, GameConstants.ANIMATION_DURATION.TILE_MOVE);
  }


  // 移动方块
  private moveTile(index: number): void {
    SoundService.playMoveSound();

    animateTo({
      duration: GameConstants.ANIMATION_DURATION.TILE_MOVE,
      curve: Curve.EaseOut
    }, () => {
      const temp = this.tiles[index];
      this.tiles[index] = this.tiles[this.emptyIndex];
      this.tiles[this.emptyIndex] = temp;

      this.tiles[index].currentIndex = index;
      this.tiles[this.emptyIndex].currentIndex = this.emptyIndex;

      this.emptyIndex = index;
      this.moveCount++;
      
      // 🔥 关键：每次移动后立即保存状态，确保按Home键时能读取到最新进度
      this.saveCurrentGameState();
    });

    setTimeout(() => {
      this.checkWin();
    }, GameConstants.ANIMATION_DURATION.TILE_MOVE);
  }

  // 检查胜利
  private checkWin(): void {
    if (WinChecker.checkWin(this.tiles)) {
      this.isPlaying = false;
      clearInterval(this.timerInterval);

      GameStorage.saveBestRecord(this.gridSize, this.moveCount, this.timeElapsed);
      GameStorage.clearGameState();
      
      // 🔥 清除 AppStorage 中的游戏状态
      AppStorage.delete('currentGameState');
      console.info('[GamePage] 🏆 游戏完成，已清除状态');

      this.playWinAnimation();
    }
  }

  // 胜利动画
  private playWinAnimation(): void {
    SoundService.playWinSound();

    animateTo({
      duration: GameConstants.ANIMATION_DURATION.WIN,
      curve: Curve.EaseInOut
    }, () => {
      this.gridGap = 0;
    });

    setTimeout(() => {
      this.winDialogController = new CustomDialogController({
        builder: WinDialog({
          moveCount: this.moveCount,
          timeElapsed: this.timeElapsed,
          onPlayAgain: () => {
            this.restartGame();
          },
          onBackHome: () => {
            this.goBackHome();
          }
        }),
        autoCancel: false,
        customStyle: true
      });
      this.winDialogController.open();
    }, GameConstants.ANIMATION_DURATION.WIN);
  }

  // 重新开始
  private restartGame(): void {
    this.moveCount = 0;
    this.timeElapsed = 0;
    this.gridGap = GameConstants.GRID_GAP;
    this.isPeeking = false;
    this.isPlaying = false;
    this.selectedTileIndex = -1;  // 清除选中状态
    this.resetDragState();  // 清除拖拽状态
    
    if (this.timerInterval !== -1) {
      clearInterval(this.timerInterval);
    }

    // 🔥 清除游戏状态（AppStorage + preferences）
    AppStorage.delete('currentGameState');
    GameStorage.clearGameState();
    console.info('[GamePage] 🔄 重新开始，已清除旧状态');

    // 重新初始化游戏（重新切割并洗牌，重新生成isHint）
    this.initGame();
  }

  // 重置拖拽状态
  private resetDragState(): void {
    this.draggedTileIndex = -1;
    this.isDragging = false;
    this.dragOffsetX = 0;
    this.dragOffsetY = 0;
  }

  // 根据拖拽坐标计算目标方块索引
  private calculateDropIndex(absoluteX: number, absoluteY: number): number {
    console.info(`[calculateDropIndex] ========== 开始计算目标索引 ==========`);
    console.info(`[calculateDropIndex] 输入坐标: (${absoluteX}, ${absoluteY})`);
    
    // 优先使用动态获取的Grid位置
    let puzzleX = this.gridPositionX;
    let puzzleY = this.gridPositionY;
    let puzzleSize = this.gridActualSize;
    
    // 如果还未获取到Grid位置（首次拖拽前），使用硬编码的备用值
    if (puzzleSize === 0) {
      console.warn(`[calculateDropIndex] ⚠️ Grid位置尚未获取，使用硬编码备用值`);
      if (this.screenState === ScreenState.TRIPLE) {
        puzzleX = 92;
        puzzleY = 73;
        puzzleSize = 630;
      } else if (this.screenState === ScreenState.DOUBLE) {
        puzzleX = 107;
        puzzleY = 52;
        puzzleSize = 494;
      } else {
        puzzleX = 115;
        puzzleY = 15;
        puzzleSize = 313;
      }
      console.info(`[calculateDropIndex] 备用值 - 屏幕状态: ${this.screenState}`);
    } else {
      console.info(`[calculateDropIndex] ✅ 使用动态获取的Grid位置`);
    }
    
    console.info(`[calculateDropIndex] Grid区域: X=${puzzleX}, Y=${puzzleY}, Size=${puzzleSize}`);
    console.info(`[calculateDropIndex] 网格尺寸: ${this.gridSize}×${this.gridSize}`);

    // 计算相对于拼图区域的坐标
    const relativeX = absoluteX - puzzleX;
    const relativeY = absoluteY - puzzleY;
    
    console.info(`[calculateDropIndex] 相对坐标: (${relativeX}, ${relativeY})`);

    // 检查是否在拼图区域内
    if (relativeX < 0 || relativeY < 0 || relativeX > puzzleSize || relativeY > puzzleSize) {
      console.warn(`[calculateDropIndex] ❌ 坐标超出拼图区域！`);
      console.warn(`[calculateDropIndex] 检查: X范围[0, ${puzzleSize}], 实际=${relativeX}`);
      console.warn(`[calculateDropIndex] 检查: Y范围[0, ${puzzleSize}], 实际=${relativeY}`);
      return -1;
    }

    // 计算每个方块的尺寸（包括间隙）
    const tileSize = puzzleSize / this.gridSize;
    console.info(`[calculateDropIndex] 单个方块尺寸: ${tileSize}vp`);
    
    // 计算行列
    const col = Math.floor(relativeX / tileSize);
    const row = Math.floor(relativeY / tileSize);
    
    console.info(`[calculateDropIndex] 计算的行列: row=${row}, col=${col}`);
    
    // 确保在有效范围内
    if (col >= this.gridSize || row >= this.gridSize) {
      console.warn(`[calculateDropIndex] ❌ 行列超出范围！`);
      return -1;
    }

    const index = row * this.gridSize + col;
    console.info(`[calculateDropIndex] ✅ 计算出的索引: ${index}`);
    console.info(`[calculateDropIndex] ========== 计算完成 ==========`);
    return index;
  }

  // 切换模式
  private async toggleMode(): Promise<void> {
    this.gameMode = this.gameMode === GameConstants.GAME_MODE.HUARONG ? 
      GameConstants.GAME_MODE.SWAP : GameConstants.GAME_MODE.HUARONG;
    
    // 停止当前游戏
    this.isPlaying = false;
    if (this.timerInterval !== -1) {
    clearInterval(this.timerInterval);
    }

    // 重新初始化游戏
    this.moveCount = 0;
    this.timeElapsed = 0;
    this.gridGap = GameConstants.GRID_GAP;
    this.isPeeking = false;

    // 重新切割并洗牌
    if (this.originalPixelMap) {
      try {
        const createEmpty = (this.gameMode === GameConstants.GAME_MODE.HUARONG);
        const tilesData = await ImageSlicer.sliceImage(this.originalPixelMap, this.gridSize, createEmpty);
        this.tiles = tilesData;
        this.emptyIndex = this.gridSize * this.gridSize - 1;

        // 延迟后洗牌
        setTimeout(() => {
          this.shuffleWithAnimation();
        }, 500);
      } catch (error) {
        console.error('重新切割图片失败:', error);
      }
    }
  }

  // 切换难度
  private changeDifficulty(newDifficulty: number): void {
    if (newDifficulty !== this.gridSize) {
      this.gridSize = newDifficulty;
      this.initGame();
    }
  }

  // 偷看答案
  private togglePeek(): void {
    if (!this.isPeeking) {
      // 开始偷看 - 保存当前打乱的状态
      this.isPeeking = true;
      
      console.info('[GamePage] 偷看答案 - 保存当前状态');
      
      // 深拷贝保存当前的tiles状态（包括打乱的顺序和isHint状态）
      this.savedTilesBeforePeek = this.tiles.map(tile => 
        new TileData(tile.id, tile.currentIndex, tile.pixelMap, tile.isEmpty, tile.isHint)
      );
      
      // 保存空格位置
      this.savedEmptyIndexBeforePeek = this.emptyIndex;
      
      console.info(`[GamePage] 已保存 ${this.savedTilesBeforePeek.length} 个方块的状态`);
      
      // 暂停游戏
      this.isPlaying = false;

      // 显示答案
    animateTo({
      duration: GameConstants.ANIMATION_DURATION.TILE_MOVE,
      curve: Curve.EaseOut
    }, () => {
      this.tiles = WinChecker.restoreAnswer(this.tiles);
      this.emptyIndex = this.gridSize * this.gridSize - 1;
      this.gridGap = 0;
    });
    } else {
      // 回归作答 - 恢复之前保存的打乱状态
      this.isPeeking = false;
      
      console.info('[GamePage] 回归作答 - 恢复之前的打乱状态');
      
      animateTo({
        duration: GameConstants.ANIMATION_DURATION.TILE_MOVE,
        curve: Curve.EaseOut
      }, () => {
        // 恢复保存的tiles打乱状态（包括isHint状态）
        if (this.savedTilesBeforePeek.length > 0) {
          this.tiles = this.savedTilesBeforePeek.map(tile => 
            new TileData(tile.id, tile.currentIndex, tile.pixelMap, tile.isEmpty, tile.isHint)
          );
          
          // 恢复空格位置
          this.emptyIndex = this.savedEmptyIndexBeforePeek;
          
          console.info(`[GamePage] 已恢复 ${this.tiles.length} 个方块的打乱状态`);
        } else {
          console.warn('[GamePage] 警告：没有保存的状态可恢复');
        }
        
        // 恢复间隙
        this.gridGap = GameConstants.GRID_GAP;
      });
      
      // 恢复游戏
      this.isPlaying = true;
    }
  }

  // 返回上一级页面
  private goBackHome(): void {
    router.back();
  }

  // 格式化时间
  private formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  // 拼图区域（辅助Builder，接受尺寸和位置参数）
  @Builder
  puzzleAreaBuilder(width: number, height: number, x: number, y: number) {
    Stack() {
      // 拼图网格
      Grid() {
        ForEach(this.tiles, (tile: TileData, index: number) => {
          GridItem() {
            if (tile.isEmpty) {
              // 空格
              Column()
                .width('100%')
                .height('100%')
                .backgroundColor(GameConstants.COLORS.EMPTY_BG)
            } else {
              // 方块
              Stack() {
                // 方块图片
                if (tile.pixelMap) {
                  Image(tile.pixelMap)
                    .width('100%')
                    .height('100%')
                    .objectFit(ImageFit.Fill)
                    .draggable(false)  // 禁用系统拖拽，避免拦截PanGesture
                }

                // 华容道模式：数字标记
                if (this.gameMode === GameConstants.GAME_MODE.HUARONG) {
                  Text(`${tile.id + 1}`)
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF')
                    .textShadow({ radius: 4, color: '#000000', offsetX: 0, offsetY: 0 })
                    .backgroundColor('rgba(0, 0, 0, 0.6)')
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .borderRadius(8)
                    .position({ x: 8, y: 8 })
                }

                // 交换模式：提示方块遮罩（黑色阴影，无描边）
                if (this.gameMode === GameConstants.GAME_MODE.SWAP && tile.isHint) {
                  Column()
                    .width('100%')
                    .height('100%')
                    .backgroundColor('rgba(0, 0, 0, 0.55)')
                }

                // 交换模式：选中状态指示
                if (this.gameMode === GameConstants.GAME_MODE.SWAP && this.selectedTileIndex === index) {
                  Column()
                    .width('100%')
                    .height('100%')
                    .backgroundColor('rgba(24, 144, 255, 0.3)')
                    .border({ width: 3, color: '#24FF00' })
                }

                // 拖拽中的视觉效果
                if (this.isDragging && this.draggedTileIndex === index) {
                  Column()
                    .width('100%')
                    .height('100%')
                    .backgroundColor('rgba(255, 255, 255, 0.5)')
                }
              }
              .width('100%')
              .height('100%')
              .backgroundColor(GameConstants.COLORS.TILE_BG)
              .opacity(this.isDragging && this.draggedTileIndex === index ? 0.3 : 1)  // 拖拽时原位置半透明占位
              .onClick(() => {
                this.onTileClick(index);
              })
              // 交换模式：添加拖拽手势支持（使用PanGesture，parallel模式与点击共存）
              .parallelGesture(
                PanGesture({ distance: 5, fingers: 1 })
                  .onActionStart((event: GestureEvent) => {
                    // 只在交换模式且非提示方块时响应
                    if (this.isPlaying && this.gameMode === GameConstants.GAME_MODE.SWAP && !tile.isHint) {
                      console.info(`[GamePage] ========== 开始拖拽方块 ${index} ==========`);
                      this.draggedTileIndex = index;
                      this.isDragging = true;
                      // 记录起始位置（全局坐标）
                      this.dragStartX = event.fingerList[0].globalX;
                      this.dragStartY = event.fingerList[0].globalY;
                      console.info(`[GamePage] 起始坐标: globalX=${this.dragStartX}, globalY=${this.dragStartY}`);
                      console.info(`[GamePage] 起始坐标: localX=${event.fingerList[0].localX}, localY=${event.fingerList[0].localY}`);
                    }
                  })
                  .onActionUpdate((event: GestureEvent) => {
                    // 只在拖拽状态下更新偏移量
                    if (this.isDragging && this.gameMode === GameConstants.GAME_MODE.SWAP) {
                      // 更新拖拽偏移量
                      this.dragOffsetX = event.offsetX;
                      this.dragOffsetY = event.offsetY;
                      // 实时输出坐标（用于调试）
                      if (Math.abs(this.dragOffsetX) > 10 || Math.abs(this.dragOffsetY) > 10) {
                        const currentX = this.dragStartX + this.dragOffsetX;
                        const currentY = this.dragStartY + this.dragOffsetY;
                        console.debug(`[GamePage] 拖拽中: offset=(${event.offsetX}, ${event.offsetY}), current=(${currentX}, ${currentY})`);
                      }
                    }
                  })
                  .onActionEnd((event: GestureEvent) => {
                    // 处理拖拽结束
                    if (this.isDragging && this.gameMode === GameConstants.GAME_MODE.SWAP) {
                      // 使用最终的globalX/globalY而不是起始+偏移
                      const endX = event.fingerList[0].globalX;
                      const endY = event.fingerList[0].globalY;
                      
                      console.info(`[GamePage] ========== 拖拽结束 ==========`);
                      console.info(`[GamePage] 结束坐标: globalX=${endX}, globalY=${endY}`);
                      console.info(`[GamePage] 结束坐标: localX=${event.fingerList[0].localX}, localY=${event.fingerList[0].localY}`);
                      console.info(`[GamePage] 总偏移: offsetX=${event.offsetX}, offsetY=${event.offsetY}`);
                      console.info(`[GamePage] 屏幕状态: ${this.screenState}, 实际尺寸: ${this.actualWidth}×${this.actualHeight}`);
                      
                      // 计算目标方块索引
                      const targetIndex = this.calculateDropIndex(endX, endY);
                      
                      console.info(`[GamePage] 计算结果: 目标索引=${targetIndex}, 起始索引=${this.draggedTileIndex}`);
                      
                      if (targetIndex !== -1 && targetIndex !== this.draggedTileIndex && 
                          !this.tiles[targetIndex].isHint) {
                        console.info(`[GamePage] ✅ 执行交换: ${this.draggedTileIndex} <-> ${targetIndex}`);
                        this.swapTiles(this.draggedTileIndex, targetIndex);
                      } else {
                        if (targetIndex === -1) {
                          console.warn(`[GamePage] ❌ 拖拽取消: 坐标不在有效区域内`);
                        } else if (targetIndex === this.draggedTileIndex) {
                          console.warn(`[GamePage] ❌ 拖拽取消: 未移动到其他方块`);
                        } else if (this.tiles[targetIndex].isHint) {
                          console.warn(`[GamePage] ❌ 拖拽取消: 目标是固定提示方块`);
                        }
                      }
                      
                      // 清除拖拽状态
                      this.resetDragState();
                      console.info(`[GamePage] ========== 拖拽流程结束 ==========`);
                    } else if (this.isDragging) {
                      // 如果在其他模式下误触发了拖拽，重置状态
                      console.warn(`[GamePage] ⚠️ 非交换模式，重置拖拽状态`);
                      this.resetDragState();
                    }
                  })
              )
            }
          }
        })
      }
      .columnsTemplate('1fr '.repeat(this.gridSize).trim())
      .rowsTemplate('1fr '.repeat(this.gridSize).trim())
      .columnsGap(this.gridGap)
      .rowsGap(this.gridGap)
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')
      .clip(true)
      .onAreaChange((oldValue: Area, newValue: Area) => {
        // 动态获取Grid组件的实际位置和尺寸
        if (newValue.position && newValue.globalPosition && newValue.width) {
          this.gridPositionX = Number(newValue.globalPosition.x ?? 0);
          this.gridPositionY = Number(newValue.globalPosition.y ?? 0);
          this.gridActualSize = Number(newValue.width ?? 0);
          console.info(`[GamePage] Grid位置更新: X=${this.gridPositionX}, Y=${this.gridPositionY}, Size=${this.gridActualSize}`);
        }
      })
    }
    .width(width)
    .height(height)
    .borderRadius(25)
    .shadow({ 
      radius: 25,
      color: 'rgba(0, 0, 0, 0.25)',
      offsetX: 4,
      offsetY: 4
    })
    .position({ x: x, y: y })
  }

  // 三屏布局（所有参数写死）
  @Builder
  buildTripleLayout() {
    Stack() {
      // 背景图片
      Image($rawfile('images/其余页面背景图.png'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      // 拼图区域（写死）
      this.puzzleAreaBuilder(630, 630, 92, 73)

      // 返回按钮（写死）
      Button() {
        Image($rawfile('images/icon/返回.png'))
          .width(37)
          .height(35)
      }
      .width(60)
      .height(60)
      .backgroundColor('rgba(255, 255, 255, 0.9)')
      .borderRadius(30)
      .position({ x: 20, y: 21 })
      .onClick(() => {
        this.goBackHome();
      })

      // 主页按钮（写死）
      Button() {
        Image($rawfile('images/icon/主题.png'))
          .width(32)
          .height(32)
      }
      .width(60)
      .height(60)
      .backgroundColor('rgba(255, 255, 255, 0.9)')
      .borderRadius(30)
      .position({ x: 90, y: 21 })
      .onClick(() => {
        router.pushUrl({
          url: 'pages/ThemeSelectionPage'
        }).catch((err: Error) => {
          console.error('跳转失败:', err);
        });
      })

      // 声音控制按钮（右上角）
      SoundButton({ buttonSize: 60, iconSize: 32 })
        .position({ x: 1020, y: 21 })

      // 切换模式按钮（写死）
      Button() {
        Text(this.gameMode === GameConstants.GAME_MODE.HUARONG ? '华容道模式' : '交换模式')
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(287)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 0.91)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 769, y: 148 })
      .onClick(() => {
        this.toggleMode();
      })

      // 切换难度按钮（写死）
      Button() {
        Text(`难度 ${this.gridSize} × ${this.gridSize}`)
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(306)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 0.91)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 767, y: 283 })
      .onClick(() => {
        this.difficultyDialogController = new CustomDialogController({
          builder: DifficultyDialog({
            selectedDifficulty: this.gridSize,
            onDifficultySelected: (difficulty: number) => {
              this.changeDifficulty(difficulty);
            }
          }),
          autoCancel: true,
          customStyle: true
        });
        this.difficultyDialogController.open();
      })

      // 偷看答案/回归作答按钮（写死）
      Button() {
        Text(this.isPeeking ? '回归作答' : '偷看答案')
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(254)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 0.91)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 793, y: 418 })
      .onClick(() => {
        this.togglePeek();
      })

      // 重新开始按钮（写死）
      Button() {
        Text('重新开始')
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(254)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 0.91)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 793, y: 553 })
      .onClick(() => {
        this.restartGame();
      })
    }
    .width(1107)
    .height(776)
  }

  // 双屏布局（所有参数写死）
  @Builder
  buildDoubleLayout() {
    Stack() {
      // 背景图片
      Image($rawfile('images/其余页面背景图.png'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      // 拼图区域（写死）
      this.puzzleAreaBuilder(494, 475, 107, 52)

      // 返回按钮（写死）
      Button() {
        Image($rawfile('images/icon/返回.png'))
          .width(37)
          .height(35)
      }
      .width(60)
      .height(60)
      .backgroundColor('rgba(255, 255, 255, 0.9)')
      .borderRadius(30)
      .position({ x: 17, y: 22 })
      .onClick(() => {
        this.goBackHome();
      })

      // 主页按钮（写死）
      Button() {
        Image($rawfile('images/icon/主题.png'))
          .width(32)
          .height(32)
      }
      .width(60)
      .height(60)
      .backgroundColor('rgba(255, 255, 255, 0.9)')
      .borderRadius(30)
      .position({ x: 87, y: 22 })
      .onClick(() => {
        router.pushUrl({
          url: 'pages/ThemeSelectionPage'
        }).catch((err: Error) => {
          console.error('跳转失败:', err);
        });
      })

      // 声音控制按钮（右上角）
      SoundButton({ buttonSize: 60, iconSize: 32 })
        .position({ x: 625, y: 22 })

      // 切换模式按钮（写死）
      Button() {
        Text(this.gameMode === GameConstants.GAME_MODE.HUARONG ? '华容道模式' : '交换模式')
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(287)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 1)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 54, y: 556 })
      .onClick(() => {
        this.toggleMode();
      })

      // 切换难度按钮（写死）
      Button() {
        Text(`难度 ${this.gridSize} × ${this.gridSize}`)
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(287)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 1)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 372, y: 556 })
      .onClick(() => {
        this.difficultyDialogController = new CustomDialogController({
          builder: DifficultyDialog({
            selectedDifficulty: this.gridSize,
            onDifficultySelected: (difficulty: number) => {
              this.changeDifficulty(difficulty);
            }
          }),
          autoCancel: true,
          customStyle: true
        });
        this.difficultyDialogController.open();
      })

      // 偷看答案/回归作答按钮（写死）
      Button() {
        Text(this.isPeeking ? '回归作答' : '偷看答案')
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(254)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 1)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 70, y: 661 })
      .onClick(() => {
        this.togglePeek();
      })

      // 重新开始按钮（写死）
      Button() {
        Text('重新开始')
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(254)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 1)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 388, y: 661 })
      .onClick(() => {
        this.restartGame();
      })
    }
    .width(712)
    .height(776)
  }

  // 单屏布局（所有参数写死）
  @Builder
  buildSingleLayout() {
    Stack() {
      // 背景图片
      Image($rawfile('images/其余页面背景图.png'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      // 拼图区域（写死）
      this.puzzleAreaBuilder(313, 320, 115, 15)

      // 返回按钮（写死 - 注意单屏下尺寸不同）
      Button() {
        Image($rawfile('images/icon/返回.png'))
          .width(20)
          .height(17)
      }
      .width(35)
      .height(35)
      .backgroundColor('rgba(255, 255, 255, 0.9)')
      .borderRadius(17.5)
      .position({ x: 18, y: 11 })
      .onClick(() => {
        this.goBackHome();
      })

      // 主页按钮（写死）
      Button() {
        Image($rawfile('images/icon/主题.png'))
          .width(20)
          .height(20)
      }
      .width(35)
      .height(35)
      .backgroundColor('rgba(255, 255, 255, 0.9)')
      .borderRadius(17.5)
      .position({ x: 63, y: 11 })
      .onClick(() => {
        router.pushUrl({
          url: 'pages/ThemeSelectionPage'
        }).catch((err: Error) => {
          console.error('跳转失败:', err);
        });
      })

      // 声音控制按钮（右上角）
      SoundButton({ buttonSize: 35, iconSize: 20 })
        .position({ x: 723, y: 11 })

      // 切换模式按钮（写死）
      Button() {
        Text(this.gameMode === GameConstants.GAME_MODE.HUARONG ? '华容道模式' : '交换模式')
          .fontFamily('Muyao-Softbrush')
          .fontSize(35)
          .fontColor('#000000')
      }
      .width(206)
      .height(65)
      .backgroundColor('rgba(255, 255, 255, 1)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 503, y: 24 })
      .onClick(() => {
        this.toggleMode();
      })

      // 切换难度按钮（写死）
      Button() {
        Text(`难度 ${this.gridSize} × ${this.gridSize}`)
          .fontFamily('Muyao-Softbrush')
          .fontSize(35)
          .fontColor('#000000')
      }
      .width(206)
      .height(65)
      .backgroundColor('rgba(255, 255, 255, 1)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 503, y: 103 })
      .onClick(() => {
        this.difficultyDialogController = new CustomDialogController({
          builder: DifficultyDialog({
            selectedDifficulty: this.gridSize,
            onDifficultySelected: (difficulty: number) => {
              this.changeDifficulty(difficulty);
            }
          }),
          autoCancel: true,
          customStyle: true
        });
        this.difficultyDialogController.open();
      })

      // 偷看答案/回归作答按钮（写死）
      Button() {
        Text(this.isPeeking ? '回归作答' : '偷看答案')
          .fontFamily('Muyao-Softbrush')
          .fontSize(35)
          .fontColor('#000000')
      }
      .width(190)
      .height(65)
      .backgroundColor('rgba(255, 255, 255, 1)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 511, y: 182 })
      .onClick(() => {
        this.togglePeek();
      })

      // 重新开始按钮（写死）
      Button() {
        Text('重新开始')
          .fontFamily('Muyao-Softbrush')
          .fontSize(35)
          .fontColor('#000000')
      }
      .width(190)
      .height(65)
      .backgroundColor('rgba(255, 255, 255, 1)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 511, y: 261 })
      .onClick(() => {
        this.restartGame();
      })
    }
    .width(776)
    .height(350)
  }

  // 拖拽浮层：显示在整个屏幕最顶层
  @Builder
  buildDraggingOverlay() {
    if (this.draggedTileIndex >= 0 && this.draggedTileIndex < this.tiles.length) {
      Stack() {
        // 显示被拖拽的切片
        if (this.tiles[this.draggedTileIndex].pixelMap) {
          Image(this.tiles[this.draggedTileIndex].pixelMap)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Fill)
        }
        
        // 半透明白色遮罩
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(255, 255, 255, 0.3)')
      }
      .width(this.gridActualSize / this.gridSize)
      .height(this.gridActualSize / this.gridSize)
      .backgroundColor(GameConstants.COLORS.TILE_BG)
      .borderRadius(8)
      .opacity(0.85)
      .scale({ x: 1.1, y: 1.1 })
      .shadow({ 
        radius: 20,
        color: 'rgba(0, 0, 0, 0.5)',
        offsetX: 4,
        offsetY: 4
      })
      .position({ 
        x: (this.dragStartX + this.dragOffsetX) - (this.gridActualSize / this.gridSize) / 2,
        y: (this.dragStartY + this.dragOffsetY) - (this.gridActualSize / this.gridSize) / 2
      })
      .zIndex(9999)
    }
  }

  /**
   * 🔥 清除游戏状态后立即更新所有卡片
   */
  private async updateAllFormsAfterClear(): Promise<void> {
    try {
      console.info('[GamePage] 🔄 开始更新所有卡片（显示"开始新游戏"）');
      
      // 获取应用上下文
      const context = getContext(this) as common.UIAbilityContext;
      
      // 读取所有卡片ID
      const dataPreferences: preferences.Preferences = await preferences.getPreferences(context, 'formIds');
      const formIdsStr: string = await dataPreferences.get('ids', '[]') as string;
      const formIds: Array<string> = JSON.parse(formIdsStr);
      
      console.info('[GamePage] 📋 读取到 %{public}d 个卡片', formIds.length);
      
      if (formIds.length === 0) {
        console.warn('[GamePage] ⚠️ 没有已添加的卡片，跳过更新');
        return;
      }
      
      // 🔥 创建"开始新游戏"的卡片数据
      const formData: FormDataContent = {
        title: '拼图游戏',
        gameMode: '交换模式',
        gridSize: '3×3',
        moveCount: 0,
        timeElapsed: '00:00',
        hasActiveGame: false
      };
      
      // 🔥 更新所有卡片
      for (const formId of formIds) {
        try {
          await formProvider.updateForm(formId, formBindingData.createFormBindingData(formData));
          console.info('[GamePage] ✅ 卡片 %{public}s 更新成功', formId);
        } catch (error) {
          const err = error as Error;
          console.error('[GamePage] ❌ 卡片 %{public}s 更新失败: %{public}s', formId, err.message);
        }
      }
      
      console.info('[GamePage] ✅ 所有卡片更新完成');
    } catch (error) {
      const err = error as Error;
      console.error('[GamePage] ❌ 更新卡片过程出错: %{public}s', err.message);
    }
  }

  build() {
    Stack() {
      // 原有游戏布局
      Column() {
        if (this.screenState === ScreenState.TRIPLE) {
          this.buildTripleLayout()
        } else if (this.screenState === ScreenState.DOUBLE) {
          this.buildDoubleLayout()
        } else {
          this.buildSingleLayout()
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      
      // 拖拽浮层：覆盖整个屏幕，显示在最顶层
      if (this.isDragging) {
        this.buildDraggingOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }
}
