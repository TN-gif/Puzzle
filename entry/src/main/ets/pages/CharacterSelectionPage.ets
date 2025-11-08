import { router, font, display } from '@kit.ArkUI';
import { ScreenState, ScreenStateManager } from '../utils/ScreenStateManager';
import { DesignConstants } from '../constants/DesignConstants';
import { ImageAssets, CharacterInfo } from '../constants/ImageAssets';
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
interface ButtonPositions {
  select: Position;
  switch: Position;
  image: ImageSize;
  back: Position;
}

/**
 * 人物选择页面
 * 用于选择角色主题（莱特/薇薇安）
 */
@Entry
@Component
struct CharacterSelectionPage {
  @State screenState: ScreenState = ScreenState.TRIPLE;
  @State currentCharacterIndex: number = 0;  // 当前选择的角色索引
  private screenManager: ScreenStateManager = ScreenStateManager.getInstance();
  private characters: CharacterInfo[] = ImageAssets.CHARACTERS;
  
  // 实际屏幕尺寸（用于响应式缩放）
  @State actualWidth: number = 1107;
  @State actualHeight: number = 776;

  aboutToAppear() {
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
    
    // 播放主题背景音乐
    audioManager.playBGM('music/主题背景音乐.mp3');
    console.info('[CharacterSelectionPage] 播放主题背景音乐');
  }
  
  // 更新实际屏幕尺寸
  private updateScreenSize(): void {
    const displayClass = display.getDefaultDisplaySync();
    this.actualWidth = displayClass.width;
    this.actualHeight = displayClass.height;
    console.info(`[CharacterSelectionPage] 实际屏幕尺寸: ${this.actualWidth}×${this.actualHeight}`);
  }

  onPageShow() {
    // 确保音乐播放
    audioManager.resumeBGM();
  }

  aboutToDisappear() {
    this.screenManager.removeListener((state: ScreenState) => {
      this.screenState = state;
    });
  }

  // 切换人物（循环）
  switchCharacter() {
    this.currentCharacterIndex = (this.currentCharacterIndex + 1) % this.characters.length;
  }

  // 选择人物并进入图片选择页面
  selectCharacter() {
    const selectedCharacter = this.characters[this.currentCharacterIndex];
    router.pushUrl({
      url: 'pages/ImageSelectionPage',
      params: {
        source: 'character',
        characterId: selectedCharacter.id
      }
    }).catch((err: Error) => {
      console.error('跳转失败:', err);
    });
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

      // 角色显示图（写死）
      Image($rawfile(this.characters[this.currentCharacterIndex].displayImage))
        .width(852)
        .height(533)
        .objectFit(ImageFit.Contain)
        .borderRadius(25)
        .shadow({
          radius: 25,
          color: 'rgba(0, 0, 0, 0.25)',
          offsetX: 4,
          offsetY: 4
        })
        .position({ x: 127, y: 69 })

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
      .position({ x: 27, y: 26 })
      .onClick(() => {
        router.back();
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
      .position({ x: 97, y: 26 })
      .onClick(() => {
        router.pushUrl({
          url: 'pages/ThemeSelectionPage'
        }).catch((err: Error) => {
          console.error('跳转失败:', err);
        });
      })

      // 声音控制按钮（右上角）
      SoundButton({ buttonSize: 60, iconSize: 32 })
        .position({ x: 1020, y: 26 })

      // 选择人物按钮（写死）
      Button() {
        Text('选择人物')
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(254)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 1)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 239, y: 651 })
      .onClick(() => {
        this.selectCharacter();
      })

      // 切换人物按钮（写死）
      Button() {
        Text('切换人物')
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(254)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 1)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 613, y: 651 })
      .onClick(() => {
        this.switchCharacter();
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

      // 角色显示图（写死）
      Image($rawfile(this.characters[this.currentCharacterIndex].displayImage))
        .width(605)
        .height(399)
        .objectFit(ImageFit.Contain)
        .borderRadius(25)
        .shadow({
          radius: 25,
          color: 'rgba(0, 0, 0, 0.25)',
          offsetX: 4,
          offsetY: 4
        })
        .position({ x: 54, y: 112 })

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
        router.back();
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

      // 选择人物按钮（写死）
      Button() {
        Text('选择人物')
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(254)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 1)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 229, y: 544 })
      .onClick(() => {
        this.selectCharacter();
      })

      // 切换人物按钮（写死）
      Button() {
        Text('切换人物')
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(254)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 1)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 229, y: 655 })
      .onClick(() => {
        this.switchCharacter();
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

      // 角色显示图（写死）
      Image($rawfile(this.characters[this.currentCharacterIndex].displayImage))
        .width(432)
        .height(270)
        .objectFit(ImageFit.Contain)
        .borderRadius(25)
        .shadow({
          radius: 25,
          color: 'rgba(0, 0, 0, 0.25)',
          offsetX: 4,
          offsetY: 4
        })
        .position({ x: 77, y: 40 })

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
        router.back();
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

      // 选择人物按钮（写死）
      Button() {
        Text('选择人物')
          .fontFamily('Muyao-Softbrush')
          .fontSize(38)
          .fontColor('#000000')
      }
      .width(203)
      .height(67)
      .backgroundColor('rgba(255, 255, 255, 1)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 537, y: 91 })
      .onClick(() => {
        this.selectCharacter();
      })

      // 切换人物按钮（写死）
      Button() {
        Text('切换人物')
          .fontFamily('Muyao-Softbrush')
          .fontSize(38)
          .fontColor('#000000')
      }
      .width(203)
      .height(67)
      .backgroundColor('rgba(255, 255, 255, 1)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 537, y: 191 })
      .onClick(() => {
        this.switchCharacter();
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

