import { font } from '@kit.ArkUI';
import { DesignConstants } from '../constants/DesignConstants';
import { ApiConstants } from '../constants/ApiConstants';
import { ScreenState, ScreenStateManager } from '../utils/ScreenStateManager';

/**
 * 响应式尺寸接口
 */
interface NetworkImageResponsiveSize {
  width: number;
  padding: number;
  titleSize: number;
  categoryTitleSize: number;
  categoryBtnSize: number;
  categoryBtnHeight: number;
  descSize: number;
  confirmBtnHeight: number;
  confirmBtnSize: number;
  cancelBtnHeight: number;
  cancelBtnSize: number;
}

/**
 * 网络图片选择弹窗
 */
@CustomDialog
export struct NetworkImageSelector {
  controller: CustomDialogController;
  @State searchKeyword: string = '';
  @State selectedCategory: string = 'random';  // 类别：random, nature, city, etc.
  onImageSelected?: (imageUrl: string) => void;
  @State screenState: ScreenState = ScreenState.TRIPLE;
  private screenManager: ScreenStateManager = ScreenStateManager.getInstance();
  private networkImageSize: NetworkImageResponsiveSize = {
    width: 500,
    padding: 32,
    titleSize: 48,
    categoryTitleSize: 36,
    categoryBtnSize: 32,
    categoryBtnHeight: 60,
    descSize: 28,
    confirmBtnHeight: 74,
    confirmBtnSize: 44,
    cancelBtnHeight: 64,
    cancelBtnSize: 40
  };

  aboutToAppear() {
    this.screenState = this.screenManager.getCurrentState();
    this.networkImageSize = this.getResponsiveSize();
    // 注册自定义字体
    font.registerFont({
      familyName: 'Muyao-Softbrush',
      familySrc: `/resources/rawfile/${DesignConstants.CUSTOM_FONT_PATH}`
    });
  }

  // 获取响应式尺寸
  private getResponsiveSize(): NetworkImageResponsiveSize {
    if (this.screenState === ScreenState.SINGLE) {
      const imgSize: NetworkImageResponsiveSize = {
        width: 280,
        padding: 20,
        titleSize: 32,
        categoryTitleSize: 24,
        categoryBtnSize: 20,
        categoryBtnHeight: 42,
        descSize: 18,
        confirmBtnHeight: 50,
        confirmBtnSize: 28,
        cancelBtnHeight: 44,
        cancelBtnSize: 26
      };
      return imgSize;
    } else if (this.screenState === ScreenState.DOUBLE) {
      const imgSize: NetworkImageResponsiveSize = {
        width: 390,
        padding: 26,
        titleSize: 40,
        categoryTitleSize: 30,
        categoryBtnSize: 26,
        categoryBtnHeight: 51,
        descSize: 23,
        confirmBtnHeight: 62,
        confirmBtnSize: 36,
        cancelBtnHeight: 54,
        cancelBtnSize: 33
      };
      return imgSize;
    } else {
      const imgSize: NetworkImageResponsiveSize = {
        width: 500,
        padding: 32,
        titleSize: 48,
        categoryTitleSize: 36,
        categoryBtnSize: 32,
        categoryBtnHeight: 60,
        descSize: 28,
        confirmBtnHeight: 74,
        confirmBtnSize: 44,
        cancelBtnHeight: 64,
        cancelBtnSize: 40
      };
      return imgSize;
    }
  }

  // 随机获取图片URL（使用国内API）
  getRandomImageUrl(): string {
    const timestamp = Date.now();
    
    // 根据类别选择不同的国内API
    switch (this.selectedCategory) {
      case 'random':
        // 必应每日壁纸（高质量）
        return `${ApiConstants.BING_IMAGE_URL}?t=${timestamp}`;
      
      case 'nature':
        // 风景图片
        return `https://api.btstu.cn/sjbz/api.php?lx=fengjing&t=${timestamp}`;
      
      case 'city':
        // 使用Lorem Picsum（城市场景）
        return `${ApiConstants.PICSUM_BASE_URL}/800/800?random=${timestamp}`;
      
      case 'animal':
        // 动漫图片（替代动物）
        return `https://api.btstu.cn/sjbz/api.php?lx=dongman&t=${timestamp}`;
      
      default:
        // 默认使用必应壁纸
        return `${ApiConstants.BING_IMAGE_URL}?t=${timestamp}`;
    }
  }

  // 类别选择按钮
  @Builder
  CategoryButton(label: string, category: string) {
    Button() {
      Text(label)
        .fontFamily('Muyao-Softbrush')
        .fontSize(this.networkImageSize.categoryBtnSize)
        .fontColor(this.selectedCategory === category ? '#FFFFFF' : '#000000')
    }
    .height(this.networkImageSize.categoryBtnHeight)
    .backgroundColor(this.selectedCategory === category ? '#000000' : '#FFFFFF')
    .border({
      width: 3,
      color: '#000000'
    })
    .borderRadius(8)
    .layoutWeight(1)
    .onClick(() => {
      this.selectedCategory = category;
    })
  }

  build() {
    Column({ space: 20 }) {
      // 标题
      Text('网络随机图片')
        .fontFamily('Muyao-Softbrush')
        .fontSize(this.networkImageSize.titleSize)
        .fontColor('#000000')
        .fontWeight(FontWeight.Bold)

      // 类别选择
      Column({ space: 12 }) {
        Text('选择类别')
          .fontFamily('Muyao-Softbrush')
          .fontSize(this.networkImageSize.categoryTitleSize)
          .fontColor('#000000')
        
        Row({ space: 12 }) {
          this.CategoryButton('必应壁纸', 'random')
          this.CategoryButton('风景', 'nature')
        }
        .width('100%')

        Row({ space: 12 }) {
          this.CategoryButton('随机图片', 'city')
          this.CategoryButton('动漫', 'animal')
        }
        .width('100%')
      }
      .width('100%')

      // 说明文字
      Text('将随机选择一张高质量图片')
        .fontFamily('Muyao-Softbrush')
        .fontSize(this.networkImageSize.descSize)
        .fontColor('#666666')

      // 确认按钮
      Button() {
        Text('确认选择')
          .fontFamily('Muyao-Softbrush')
          .fontSize(this.networkImageSize.confirmBtnSize)
          .fontColor('#FFFFFF')
      }
      .width('100%')
      .height(this.networkImageSize.confirmBtnHeight)
      .backgroundColor('#000000')
      .borderRadius(8)
      .border({
        width: 4,
        color: '#000000'
      })
      .margin({ top: 16 })
      .onClick(() => {
        const imageUrl = this.getRandomImageUrl();
        console.info('[NetworkImageSelector] 生成随机图片URL:', imageUrl);
        if (this.onImageSelected) {
          this.onImageSelected(imageUrl);
        }
        this.controller.close();
      })

      // 取消按钮
      Button() {
        Text('取消')
          .fontFamily('Muyao-Softbrush')
          .fontSize(this.networkImageSize.cancelBtnSize)
          .fontColor('#000000')
      }
      .width('100%')
      .height(this.networkImageSize.cancelBtnHeight)
      .backgroundColor('#FFFFFF')
      .borderRadius(8)
      .border({
        width: 3,
        color: '#000000'
      })
      .onClick(() => {
        this.controller.close();
      })
    }
    .width(this.networkImageSize.width)
    .padding(this.networkImageSize.padding)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .border({
      width: 4,
      color: '#000000'
    })
  }
}
