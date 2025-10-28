import { GameConstants, DifficultyOption } from '../constants/GameConstants';

/**
 * 难度选择器组件
 */
@Component
export struct DifficultySelector {
  @Link selectedDifficulty: number;

  build() {
    Column({ space: 12 }) {
      Text('选择难度')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(GameConstants.COLORS.TEXT)

      Column({ space: 8 }) {
        ForEach(GameConstants.DIFFICULTY_OPTIONS, (option: DifficultyOption) => {
          Row() {
            Radio({ value: option.value.toString(), group: 'difficulty' })
              .checked(this.selectedDifficulty === option.value)
              .onChange((isChecked: boolean) => {
                if (isChecked) {
                  this.selectedDifficulty = option.value;
                }
              })

            Text(option.label)
              .fontSize(16)
              .fontColor(GameConstants.COLORS.TEXT)
              .margin({ left: 8 })
          }
          .width('100%')
          .padding(12)
          .backgroundColor(this.selectedDifficulty === option.value ? '#E6F7FF' : Color.White)
          .borderRadius(8)
          .onClick(() => {
            this.selectedDifficulty = option.value;
          })
        })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
  }
}

