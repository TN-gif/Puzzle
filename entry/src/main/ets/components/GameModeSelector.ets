import { GameConstants, ModeOption } from '../constants/GameConstants';

/**
 * 游戏模式选择器组件
 */
@Component
export struct GameModeSelector {
  @Link selectedMode: string;

  build() {
    Column({ space: 12 }) {
      Text('选择模式')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(GameConstants.COLORS.TEXT)

      Column({ space: 8 }) {
        ForEach(GameConstants.MODE_OPTIONS, (option: ModeOption) => {
          Column({ space: 4 }) {
            Row() {
              Radio({ value: option.value, group: 'gameMode' })
                .checked(this.selectedMode === option.value)
                .onChange((isChecked: boolean) => {
                  if (isChecked) {
                    this.selectedMode = option.value;
                  }
                })

              Column({ space: 2 }) {
                Text(option.label)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(GameConstants.COLORS.TEXT)

                Text(option.desc)
                  .fontSize(12)
                  .fontColor('#999999')
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 8 })
              .layoutWeight(1)
            }
            .width('100%')
            .padding(12)
            .backgroundColor(this.selectedMode === option.value ? '#E6F7FF' : Color.White)
            .borderRadius(8)
            .onClick(() => {
              this.selectedMode = option.value;
            })
          }
        })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }
}

