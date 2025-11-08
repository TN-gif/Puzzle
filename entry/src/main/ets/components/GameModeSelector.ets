import { GameConstants, ModeOption, Colors } from '../constants/GameConstants';

/**
 * 游戏模式选择器组件 - 荧光科技风
 */
@Component
export struct GameModeSelector {
  @Link selectedMode: string;

  // 获取模式图标
  private getModeIcon(value: string): string {
    return value === GameConstants.GAME_MODE.HUARONG ? '🎲' : '🔄';
  }

  build() {
    Column({ space: 16 }) {
      Row({ space: 8 }) {
        Text('🎮')
          .fontSize(20)
        Text('选择模式')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY)
      }

      Column({ space: 12 }) {
        ForEach(GameConstants.MODE_OPTIONS, (option: ModeOption) => {
          Column({ space: 4 }) {
            Row() {
              Radio({ value: option.value, group: 'gameMode' })
                .checked(this.selectedMode === option.value)
                .radioStyle({
                  checkedBackgroundColor: Colors.ACCENT_PRIMARY
                })
                .onChange((isChecked: boolean) => {
                  if (isChecked) {
                    this.selectedMode = option.value;
                  }
                })

              Column({ space: 4 }) {
                Row({ space: 8 }) {
                  Text(this.getModeIcon(option.value))
                    .fontSize(18)
                  Text(option.label)
                    .fontSize(16)
                    .fontWeight(this.selectedMode === option.value ? FontWeight.Bold : FontWeight.Medium)
                    .fontColor(this.selectedMode === option.value ? Colors.ACCENT_PRIMARY : Colors.TEXT_SECONDARY)
                }

                Text(option.desc)
                  .fontSize(12)
                  .fontColor(Colors.TEXT_DISABLED)
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 12 })
              .layoutWeight(1)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(this.selectedMode === option.value ? Colors.SURFACE_ELEVATED : Colors.SURFACE)
            .border({
              width: this.selectedMode === option.value ? 2 : 1,
              color: this.selectedMode === option.value ? Colors.ACCENT_PRIMARY : Colors.TEXT_DISABLED
            })
            .borderRadius(GameConstants.BORDER_RADIUS.MEDIUM)
            .shadow({
              radius: this.selectedMode === option.value ? GameConstants.GLOW_EFFECT.PRIMARY.RADIUS : 0,
              color: GameConstants.GLOW_EFFECT.PRIMARY.COLOR,
              offsetX: 0,
              offsetY: 0
            })
            .onClick(() => {
              this.selectedMode = option.value;
            })
          }
        })
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Colors.SURFACE)
    .borderRadius(GameConstants.BORDER_RADIUS.LARGE)
  }
}

