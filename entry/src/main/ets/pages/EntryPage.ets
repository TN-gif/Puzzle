import { router, font } from '@kit.ArkUI';
import { ScreenState, ScreenStateManager } from '../utils/ScreenStateManager';
import { DesignConstants } from '../constants/DesignConstants';
import { audioManager } from '../utils/AudioManager';
import { SoundButton } from '../components/SoundButton';

/**
 * 位置接口
 */
interface Position {
  x: number;
  y: number;
}

/**
 * 进入页面
 * 应用启动后的第一个页面
 */
@Entry
@Component
struct EntryPage {
  @State screenState: ScreenState = ScreenState.TRIPLE;
  private screenManager: ScreenStateManager = ScreenStateManager.getInstance();
  
  // 自定义字体注册
  @State fontLoaded: boolean = false;
  
  // 🔥 监听卡片跳转请求
  @StorageProp('widgetTargetPage') widgetTargetPage: string = '';
  @StorageProp('widgetTargetPageTimestamp') widgetTargetPageTimestamp: number = 0;
  @State private lastProcessedTimestamp: number = 0;
  
  aboutToAppear() {
    // 监听屏幕状态变化
    this.screenManager.addListener((state: ScreenState) => {
      console.info(`[EntryPage] 🔔 屏幕状态变化: ${this.screenState} → ${state}`);
      this.screenState = state;
    });
    this.screenState = this.screenManager.getCurrentState();
    console.info(`[EntryPage] ✅ 初始屏幕状态: ${this.screenState}`);

    // 注册自定义字体
    font.registerFont({
      familyName: 'Muyao-Softbrush',
      familySrc: `/resources/rawfile/${DesignConstants.CUSTOM_FONT_PATH}`
    });
    this.fontLoaded = true;
    
    // 播放主题背景音乐
    audioManager.playBGM('music/主题背景音乐.mp3');
    console.info('[EntryPage] 开始播放主题背景音乐');
    
    // 🔥 检查是否有卡片跳转请求
    this.checkWidgetNavigation();
  }
  
  /**
   * 🔥 处理卡片跳转请求（官方建议：添加时间戳校验）
   */
  private checkWidgetNavigation(): void {
    // 🔥 官方建议：时间戳校验，避免重复跳转
    if (this.widgetTargetPage && 
        this.widgetTargetPageTimestamp > 0 && 
        this.widgetTargetPageTimestamp !== this.lastProcessedTimestamp) {
      
      console.info(`[EntryPage] 🎯 检测到卡片跳转请求:`);
      console.info(`[EntryPage]   - 目标页面: ${this.widgetTargetPage}`);
      console.info(`[EntryPage]   - 请求时间戳: ${this.widgetTargetPageTimestamp}`);
      
      // 🔥 关键：先用局部变量保存目标页面（防止清空AppStorage后丢失）
      const targetPageToNavigate = this.widgetTargetPage;
      
      // 记录已处理的时间戳
      this.lastProcessedTimestamp = this.widgetTargetPageTimestamp;
      
      // 清除标记，避免重复跳转
      AppStorage.setOrCreate('widgetTargetPage', '');
      AppStorage.setOrCreate('widgetTargetPageTimestamp', 0);
      
      // 执行跳转
      setTimeout(() => {
        router.pushUrl({
          url: targetPageToNavigate
        }).then(() => {
          console.info(`[EntryPage] ✅ 卡片跳转成功: ${targetPageToNavigate}`);
        }).catch((err: Error) => {
          console.error(`[EntryPage] ❌ 卡片跳转失败: ${err.message}`);
        });
      }, 100);
    }
  }
  
  /**
   * 监听 widgetTargetPageTimestamp 变化
   */
  onPageShow() {
    this.checkWidgetNavigation();
    
    // 确保音乐播放
    audioManager.resumeBGM();
  }

  aboutToDisappear() {
    // 移除监听器
    this.screenManager.removeListener((state: ScreenState) => {
      this.screenState = state;
    });
  }

  // 开始拼图按钮点击
  startPuzzle() {
    router.pushUrl({
      url: 'pages/ThemeSelectionPage'
    }).catch((err: Error) => {
      console.error('跳转失败:', err);
    });
  }

  // 三屏布局（所有参数写死）
  @Builder
  buildTripleLayout() {
    Stack() {
      // 背景图片
      Image($rawfile('images/主页面背景图.jpg'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      // 声音控制按钮（右上角）
      SoundButton({ buttonSize: 60, iconSize: 32 })
        .position({ x: 1020, y: 26 })

      // 开始拼图按钮（写死所有参数）
      Button() {
        Text('开始拼图')
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(254)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 0.91)')
      .borderRadius(25)
      .border({
        width: 4,
        color: Color.Transparent
      })
      .position({ x: 426, y: 652 })
      .onClick(() => {
        this.startPuzzle();
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
      Image($rawfile('images/主页面背景图.jpg'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      // 声音控制按钮（右上角）
      SoundButton({ buttonSize: 60, iconSize: 32 })
        .position({ x: 625, y: 22 })

      // 开始拼图按钮（写死所有参数）
      Button() {
        Text('开始拼图')
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(254)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 0.91)')
      .borderRadius(25)
      .border({
        width: 4,
        color: Color.Transparent
      })
      .position({ x: 229, y: 588 })
      .onClick(() => {
        this.startPuzzle();
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
      Image($rawfile('images/主页面背景图.jpg'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      // 声音控制按钮（右上角）
      SoundButton({ buttonSize: 35, iconSize: 20 })
        .position({ x: 723, y: 11 })

      // 开始拼图按钮（写死所有参数）
      Button() {
        Text('开始拼图')
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(254)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 0.91)')
      .borderRadius(25)
      .border({
        width: 4,
        color: Color.Transparent
      })
      .position({ x: 40, y: 138 })
      .onClick(() => {
        this.startPuzzle();
      })
    }
    .width(776)
    .height(350)
  }

  build() {
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
    .alignItems(HorizontalAlign.Center)
  }
}

