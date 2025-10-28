import { GameConstants } from '../constants/GameConstants';

/**
 * 胜利对话框组件
 */
@CustomDialog
export struct WinDialog {
  controller: CustomDialogController;
  moveCount: number = 0;
  timeElapsed: number = 0;
  onPlayAgain?: () => void;
  onBackHome?: () => void;

  // 格式化时间
  private formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  build() {
    Column({ space: 20 }) {
      // 奖杯图标
      Text('🏆')
        .fontSize(64)

      // 标题
      Text('恭喜完成！')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(GameConstants.COLORS.PRIMARY)

      // 统计信息
      Column({ space: 12 }) {
        Row() {
          Text('耗时：')
            .fontSize(16)
            .fontColor(GameConstants.COLORS.TEXT)
          Text(this.formatTime(this.timeElapsed))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(GameConstants.COLORS.PRIMARY)
        }

        Row() {
          Text('步数：')
            .fontSize(16)
            .fontColor(GameConstants.COLORS.TEXT)
          Text(`${this.moveCount} 步`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(GameConstants.COLORS.PRIMARY)
        }
      }
      .padding(16)
      .backgroundColor('#F5F5F5')
      .borderRadius(8)
      .width('100%')

      // 按钮组
      Column({ space: 12 }) {
        Button('再玩一次')
          .width('100%')
          .height(44)
          .fontSize(16)
          .backgroundColor(GameConstants.COLORS.PRIMARY)
          .onClick(() => {
            this.controller.close();
            if (this.onPlayAgain) {
              this.onPlayAgain();
            }
          })

        Button('返回主页')
          .width('100%')
          .height(44)
          .fontSize(16)
          .backgroundColor(Color.White)
          .fontColor(GameConstants.COLORS.PRIMARY)
          .border({ width: 1, color: GameConstants.COLORS.PRIMARY })
          .onClick(() => {
            this.controller.close();
            if (this.onBackHome) {
              this.onBackHome();
            }
          })
      }
    }
    .padding(24)
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}

