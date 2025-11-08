import { router, font, display } from '@kit.ArkUI';
import { picker } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { ScreenState, ScreenStateManager } from '../utils/ScreenStateManager';
import { DesignConstants } from '../constants/DesignConstants';
import { ImageAssets } from '../constants/ImageAssets';
import { NetworkImageSelector } from '../components/NetworkImageSelector';
import { UriConverter } from '../utils/UriConverter';
import { ImageCropper } from '../utils/ImageCropper';
import { ImageCache } from '../utils/ImageCache';
import { audioManager } from '../utils/AudioManager';
import { SoundButton } from '../components/SoundButton';

/**
 * 路由参数接口
 */
interface ImageSelectionParams {
  source: string;       // 来源：character/bangbu/network/gallery
  characterId?: string; // 角色ID
  networkUrl?: string;  // 网络图片URL
  customUri?: string;   // 相册图片URI
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
interface ButtonPositions {
  startGame: Position;
  action: Position;
  image: ImageSize;
  back: Position;
}

/**
 * 选择主题照片页面
 * 根据不同来源显示对应的图片选择界面
 */
@Entry
@Component
struct ImageSelectionPage {
  @State screenState: ScreenState = ScreenState.TRIPLE;
  @State source: string = '';
  @State characterId: string = '';
  @State networkUrl: string = '';
  @State customUri: string = '';
  @State currentImageIndex: number = 0;  // 当前选择的图片索引
  @State imageList: string[] = [];       // 当前可选图片列表
  
  // 网络图片相关状态
  @State networkPixelMap: image.PixelMap | null = null;  // 网络图片的PixelMap
  @State isLoadingNetworkImage: boolean = false;          // 是否正在加载网络图片
  @State networkImageLoadError: boolean = false;          // 网络图片加载失败
  
  private screenManager: ScreenStateManager = ScreenStateManager.getInstance();
  
  // 实际屏幕尺寸（用于响应式缩放）
  @State actualWidth: number = 1107;
  @State actualHeight: number = 776;
  
  // 网络图片选择对话框（初始创建，randomAgain中会重新创建）
  private networkImageDialogController: CustomDialogController = new CustomDialogController({
    builder: NetworkImageSelector({
      onImageSelected: (imageUrl: string) => {
        console.info('[ImageSelectionPage] 接收到网络图片URL:', imageUrl);
        this.networkUrl = imageUrl;
        console.info('[ImageSelectionPage] networkUrl已更新为:', this.networkUrl);
        // 立即加载网络图片
        this.loadNetworkImage(imageUrl);
      }
    }),
    autoCancel: true,
    customStyle: true
  });

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as ImageSelectionParams;
    if (params) {
      this.source = params.source || '';
      this.characterId = params.characterId || '';
      this.networkUrl = params.networkUrl || '';
      this.customUri = params.customUri || '';
      
      console.info('[ImageSelectionPage] 路由参数:', JSON.stringify({
        source: this.source,
        characterId: this.characterId,
        networkUrl: this.networkUrl,
        customUri: this.customUri
      }));
    }

    // 根据来源初始化图片列表
    this.initImageList();
    
    // 如果是网络图片，立即加载
    if (this.source === 'network' && this.networkUrl) {
      console.info('[ImageSelectionPage] 检测到网络图片，开始加载...');
      this.loadNetworkImage(this.networkUrl);
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
    
    // 根据来源播放对应的背景音乐
    this.playBackgroundMusic();
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
      console.info(`[ImageSelectionPage] 播放背景音乐: ${musicPath}`);
    }
  }
  
  // 更新实际屏幕尺寸
  private updateScreenSize(): void {
    const displayClass = display.getDefaultDisplaySync();
    this.actualWidth = displayClass.width;
    this.actualHeight = displayClass.height;
    console.info(`[ImageSelectionPage] 实际屏幕尺寸: ${this.actualWidth}×${this.actualHeight}`);
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

  // 初始化图片列表
  initImageList() {
    switch (this.source) {
      case 'character':
        // 角色专辑
        this.imageList = ImageAssets.getCharacterImages(this.characterId);
        break;
      case 'bangbu':
        // 邦布专辑
        this.imageList = ImageAssets.BANGBU_IMAGES;
        break;
      case 'network':
        // 网络随机（单张）
        this.imageList = [];
        break;
      case 'gallery':
        // 相册上传（单张）
        this.imageList = [];
        break;
    }
  }

  // 加载网络图片（增强版）
  private async loadNetworkImage(url: string): Promise<void> {
    if (!url || url.length === 0) {
      console.error('[ImageSelectionPage] 网络图片URL为空');
      this.networkImageLoadError = true;
      return;
    }
    
    try {
      this.isLoadingNetworkImage = true;
      this.networkImageLoadError = false;
      this.networkPixelMap = null;
      
      console.info('[ImageSelectionPage] 开始加载网络图片:', url);
      
      // 使用UriConverter下载并转换为PixelMap（带3次重试）
      const pixelMap = await UriConverter.urlToPixelMap(url, 3);
      console.info('[ImageSelectionPage] ✅ 网络图片下载成功！');
      
      // 裁剪为正方形（所见即所得）
      console.info('[ImageSelectionPage] 开始裁剪图片为正方形...');
      const squarePixelMap = await ImageCropper.cropToSquare(pixelMap);
      console.info('[ImageSelectionPage] ✅ 图片裁剪完成！');
      
      this.networkPixelMap = squarePixelMap;
      this.isLoadingNetworkImage = false;
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      console.error('[ImageSelectionPage] ❌ 网络图片加载失败:', errorMsg);
      
      // 提供详细的错误诊断信息
      if (errorMsg.includes('网络不可用')) {
        console.error('[诊断] 设备网络未连接，请检查模拟器网络设置');
      } else if (errorMsg.includes('403') || errorMsg.includes('代理')) {
        console.error('[诊断] 可能需要配置代理：');
        console.error('  - 确保Clash/V2RayN等代理软件正在运行');
        console.error('  - 在代理软件中开启"Allow LAN"或"允许局域网连接"');
        console.error('  - 检查防火墙设置');
      } else if (errorMsg.includes('timeout') || errorMsg.includes('超时')) {
        console.error('[诊断] 网络请求超时，可能原因：');
        console.error('  - 网络速度过慢');
        console.error('  - 代理服务器响应慢');
        console.error('  - 目标服务器不可达');
      }
      
      this.isLoadingNetworkImage = false;
      this.networkImageLoadError = true;
      this.networkPixelMap = null;
    }
  }

  // 切换图片（循环）
  switchImage() {
    if (this.imageList.length > 0) {
      this.currentImageIndex = (this.currentImageIndex + 1) % this.imageList.length;
    }
  }

  // 再次随机（网络图片）
  randomAgain() {
    // 重新创建对话框控制器以确保回调正确绑定
    this.networkImageDialogController = new CustomDialogController({
      builder: NetworkImageSelector({
        onImageSelected: (imageUrl: string) => {
          console.info('[ImageSelectionPage] 再次随机 - 接收到网络图片URL:', imageUrl);
          this.networkUrl = imageUrl;
          // 立即加载新的网络图片
          this.loadNetworkImage(imageUrl);
        }
      }),
      autoCancel: true,
      customStyle: true
    });
    this.networkImageDialogController.open();
  }

  // 重新上传（相册）
  async reupload(): Promise<void> {
    try {
      const photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.maxSelectNumber = 1;

      const photoPicker = new picker.PhotoViewPicker();
      const result = await photoPicker.select(photoSelectOptions);

      if (result && result.photoUris && result.photoUris.length > 0) {
        this.customUri = result.photoUris[0];
      }
    } catch (error) {
      console.error('选择图片失败:', error);
    }
  }

  // 开始游戏
  async startGame() {
    // 准备图片资源
    let imageResource: string = '';
    let isCustomImage = false;
    let isNetworkImage = false;
    let useCachedImage = false;  // 是否使用缓存的裁剪后图片

    if (this.source === 'network') {
      console.info('[ImageSelectionPage] 启动网络图片游戏');
      console.info(`[ImageSelectionPage] networkUrl: ${this.networkUrl}`);
      
      // 检查网络图片是否已加载完成
      if (this.isLoadingNetworkImage) {
        console.warn('[ImageSelectionPage] 网络图片正在加载中，请稍候...');
        return;
      }
      
      if (this.networkImageLoadError) {
        console.error('[ImageSelectionPage] 网络图片加载失败，无法启动游戏！');
        return;
      }
      
      if (!this.networkPixelMap) {
        console.error('[ImageSelectionPage] 网络图片未加载，请先选择图片！');
        return;
      }
      
      // 缓存裁剪后的网络图片（已在loadNetworkImage中裁剪）
      ImageCache.set(this.networkPixelMap);
      console.info('[ImageSelectionPage] ✅ 网络图片已缓存（已裁剪为正方形）');
      
      imageResource = this.networkUrl;
      isNetworkImage = true;
      isCustomImage = false;
      useCachedImage = true;  // 使用缓存
    } else if (this.source === 'gallery') {
      console.info('[ImageSelectionPage] 启动相册图片游戏');
      console.info(`[ImageSelectionPage] customUri: ${this.customUri}`);
      
      // 加载并裁剪相册图片
      try {
        console.info('[ImageSelectionPage] 加载相册图片...');
        const pixelMap = await UriConverter.uriToPixelMap(this.customUri);
        console.info('[ImageSelectionPage] 裁剪相册图片为正方形...');
        const squarePixelMap = await ImageCropper.cropToSquare(pixelMap);
        ImageCache.set(squarePixelMap);
        console.info('[ImageSelectionPage] ✅ 相册图片已缓存（已裁剪为正方形）');
        useCachedImage = true;
      } catch (error) {
        console.error('[ImageSelectionPage] 相册图片处理失败:', error);
      }
      
      imageResource = this.customUri;
      isCustomImage = true;
      isNetworkImage = false;
    } else {
      // 角色专辑或邦布专辑（rawfile路径）
      console.info('[ImageSelectionPage] 启动本地图片游戏');
      imageResource = this.imageList[this.currentImageIndex];
      console.info(`[ImageSelectionPage] rawfile路径: ${imageResource}`);
      
      // 加载并裁剪本地图片
      try {
        console.info('[ImageSelectionPage] 加载本地图片...');
        const pixelMap = await UriConverter.rawfileToPixelMap(imageResource);
        console.info('[ImageSelectionPage] 裁剪本地图片为正方形...');
        const squarePixelMap = await ImageCropper.cropToSquare(pixelMap);
        ImageCache.set(squarePixelMap);
        console.info('[ImageSelectionPage] ✅ 本地图片已缓存（已裁剪为正方形）');
        useCachedImage = true;
      } catch (error) {
        console.error('[ImageSelectionPage] 本地图片处理失败:', error);
      }
      
      isCustomImage = true;  // 标记为自定义图片，以便使用rawfile路径
      isNetworkImage = false;
    }

    console.info('[ImageSelectionPage] 跳转参数:');
    console.info(`  - gameMode: swap`);
    console.info(`  - gridSize: 3`);
    console.info(`  - imageResource: ${imageResource}`);
    console.info(`  - isCustomImage: ${isCustomImage}`);
    console.info(`  - isNetworkImage: ${isNetworkImage}`);
    console.info(`  - useCachedImage: ${useCachedImage}`);
    console.info(`  - fromPage: ${this.source}`);
    console.info(`  - source: ${this.source}`);
    console.info(`  - characterId: ${this.characterId}`);

    // 跳转到游戏页面
    router.pushUrl({
      url: 'pages/GamePage',
      params: {
        gameMode: 'swap',           // 默认交换模式
        gridSize: 3,                // 默认3x3难度
        imageResource: imageResource,
        isCustomImage: isCustomImage,
        isNetworkImage: isNetworkImage,
        useCachedImage: useCachedImage,  // 新增：告诉GamePage使用缓存
        fromPage: this.source,       // 记录来源页面
        source: this.source,         // 用于音乐播放
        characterId: this.characterId // 用于音乐播放
      }
    }).catch((err: Error) => {
      console.error('[ImageSelectionPage] 跳转失败:', err);
    });
  }

  // 获取操作按钮文字
  getActionButtonText(): string {
    switch (this.source) {
      case 'network':
        return '再次随机';
      case 'gallery':
        return '重新上传';
      default:
        return '切换图片';
    }
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

      // 图片展示区域（根据来源显示不同内容）
      this.buildImageDisplay(630, 630, 239, 29)

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

      // 开始游戏按钮（写死）
      Button() {
        Text('开始游戏')
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(254)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 0.91)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 278, y: 677 })
      .onClick(() => {
        this.startGame();
      })

      // 操作按钮（写死）- 文本根据source变化
      Button() {
        Text(this.getActionButtonText())
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(254)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 0.91)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 587, y: 677 })
      .onClick(() => {
        if (this.source === 'network') {
          this.randomAgain();
        } else if (this.source === 'gallery') {
          this.reupload();
        } else {
          this.switchImage();
        }
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

      // 图片展示区域（根据来源显示不同内容）
      this.buildImageDisplay(558, 549, 77, 65)

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

      // 开始游戏按钮（写死）
      Button() {
        Text('开始游戏')
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(254)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 1)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 77, y: 647 })
      .onClick(() => {
        this.startGame();
      })

      // 操作按钮（写死）- 文本根据source变化
      Button() {
        Text(this.getActionButtonText())
          .fontFamily('Muyao-Softbrush')
          .fontSize(48)
          .fontColor('#000000')
      }
      .width(254)
      .height(74)
      .backgroundColor('rgba(255, 255, 255, 1)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 381, y: 647 })
      .onClick(() => {
        if (this.source === 'network') {
          this.randomAgain();
        } else if (this.source === 'gallery') {
          this.reupload();
        } else {
          this.switchImage();
        }
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

      // 图片展示区域（根据来源显示不同内容）
      this.buildImageDisplay(313, 320, 115, 15)

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

      // 开始游戏按钮（写死）
      Button() {
        Text('开始游戏')
          .fontFamily('Muyao-Softbrush')
          .fontSize(38)
          .fontColor('#000000')
      }
      .width(203)
      .height(67)
      .backgroundColor('rgba(255, 255, 255, 1)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 493, y: 88 })
      .onClick(() => {
        this.startGame();
      })

      // 操作按钮（写死）- 文本根据source变化
      Button() {
        Text(this.getActionButtonText())
          .fontFamily('Muyao-Softbrush')
          .fontSize(38)
          .fontColor('#000000')
      }
      .width(203)
      .height(67)
      .backgroundColor('rgba(255, 255, 255, 1)')
      .borderRadius(25)
      .border({ width: 4, color: Color.Transparent })
      .position({ x: 493, y: 194 })
      .onClick(() => {
        if (this.source === 'network') {
          this.randomAgain();
        } else if (this.source === 'gallery') {
          this.reupload();
        } else {
          this.switchImage();
        }
      })
    }
    .width(776)
    .height(350)
  }

  // 图片显示辅助方法（根据来源显示不同内容）
  @Builder
  buildImageDisplay(width: number, height: number, x: number, y: number) {
    if (this.source === 'network') {
      // 网络图片 - 显示加载状态或PixelMap
      if (this.isLoadingNetworkImage) {
        // 加载中
        Column() {
          Text('加载中...')
            .fontFamily('Muyao-Softbrush')
            .fontSize(36)
            .fontColor(Color.White)
          Text('正在下载网络图片')
            .fontFamily('Muyao-Softbrush')
            .fontSize(24)
            .fontColor('rgba(255, 255, 255, 0.8)')
            .margin({ top: 10 })
        }
        .width(width)
        .height(height)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .borderRadius(25)
        .position({ x: x, y: y })
      } else if (this.networkImageLoadError) {
        // 加载失败
        Column() {
          Text('加载失败')
            .fontFamily('Muyao-Softbrush')
            .fontSize(36)
            .fontColor(Color.Red)
          Text('请检查网络连接后重试')
            .fontFamily('Muyao-Softbrush')
            .fontSize(24)
            .fontColor('rgba(255, 255, 255, 0.8)')
            .margin({ top: 10 })
          Text('提示：可能需要配置代理')
            .fontFamily('Muyao-Softbrush')
            .fontSize(20)
            .fontColor('rgba(255, 255, 255, 0.6)')
            .margin({ top: 5 })
          Text('点击"再次随机"重试')
            .fontFamily('Muyao-Softbrush')
            .fontSize(20)
            .fontColor('rgba(255, 255, 255, 0.6)')
            .margin({ top: 5 })
        }
        .width(width)
        .height(height)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .borderRadius(25)
        .position({ x: x, y: y })
      } else if (this.networkPixelMap) {
        // 显示已加载的网络图片
        Image(this.networkPixelMap)
          .width(width)
          .height(height)
          .objectFit(ImageFit.Cover)
          .borderRadius(25)
          .shadow({
            radius: 25,
            color: 'rgba(0, 0, 0, 0.25)',
            offsetX: 4,
            offsetY: 4
          })
          .position({ x: x, y: y })
      } else {
        // 等待选择图片
        Column() {
          Text('请选择图片')
            .fontFamily('Muyao-Softbrush')
            .fontSize(36)
            .fontColor(Color.White)
          Text('点击"再次随机"按钮')
            .fontFamily('Muyao-Softbrush')
            .fontSize(24)
            .fontColor('rgba(255, 255, 255, 0.8)')
            .margin({ top: 10 })
        }
        .width(width)
        .height(height)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('rgba(0, 0, 0, 0.3)')
        .borderRadius(25)
        .position({ x: x, y: y })
      }
    } else if (this.source === 'gallery' && this.customUri) {
      // 相册图片
      Image(this.customUri)
        .width(width)
        .height(height)
        .objectFit(ImageFit.Cover)
        .borderRadius(25)
        .shadow({
          radius: 25,
          color: 'rgba(0, 0, 0, 0.25)',
          offsetX: 4,
          offsetY: 4
        })
        .position({ x: x, y: y })
    } else if (this.imageList.length > 0) {
      // 角色/邦布图片
      Image($rawfile(this.imageList[this.currentImageIndex]))
        .width(width)
        .height(height)
        .objectFit(ImageFit.Cover)
        .borderRadius(25)
        .shadow({
          radius: 25,
          color: 'rgba(0, 0, 0, 0.25)',
          offsetX: 4,
          offsetY: 4
        })
        .position({ x: x, y: y })
    }
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

