import { router } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { TileData } from '../models/TileData';
import { ImageSlicer } from '../utils/ImageSlicer';
import { ShuffleHelper } from '../utils/ShuffleHelper';
import { WinChecker } from '../utils/WinChecker';
import { UriConverter } from '../utils/UriConverter';
import { SoundService } from '../utils/SoundService';
import { GameStorage } from '../utils/GameStorage';
import { GameConstants } from '../constants/GameConstants';
import { WinDialog } from '../components/WinDialog';
import { mediaquery } from '@kit.ArkUI';

/**
 * 路由参数接口
 */
interface GamePageParams {
  gameMode: string;
  gridSize: number;
  imageResource: Resource | string;
  isCustomImage: boolean;
  isNetworkImage: boolean;
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
  @State isWideScreen: boolean = false;
  @State draggedTileIndex: number = -1;  // 拖拽的方块索引
  @State selectedTileIndex: number = -1; // 交换模式下选中的方块

  // 定时器
  private timerInterval: number = -1;
  private listener: mediaquery.MediaQueryListener | null = null;

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

  async aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as GamePageParams;

    if (params) {
      this.gameMode = params.gameMode || GameConstants.GAME_MODE.SWAP;
      this.gridSize = params.gridSize || 3;
      this.imageResource = params.imageResource;
      this.isCustomImage = params.isCustomImage || false;
      this.isNetworkImage = params.isNetworkImage || false;
    }

    // 初始化媒体查询
    this.initMediaQuery();

    // 初始化游戏
    await this.initGame();
  }

  aboutToDisappear() {
    // 保存游戏状态
    if (this.isPlaying) {
      GameStorage.saveGameState({
        gameMode: this.gameMode,
        gridSize: this.gridSize,
        moveCount: this.moveCount,
        timeElapsed: this.timeElapsed,
        isPlaying: this.isPlaying
      });
    }

    // 清理定时器
    if (this.timerInterval !== -1) {
      clearInterval(this.timerInterval);
    }

    // 清理媒体查询
    if (this.listener) {
      this.listener.off('change');
    }
  }

  // 初始化媒体查询（折叠屏适配）
  private initMediaQuery(): void {
    this.listener = mediaquery.matchMediaSync(`(min-width: ${GameConstants.BREAKPOINT_WIDTH}vp)`);
    this.listener.on('change', (result) => {
      this.isWideScreen = result.matches;
    });
    this.isWideScreen = this.listener.matches;
  }

  // 初始化游戏
  private async initGame(): Promise<void> {
    try {
      // 加载图片
      let pixelMap: image.PixelMap;
      if (this.isNetworkImage && typeof this.imageResource === 'string') {
        // 网络图片
        pixelMap = await UriConverter.urlToPixelMap(this.imageResource);
      } else if (this.isCustomImage && typeof this.imageResource === 'string') {
        // 相册图片
        pixelMap = await UriConverter.uriToPixelMap(this.imageResource);
      } else {
        // 预设图片
        pixelMap = await UriConverter.resourceToPixelMap(this.imageResource as Resource);
      }

      this.originalPixelMap = pixelMap;

      // 切割图片
      const tilesData = await ImageSlicer.sliceImage(pixelMap, this.gridSize);
      this.tiles = tilesData;
      this.emptyIndex = this.gridSize * this.gridSize - 1;

      // 显示完整拼图1秒后开始洗牌
      setTimeout(() => {
        this.shuffleWithAnimation();
      }, 1000);

    } catch (error) {
      console.error('初始化游戏失败:', error);
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
      }
    }, 1000);
  }

  // 点击方块
  private onTileClick(index: number): void {
    if (!this.isPlaying) return;
    if (this.tiles[index].isEmpty) return;

    if (this.gameMode === GameConstants.GAME_MODE.HUARONG) {
      // 华容道模式：检查是否相邻
      if (ShuffleHelper.isAdjacent(index, this.emptyIndex, this.gridSize)) {
        this.moveTile(index);
      }
    } else {
      // 交换模式：选择方块用于交换
      if (this.selectedTileIndex === -1) {
        // 第一次点击：选中方块
        this.selectedTileIndex = index;
      } else {
        // 第二次点击：交换方块
        if (this.selectedTileIndex !== index) {
          this.swapTiles(this.selectedTileIndex, index);
        }
        this.selectedTileIndex = -1;
      }
    }
  }

  // 交换两个方块（交换模式）
  private swapTiles(index1: number, index2: number): void {
    // 播放移动音效
    SoundService.playMoveSound();

    animateTo({
      duration: GameConstants.ANIMATION_DURATION.TILE_MOVE,
      curve: Curve.EaseOut
    }, () => {
      // 交换方块
      const temp = this.tiles[index1];
      this.tiles[index1] = this.tiles[index2];
      this.tiles[index2] = temp;

      // 更新currentIndex
      this.tiles[index1].currentIndex = index1;
      this.tiles[index2].currentIndex = index2;

      // 步数+1
      this.moveCount++;
    });

    // 检查胜利
    setTimeout(() => {
      this.checkWin();
    }, GameConstants.ANIMATION_DURATION.TILE_MOVE);
  }

  // 移动方块
  private moveTile(index: number): void {
    // 播放移动音效
    SoundService.playMoveSound();

    // 使用动画
    animateTo({
      duration: GameConstants.ANIMATION_DURATION.TILE_MOVE,
      curve: Curve.EaseOut
    }, () => {
      // 交换
      const temp = this.tiles[index];
      this.tiles[index] = this.tiles[this.emptyIndex];
      this.tiles[this.emptyIndex] = temp;

      // 更新索引
      this.tiles[index].currentIndex = index;
      this.tiles[this.emptyIndex].currentIndex = this.emptyIndex;

      // 更新空格位置
      this.emptyIndex = index;

      // 步数+1
      this.moveCount++;
    });

    // 检查胜利
    setTimeout(() => {
      this.checkWin();
    }, GameConstants.ANIMATION_DURATION.TILE_MOVE);
  }

  // 检查胜利
  private checkWin(): void {
    if (WinChecker.checkWin(this.tiles)) {
      this.isPlaying = false;
      clearInterval(this.timerInterval);

      // 保存最佳记录
      GameStorage.saveBestRecord(this.gridSize, this.moveCount, this.timeElapsed);

      // 清除当前游戏状态
      GameStorage.clearGameState();

      // 播放胜利动画
      this.playWinAnimation();
    }
  }

  // 胜利动画
  private playWinAnimation(): void {
    // 播放胜利音效
    SoundService.playWinSound();

    // 方块间隙逐渐消失
    animateTo({
      duration: GameConstants.ANIMATION_DURATION.WIN,
      curve: Curve.EaseInOut
    }, () => {
      this.gridGap = 0;
    });

    // 延迟显示对话框
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
    // 重置状态
    this.moveCount = 0;
    this.timeElapsed = 0;
    this.gridGap = GameConstants.GRID_GAP;
    
    // 清除定时器
    if (this.timerInterval !== -1) {
      clearInterval(this.timerInterval);
    }

    // 重新洗牌
    this.shuffleWithAnimation();
  }

  // 结束游戏（显示答案）
  private endGame(): void {
    this.isPlaying = false;
    clearInterval(this.timerInterval);

    animateTo({
      duration: GameConstants.ANIMATION_DURATION.TILE_MOVE,
      curve: Curve.EaseOut
    }, () => {
      this.tiles = WinChecker.restoreAnswer(this.tiles);
      this.emptyIndex = this.gridSize * this.gridSize - 1;
      this.gridGap = 0;
    });
  }

  // 返回主页
  private goBackHome(): void {
    try {
      router.back();
    } catch (err) {
      console.error('返回失败:', err);
    }
  }

  // 格式化时间
  private formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  // 拼图区域
  @Builder
  puzzleArea() {
    Stack() {
      // 底层原图（偷看功能）
      if (this.isPeeking && this.originalPixelMap) {
        Image(this.originalPixelMap)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .opacity(0.5)
      }

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
                // 图片
                if (tile.pixelMap) {
                  Image(tile.pixelMap)
                    .width('100%')
                    .height('100%')
                    .objectFit(ImageFit.Fill)
                }

                // 数字标记
                Text((tile.id + 1).toString())
                  .fontSize(16)
                  .fontColor(GameConstants.COLORS.TEXT_OVERLAY)
                  .fontWeight(FontWeight.Bold)
                  .padding(4)
                  .backgroundColor('rgba(0, 0, 0, 0.5)')
                  .borderRadius(4)
                  .margin(4)

                // 选中状态指示（交换模式）
                if (this.gameMode === GameConstants.GAME_MODE.SWAP && this.selectedTileIndex === index) {
                  Column()
                    .width('100%')
                    .height('100%')
                    .backgroundColor('rgba(24, 144, 255, 0.3)')
                    .border({ width: 3, color: GameConstants.COLORS.PRIMARY })
                }
              }
              .width('100%')
              .height('100%')
              .backgroundColor(GameConstants.COLORS.TILE_BG)
              .alignContent(Alignment.TopStart)
              .onClick(() => {
                this.onTileClick(index);
              })
              .gesture(
                // 拖拽手势（仅交换模式）
                GestureGroup(GestureMode.Exclusive,
                  LongPressGesture({ repeat: false, duration: 300 })
                    .onAction(() => {
                      if (this.gameMode === GameConstants.GAME_MODE.SWAP && this.isPlaying) {
                        this.draggedTileIndex = index;
                      }
                    })
                )
              )
              .onDragStart(() => {
                if (this.gameMode === GameConstants.GAME_MODE.SWAP && this.isPlaying) {
                  this.draggedTileIndex = index;
                }
              })
              .onDrop((event) => {
                if (this.gameMode === GameConstants.GAME_MODE.SWAP && 
                    this.draggedTileIndex !== -1 && 
                    this.draggedTileIndex !== index) {
                  this.swapTiles(this.draggedTileIndex, index);
                  this.draggedTileIndex = -1;
                }
              })
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
      .backgroundColor('#CCCCCC')
    }
    .width('90%')
    .aspectRatio(1.0)
    .borderRadius(8)
    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.1)' })
  }

  // 控制区域
  @Builder
  controlArea() {
    Column({ space: 16 }) {
      // 信息栏
      Row({ space: 20 }) {
        // 计时器
        Column({ space: 4 }) {
          Text('⏱️')
            .fontSize(20)
          Text(this.formatTime(this.timeElapsed))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(GameConstants.COLORS.TEXT)
        }

        // 步数
        Column({ space: 4 }) {
          Text('👣')
            .fontSize(20)
          Text(`${this.moveCount} 步`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(GameConstants.COLORS.TEXT)
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .padding(16)
      .backgroundColor(Color.White)
      .borderRadius(12)

      // 偷看按钮
      Button() {
        Row({ space: 8 }) {
          Text('👁️')
            .fontSize(20)
          Text(this.isPeeking ? '正在偷看...' : '偷看原图')
            .fontSize(16)
        }
      }
      .width('100%')
      .height(44)
      .backgroundColor(this.isPeeking ? '#FFE7BA' : Color.White)
      .fontColor(GameConstants.COLORS.TEXT)
      .border({ width: 1, color: '#FFA500' })
      .onTouch((event) => {
        if (event.type === TouchType.Down) {
          animateTo({
            duration: GameConstants.ANIMATION_DURATION.PEEK_FADE,
            curve: Curve.EaseInOut
          }, () => {
            this.isPeeking = true;
          });
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          animateTo({
            duration: GameConstants.ANIMATION_DURATION.PEEK_FADE,
            curve: Curve.EaseInOut
          }, () => {
            this.isPeeking = false;
          });
        }
      })

      // 模式切换按钮
      Button() {
        Row({ space: 8 }) {
          Text('🔄')
            .fontSize(18)
          Text(this.gameMode === GameConstants.GAME_MODE.HUARONG ? '切换到交换模式' : '切换到华容道模式')
            .fontSize(14)
        }
      }
      .width('100%')
      .height(40)
      .backgroundColor(Color.White)
      .fontColor(GameConstants.COLORS.PRIMARY)
      .border({ width: 1, color: GameConstants.COLORS.PRIMARY, style: BorderStyle.Dashed })
      .onClick(() => {
        // 切换模式
        this.gameMode = this.gameMode === GameConstants.GAME_MODE.HUARONG ? 
          GameConstants.GAME_MODE.SWAP : GameConstants.GAME_MODE.HUARONG;
        // 重新开始游戏
        this.restartGame();
      })

      // 控制按钮
      Row({ space: 12 }) {
        Button('重新开始')
          .layoutWeight(1)
          .height(44)
          .fontSize(16)
          .backgroundColor('#52C41A')
          .onClick(() => {
            this.restartGame();
          })

        Button('结束游戏')
          .layoutWeight(1)
          .height(44)
          .fontSize(16)
          .backgroundColor('#FF4D4F')
          .onClick(() => {
            this.endGame();
          })
      }
      .width('100%')

      // 返回主页按钮
      Button('返回主页')
        .width('100%')
        .height(44)
        .fontSize(16)
        .backgroundColor(Color.White)
        .fontColor(GameConstants.COLORS.PRIMARY)
        .border({ width: 1, color: GameConstants.COLORS.PRIMARY })
        .onClick(() => {
          this.goBackHome();
        })
    }
    .width('100%')
    .padding(16)
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Column({ space: 2 }) {
          Text('🧩 拼图游戏')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(GameConstants.COLORS.TEXT)
          
          Text(this.gameMode === GameConstants.GAME_MODE.HUARONG ? '华容道模式' : '自由交换模式')
            .fontSize(12)
            .fontColor('#999999')
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)
      .justifyContent(FlexAlign.Center)

      // 主体内容
      if (this.isWideScreen) {
        // 宽屏布局（横向）
        Row({ space: 16 }) {
          // 左侧：拼图区
          Column() {
            this.puzzleArea()
          }
          .layoutWeight(7)
          .justifyContent(FlexAlign.Center)

          // 右侧：控制区
          Column() {
            this.controlArea()
          }
          .layoutWeight(3)
        }
        .layoutWeight(1)
        .padding(16)
      } else {
        // 窄屏布局（纵向）
        Column({ space: 16 }) {
          // 上方：拼图区
          Column() {
            this.puzzleArea()
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)

          // 下方：控制区
          this.controlArea()
        }
        .layoutWeight(1)
        .padding(16)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(GameConstants.COLORS.BACKGROUND)
  }
}

