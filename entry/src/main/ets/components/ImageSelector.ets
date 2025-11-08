import { ImageAssets, PresetImage } from '../constants/ImageAssets';
import { GameConstants, Colors } from '../constants/GameConstants';

/**
 * 图片选择器组件 - 荧光科技风
 */
@Component
export struct ImageSelector {
  @Link selectedImageId: number;
  onCustomImageSelect?: () => void;

  build() {
    Column({ space: 16 }) {
      Row({ space: 8 }) {
        Text('🖼️')
          .fontSize(20)
        Text('选择图片')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY)
      }

      // 预设图片网格
      Grid() {
        ForEach(ImageAssets.PRESET_IMAGES, (item: PresetImage) => {
          GridItem() {
            Column({ space: 6 }) {
              Stack() {
                Image(item.resource)
                  .width('100%')
                  .height(90)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(GameConstants.BORDER_RADIUS.SMALL)
                  .border({
                    width: this.selectedImageId === item.id ? 3 : 1,
                    color: this.selectedImageId === item.id ? Colors.ACCENT_PRIMARY : Colors.TEXT_DISABLED
                  })
                  .shadow({
                    radius: this.selectedImageId === item.id ? GameConstants.GLOW_EFFECT.PRIMARY.RADIUS : 0,
                    color: GameConstants.GLOW_EFFECT.PRIMARY.COLOR,
                    offsetX: 0,
                    offsetY: 0
                  })

                // 选中标记
                if (this.selectedImageId === item.id) {
                  Text('✓')
                    .fontSize(20)
                    .fontColor(Colors.ACCENT_PRIMARY)
                    .fontWeight(FontWeight.Bold)
                    .padding(4)
                    .backgroundColor('rgba(18, 18, 18, 0.8)')
                    .borderRadius(100)
                    .width(32)
                    .height(32)
                    .textAlign(TextAlign.Center)
                }
              }
              .alignContent(Alignment.TopEnd)
              .padding(6)

              Text(item.name)
                .fontSize(13)
                .fontColor(this.selectedImageId === item.id ? Colors.ACCENT_PRIMARY : Colors.TEXT_SECONDARY)
                .fontWeight(this.selectedImageId === item.id ? FontWeight.Bold : FontWeight.Medium)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .onClick(() => {
              this.selectedImageId = item.id;
            })
          }
        })

        // 从相册选择
        GridItem() {
          Column({ space: 6 }) {
            Column({ space: 4 }) {
              Text('📁')
                .fontSize(32)
                .fontColor(this.selectedImageId === -1 ? Colors.ACCENT_PRIMARY : Colors.TEXT_SECONDARY)
              Text('+')
                .fontSize(24)
                .fontColor(this.selectedImageId === -1 ? Colors.ACCENT_PRIMARY : Colors.TEXT_SECONDARY)
                .fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .height(90)
            .backgroundColor(Colors.SURFACE_ELEVATED)
            .borderRadius(GameConstants.BORDER_RADIUS.SMALL)
            .justifyContent(FlexAlign.Center)
            .border({
              width: this.selectedImageId === -1 ? 3 : 1,
              color: this.selectedImageId === -1 ? Colors.ACCENT_PRIMARY : Colors.TEXT_DISABLED,
              style: BorderStyle.Dashed
            })
            .shadow({
              radius: this.selectedImageId === -1 ? GameConstants.GLOW_EFFECT.PRIMARY.RADIUS : 0,
              color: GameConstants.GLOW_EFFECT.PRIMARY.COLOR,
              offsetX: 0,
              offsetY: 0
            })

            Text('相册选择')
              .fontSize(13)
              .fontColor(this.selectedImageId === -1 ? Colors.ACCENT_PRIMARY : Colors.TEXT_SECONDARY)
              .fontWeight(this.selectedImageId === -1 ? FontWeight.Bold : FontWeight.Medium)
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
      .height(230)
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Colors.SURFACE)
    .borderRadius(GameConstants.BORDER_RADIUS.LARGE)
  }
}

