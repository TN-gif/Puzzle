import { font } from '@kit.ArkUI';
import { DesignConstants } from '../constants/DesignConstants';
import { ScreenState, ScreenStateManager } from '../utils/ScreenStateManager';

/**
 * 响应式尺寸接口
 */
interface ResponsiveSize {
  padding: number;
  spacing: number;
  titleSize: number;
  subtitleSize: number;
  emojiSize: number;
  statSize: number;
  statLabel: number;
  btnHeight: number;
  btnTextSize: number;
  width: number;
}

/**
 * 胜利对话框组件 - 简约黑白风（响应式）
 */
@CustomDialog
export struct WinDialog {
  controller: CustomDialogController;
  moveCount: number = 0;
  timeElapsed: number = 0;
  onPlayAgain?: () => void;
  onBackHome?: () => void;
  @State screenState: ScreenState = ScreenState.TRIPLE;
  private screenManager: ScreenStateManager = ScreenStateManager.getInstance();
  private responsiveSize: ResponsiveSize = {
    padding: 32,
    spacing: 20,
    titleSize: 48,
    subtitleSize: 28,
    emojiSize: 60,
    statSize: 40,
    statLabel: 28,
    btnHeight: 74,
    btnTextSize: 44,
    width: 500
  };

  aboutToAppear() {
    this.screenState = this.screenManager.getCurrentState();
    this.responsiveSize = this.getResponsiveSize();
    // 注册自定义字体
    font.registerFont({
      familyName: 'Muyao-Softbrush',
      familySrc: `/resources/rawfile/${DesignConstants.CUSTOM_FONT_PATH}`
    });
  }

  // 格式化时间
  private formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  // 获取响应式尺寸
  private getResponsiveSize(): ResponsiveSize {
    if (this.screenState === ScreenState.SINGLE) {
      const size: ResponsiveSize = {
        padding: 20,
        spacing: 14,
        titleSize: 32,
        subtitleSize: 18,
        emojiSize: 40,
        statSize: 28,
        statLabel: 18,
        btnHeight: 56,
        btnTextSize: 32,
        width: 280
      };
      return size;
    } else if (this.screenState === ScreenState.DOUBLE) {
      const size: ResponsiveSize = {
        padding: 26,
        spacing: 17,
        titleSize: 40,
        subtitleSize: 23,
        emojiSize: 50,
        statSize: 34,
        statLabel: 23,
        btnHeight: 65,
        btnTextSize: 38,
        width: 390
      };
      return size;
    } else {
      const size: ResponsiveSize = {
        padding: 32,
        spacing: 20,
        titleSize: 48,
        subtitleSize: 28,
        emojiSize: 60,
        statSize: 40,
        statLabel: 28,
        btnHeight: 74,
        btnTextSize: 44,
        width: 500
      };
      return size;
    }
  }

  build() {
    Column({ space: this.responsiveSize.spacing }) {
      // 标题
      Text('恭喜完成！')
        .fontFamily('Muyao-Softbrush')
        .fontSize(this.responsiveSize.titleSize)
        .fontColor('#000000')
        .fontWeight(FontWeight.Bold)

      // 统计信息卡片
      Column({ space: 16 }) {
        // 耗时
        Column({ space: 8 }) {
          Text('用时')
            .fontFamily('Muyao-Softbrush')
            .fontSize(this.responsiveSize.statLabel)
            .fontColor('#666666')
          Text(this.formatTime(this.timeElapsed))
            .fontFamily('Muyao-Softbrush')
            .fontSize(this.responsiveSize.statSize)
            .fontWeight(FontWeight.Bold)
            .fontColor('#000000')
        }

        // 分隔线
        Divider()
          .color('#CCCCCC')
          .strokeWidth(2)

        // 步数
        Column({ space: 8 }) {
          Text('步数')
            .fontFamily('Muyao-Softbrush')
            .fontSize(this.responsiveSize.statLabel)
            .fontColor('#666666')
          Text(`${this.moveCount}`)
            .fontFamily('Muyao-Softbrush')
            .fontSize(this.responsiveSize.statSize)
            .fontWeight(FontWeight.Bold)
            .fontColor('#000000')
        }
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#F5F5F5')
      .borderRadius(8)
      .border({ width: 2, color: '#CCCCCC' })

      // 按钮组
      Column({ space: 12 }) {
        // 再玩一次按钮
        Button() {
          Text('再玩一次')
            .fontFamily('Muyao-Softbrush')
            .fontSize(this.responsiveSize.btnTextSize)
            .fontColor('#FFFFFF')
        }
        .width('100%')
        .height(this.responsiveSize.btnHeight)
        .backgroundColor('#000000')
        .borderRadius(8)
        .border({ width: 4, color: '#000000' })
        .onClick(() => {
          this.controller.close();
          if (this.onPlayAgain) {
            this.onPlayAgain();
          }
        })

        // 返回主页按钮
        Button() {
          Text('返回主页')
            .fontFamily('Muyao-Softbrush')
            .fontSize(this.responsiveSize.btnTextSize)
            .fontColor('#000000')
        }
        .width('100%')
        .height(this.responsiveSize.btnHeight)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .border({ width: 3, color: '#000000' })
        .onClick(() => {
          this.controller.close();
          if (this.onBackHome) {
            this.onBackHome();
          }
        })
      }
    }
    .padding(this.responsiveSize.padding)
    .width(this.responsiveSize.width)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .border({ width: 4, color: '#000000' })
  }
}


