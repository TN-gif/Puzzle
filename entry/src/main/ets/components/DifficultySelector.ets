import { GameConstants, DifficultyOption, Colors } from '../constants/GameConstants';

/**
 * 难度选择器组件 - 荧光科技风
 */
@Component
export struct DifficultySelector {
  @Link selectedDifficulty: number;

  // 获取难度图标
  private getDifficultyIcon(value: number): string {
    switch(value) {
      case 3:
        return '⭐';
      case 4:
        return '⭐⭐';
      case 5:
        return '⭐⭐⭐';
      default:
        return '⭐';
    }
  }

  // 获取难度描述
  private getDifficultyDesc(value: number): string {
    switch(value) {
      case 3:
        return '适合新手';
      case 4:
        return '中等挑战';
      case 5:
        return '高手之路';
      default:
        return '';
    }
  }

  build() {
    Column({ space: 16 }) {
      Row({ space: 8 }) {
        Text('🎯')
          .fontSize(20)
        Text('选择难度')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY)
      }

      Column({ space: 12 }) {
        ForEach(GameConstants.DIFFICULTY_OPTIONS, (option: DifficultyOption) => {
          Row() {
            Radio({ value: option.value.toString(), group: 'difficulty' })
              .checked(this.selectedDifficulty === option.value)
              .radioStyle({
                checkedBackgroundColor: Colors.ACCENT_PRIMARY
              })
              .onChange((isChecked: boolean) => {
                if (isChecked) {
                  this.selectedDifficulty = option.value;
                }
              })

            Column({ space: 4 }) {
              Row({ space: 8 }) {
                Text(option.label)
                  .fontSize(16)
                  .fontColor(this.selectedDifficulty === option.value ? Colors.ACCENT_PRIMARY : Colors.TEXT_SECONDARY)
                  .fontWeight(this.selectedDifficulty === option.value ? FontWeight.Bold : FontWeight.Medium)
                
                Text(this.getDifficultyIcon(option.value))
                  .fontSize(14)
              }
              
              Text(this.getDifficultyDesc(option.value))
                .fontSize(12)
                .fontColor(Colors.TEXT_DISABLED)
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 12 })
            .layoutWeight(1)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(this.selectedDifficulty === option.value ? Colors.SURFACE_ELEVATED : Colors.SURFACE)
          .border({
            width: this.selectedDifficulty === option.value ? 2 : 1,
            color: this.selectedDifficulty === option.value ? Colors.ACCENT_PRIMARY : Colors.TEXT_DISABLED
          })
          .borderRadius(GameConstants.BORDER_RADIUS.MEDIUM)
          .shadow({
            radius: this.selectedDifficulty === option.value ? GameConstants.GLOW_EFFECT.PRIMARY.RADIUS : 0,
            color: GameConstants.GLOW_EFFECT.PRIMARY.COLOR,
            offsetX: 0,
            offsetY: 0
          })
          .onClick(() => {
            this.selectedDifficulty = option.value;
          })
        })
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Colors.SURFACE)
    .borderRadius(GameConstants.BORDER_RADIUS.LARGE)
  }
}

