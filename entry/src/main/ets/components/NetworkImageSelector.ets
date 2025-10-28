import { NetworkImageService, ImageData } from '../utils/NetworkImageService';
import { GameConstants } from '../constants/GameConstants';

/**
 * 网络图片选择对话框
 */
@CustomDialog
export struct NetworkImageSelector {
  controller: CustomDialogController;
  onImageSelected?: (imageUrl: string) => void;

  @State searchKeyword: string = '';
  @State images: ImageData[] = [];
  @State isLoading: boolean = false;
  @State selectedImageUrl: string = '';

  async aboutToAppear() {
    // 默认加载随机图片
    await this.loadRandomImages();
  }

  // 加载随机图片
  private async loadRandomImages(): Promise<void> {
    this.isLoading = true;
    try {
      this.images = await NetworkImageService.getRandomImages();
    } catch (error) {
      console.error('加载随机图片失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  // 搜索图片
  private async searchImages(): Promise<void> {
    if (!this.searchKeyword.trim()) {
      await this.loadRandomImages();
      return;
    }

    this.isLoading = true;
    try {
      this.images = await NetworkImageService.searchImages(this.searchKeyword);
    } catch (error) {
      console.error('搜索图片失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column({ space: 16 }) {
      // 标题
      Text('网络图片搜索')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(GameConstants.COLORS.TEXT)

      // 搜索框
      Row({ space: 8 }) {
        TextInput({ placeholder: '输入关键字（如：自然、动物）', text: this.searchKeyword })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.searchKeyword = value;
          })
          .onSubmit(() => {
            this.searchImages();
          })

        Button('搜索')
          .height(40)
          .onClick(() => {
            this.searchImages();
          })

        Button('随机')
          .height(40)
          .onClick(() => {
            this.loadRandomImages();
          })
      }
      .width('100%')

      // 图片网格
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 8 })
        }
        .width('100%')
        .height(300)
        .justifyContent(FlexAlign.Center)
      } else if (this.images.length === 0) {
        Column() {
          Text('😔')
            .fontSize(48)
          Text('未找到图片')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 8 })
        }
        .width('100%')
        .height(300)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Grid() {
            ForEach(this.images.slice(0, 12), (img: ImageData) => {
              GridItem() {
                Column() {
                  Image(img.previewURL)
                    .width('100%')
                    .height(100)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(8)
                    .border({
                      width: this.selectedImageUrl === img.webformatURL ? 3 : 0,
                      color: GameConstants.COLORS.PRIMARY
                    })

                  Text(img.tags.split(',')[0])
                    .fontSize(12)
                    .fontColor('#666666')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ top: 4 })
                }
                .onClick(() => {
                  this.selectedImageUrl = img.webformatURL;
                })
              }
            })
          }
          .columnsTemplate('1fr 1fr 1fr')
          .rowsGap(12)
          .columnsGap(12)
          .width('100%')
        }
        .width('100%')
        .height(300)
        .scrollBar(BarState.Auto)
      }

      // 按钮组
      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(Color.White)
          .fontColor(GameConstants.COLORS.TEXT)
          .border({ width: 1, color: '#E0E0E0' })
          .onClick(() => {
            this.controller.close();
          })

        Button('确定')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(GameConstants.COLORS.PRIMARY)
          .enabled(this.selectedImageUrl !== '')
          .onClick(() => {
            if (this.selectedImageUrl && this.onImageSelected) {
              this.onImageSelected(this.selectedImageUrl);
            }
            this.controller.close();
          })
      }
      .width('100%')
    }
    .padding(24)
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}

