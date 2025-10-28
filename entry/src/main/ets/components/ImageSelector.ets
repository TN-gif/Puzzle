import { ImageAssets, PresetImage } from '../constants/ImageAssets';
import { GameConstants } from '../constants/GameConstants';

/**
 * 图片选择器组件
 */
@Component
export struct ImageSelector {
  @Link selectedImageId: number;
  onCustomImageSelect?: () => void;

  build() {
    Column({ space: 12 }) {
      Text('选择图片')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(GameConstants.COLORS.TEXT)

      // 预设图片网格
      Grid() {
        ForEach(ImageAssets.PRESET_IMAGES, (item: PresetImage) => {
          GridItem() {
            Column() {
              Image(item.resource)
                .width('100%')
                .height(80)
                .objectFit(ImageFit.Cover)
                .borderRadius(8)
                .border({
                  width: this.selectedImageId === item.id ? 3 : 1,
                  color: this.selectedImageId === item.id ? GameConstants.COLORS.PRIMARY : '#E0E0E0'
                })

              Text(item.name)
                .fontSize(14)
                .fontColor(GameConstants.COLORS.TEXT)
                .margin({ top: 4 })
            }
            .onClick(() => {
              this.selectedImageId = item.id;
            })
          }
        })

        // 从相册选择
        GridItem() {
          Column() {
            Column() {
              Text('+')
                .fontSize(32)
                .fontColor(GameConstants.COLORS.PRIMARY)
            }
            .width('100%')
            .height(80)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .justifyContent(FlexAlign.Center)
            .border({
              width: this.selectedImageId === -1 ? 3 : 1,
              color: this.selectedImageId === -1 ? GameConstants.COLORS.PRIMARY : '#E0E0E0',
              style: BorderStyle.Dashed
            })

            Text('相册选择')
              .fontSize(14)
              .fontColor(GameConstants.COLORS.TEXT)
              .margin({ top: 4 })
          }
          .onClick(() => {
            if (this.onCustomImageSelect) {
              this.onCustomImageSelect();
            }
          })
        }
      }
      .columnsTemplate('1fr 1fr')
      .rowsTemplate('1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .width('100%')
      .height(200)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }
}

