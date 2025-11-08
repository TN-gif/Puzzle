import { router, font, display } from '@kit.ArkUI';
import { picker } from '@kit.CoreFileKit';
import { ScreenState, ScreenStateManager } from '../utils/ScreenStateManager';
import { DesignConstants } from '../constants/DesignConstants';
import { NetworkImageSelector } from '../components/NetworkImageSelector';
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
 * 按钮位置配置接口
 */
interface ButtonPositions {
  character: Position;
  bangbu: Position;
  network: Position;
  gallery: Position;
  back: Position;
}

/**
 * 选择主题页面
 * 提供四种主题选择：角色专辑、邦布专辑、网络随机、相册上传
 */
@Entry
@Component
struct ThemeSelectionPage {
  @State screenState: ScreenState = ScreenState.TRIPLE;
  private screenManager: ScreenStateManager = ScreenStateManager.getInstance();
  
  // 实际屏幕尺寸（用于响应式缩放）
  @State actualWidth: number = 1107;
  @State actualHeight: number = 776;
  
  // 网络图片选择对话框
  private networkImageDialogController: CustomDialogController = new CustomDialogController({
    builder: NetworkImageSelector({
      onImageSelected: (imageUrl: string) => {
        // 跳转到图片选择页面
        this.navigateToImageSelection('network', '', imageUrl);
      }
    }),
    autoCancel: true,
    customStyle: true
  });

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
    console.info('[ThemeSelectionPage] 播放主题背景音乐');
  }
  
  // 更新实际屏幕尺寸
  private updateScreenSize(): void {
    const displayClass = display.getDefaultDisplaySync();
    this.actualWidth = displayClass.width;
    this.actualHeight = displayClass.height;
    console.info(`[ThemeSelectionPage] 实际屏幕尺寸: ${this.actualWidth}×${this.actualHeight}`);
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

  // 跳转到图片选择页面
  navigateToImageSelection(source: string, characterId: string = '', networkUrl: string = '', customUri: string = '') {
    router.pushUrl({
      url: 'pages/ImageSelectionPage',
      params: {
        source: source,           // 来源：character/bangbu/network/gallery
        characterId: characterId, // 角色ID（如果是角色专辑）
        networkUrl: networkUrl,   // 网络图片URL
        customUri: customUri      // 相册图片URI
      }
    }).catch((err: Error) => {
      console.error('跳转失败:', err);
    });
  }

  // 从相册选择图片
  async selectFromGallery(): Promise<void> {
    try {
      const photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.maxSelectNumber = 1;

      const photoPicker = new picker.PhotoViewPicker();
      const result = await photoPicker.select(photoSelectOptions);

      if (result && result.photoUris && result.photoUris.length > 0) {
        const customUri = result.photoUris[0];
        // 跳转到图片选择页面
        this.navigateToImageSelection('gallery', '', '', customUri);
      }
    } catch (error) {
      console.error('选择图片失败:', error);
    }
  }

  // 三屏布局（所有参数写死）
  @Builder
  buildTripleLayout() {
    Stack() {
      // 背景图片
      Image($rawfile('images/主题选择页面背景.jpg'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

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

      // 声音控制按钮（右上角）
      SoundButton({ buttonSize: 60, iconSize: 32 })
        .position({ x: 1020, y: 26 })

      // 角色专辑按钮（写死）
      Button() {
        Text('角色专辑')
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(254)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 0.91)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 41, y: 297 })
      .onClick(() => {
        router.pushUrl({
          url: 'pages/CharacterSelectionPage'
        }).catch((err: Error) => {
          console.error('跳转失败:', err);
        });
      })

      // 邦布专辑按钮（写死）
      Button() {
        Text('邦布专辑')
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(254)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 0.91)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 41, y: 412 })
      .onClick(() => {
        this.navigateToImageSelection('bangbu');
      })

      // 网络随机按钮（写死）
      Button() {
        Text('网络随机')
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(254)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 0.91)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 41, y: 527 })
      .onClick(() => {
        this.networkImageDialogController.open();
      })

      // 相册上传按钮（写死）
      Button() {
        Text('相册上传')
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(254)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 0.91)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 41, y: 642 })
      .onClick(() => {
        this.selectFromGallery();
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
      Image($rawfile('images/主题选择页面背景.jpg'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

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

      // 声音控制按钮（右上角）
      SoundButton({ buttonSize: 60, iconSize: 32 })
        .position({ x: 625, y: 22 })

      // 角色专辑按钮（写死 - 注意双屏下尺寸不同）
      Button() {
        Text('角色专辑')
          .fontFamily('Muyao-Softbrush')
          .fontSize(40)
          .fontColor('#000000')
      }
      .width(207)
      .height(68)
      .backgroundColor('rgba(255, 255, 255, 0.91)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 50, y: 316 })
      .onClick(() => {
        router.pushUrl({
          url: 'pages/CharacterSelectionPage'
        }).catch((err: Error) => {
          console.error('跳转失败:', err);
        });
      })

      // 邦布专辑按钮（写死）
      Button() {
        Text('邦布专辑')
          .fontFamily('Muyao-Softbrush')
          .fontSize(40)
          .fontColor('#000000')
      }
      .width(207)
      .height(68)
      .backgroundColor('rgba(255, 255, 255, 0.91)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 50, y: 421 })
      .onClick(() => {
        this.navigateToImageSelection('bangbu');
      })

      // 网络随机按钮（写死）
      Button() {
        Text('网络随机')
          .fontFamily('Muyao-Softbrush')
          .fontSize(40)
          .fontColor('#000000')
      }
      .width(207)
      .height(68)
      .backgroundColor('rgba(255, 255, 255, 0.91)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 50, y: 526 })
      .onClick(() => {
        this.networkImageDialogController.open();
      })

      // 相册上传按钮（写死）
      Button() {
        Text('相册上传')
          .fontFamily('Muyao-Softbrush')
          .fontSize(40)
          .fontColor('#000000')
      }
      .width(207)
      .height(68)
      .backgroundColor('rgba(255, 255, 255, 0.91)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 50, y: 631 })
      .onClick(() => {
        this.selectFromGallery();
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
      Image($rawfile('images/主题选择页面背景.jpg'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

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

      // 声音控制按钮（右上角）
      SoundButton({ buttonSize: 35, iconSize: 20 })
        .position({ x: 723, y: 11 })

      // 角色专辑按钮（写死）
      Button() {
        Text('角色专辑')
          .fontFamily('Muyao-Softbrush')
          .fontSize(35)
          .fontColor('#000000')
      }
      .width(174)
      .height(60)
      .backgroundColor('rgba(255, 255, 255, 0.91)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 42, y: 22 })
      .onClick(() => {
        router.pushUrl({
          url: 'pages/CharacterSelectionPage'
        }).catch((err: Error) => {
          console.error('跳转失败:', err);
        });
      })

      // 邦布专辑按钮（写死）
      Button() {
        Text('邦布专辑')
          .fontFamily('Muyao-Softbrush')
          .fontSize(35)
          .fontColor('#000000')
      }
      .width(174)
      .height(60)
      .backgroundColor('rgba(255, 255, 255, 0.91)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 42, y: 104 })
      .onClick(() => {
        this.navigateToImageSelection('bangbu');
      })

      // 网络随机按钮（写死）
      Button() {
        Text('网络随机')
          .fontFamily('Muyao-Softbrush')
          .fontSize(35)
          .fontColor('#000000')
      }
      .width(174)
      .height(60)
      .backgroundColor('rgba(255, 255, 255, 0.91)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 42, y: 185 })
      .onClick(() => {
        this.networkImageDialogController.open();
      })

      // 相册上传按钮（写死）
      Button() {
        Text('相册上传')
          .fontFamily('Muyao-Softbrush')
          .fontSize(35)
          .fontColor('#000000')
      }
      .width(174)
      .height(60)
      .backgroundColor('rgba(255, 255, 255, 0.91)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 42, y: 267 })
      .onClick(() => {
        this.selectFromGallery();
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

