import { font } from '@kit.ArkUI';
import { DesignConstants } from '../constants/DesignConstants';
import { ScreenState, ScreenStateManager } from '../utils/ScreenStateManager';

/**
 * 难度对话框响应式尺寸接口
 */
interface DifficultyResponsiveSize {
  width: number;
  padding: number;
  titleSize: number;
  optionSize: number;
  optionHeight: number;
  btnHeight: number;
  btnTextSize: number;
}

/**
 * 难度选择弹窗组件（响应式）
 */
@CustomDialog
export struct DifficultyDialog {
  controller: CustomDialogController;
  @State selectedDifficulty: number = 3;
  onDifficultySelected?: (difficulty: number) => void;
  @State screenState: ScreenState = ScreenState.TRIPLE;
  private screenManager: ScreenStateManager = ScreenStateManager.getInstance();
  private dialogSize: DifficultyResponsiveSize = {
    width: 500,
    padding: 32,
    titleSize: 48,
    optionSize: 40,
    optionHeight: 70,
    btnHeight: 74,
    btnTextSize: 44
  };

  aboutToAppear() {
    this.screenState = this.screenManager.getCurrentState();
    this.dialogSize = this.getResponsiveSize();
    // 注册自定义字体
    font.registerFont({
      familyName: 'Muyao-Softbrush',
      familySrc: `/resources/rawfile/${DesignConstants.CUSTOM_FONT_PATH}`
    });
  }

  // 获取响应式尺寸
  private getResponsiveSize(): DifficultyResponsiveSize {
    if (this.screenState === ScreenState.SINGLE) {
      const size: DifficultyResponsiveSize = {
        width: 280,
        padding: 20,
        titleSize: 32,
        optionSize: 28,
        optionHeight: 50,
        btnHeight: 56,
        btnTextSize: 32
      };
      return size;
    } else if (this.screenState === ScreenState.DOUBLE) {
      const size: DifficultyResponsiveSize = {
        width: 380,
        padding: 26,
        titleSize: 40,
        optionSize: 34,
        optionHeight: 60,
        btnHeight: 65,
        btnTextSize: 38
      };
      return size;
    } else {
      const size: DifficultyResponsiveSize = {
        width: 500,
        padding: 32,
        titleSize: 48,
        optionSize: 40,
        optionHeight: 70,
        btnHeight: 74,
        btnTextSize: 44
      };
      return size;
    }
  }

  // 难度选项
  @Builder
  DifficultyOption(label: string, value: number, size: DifficultyResponsiveSize) {
    Button() {
      Text(label)
        .fontFamily('Muyao-Softbrush')
        .fontSize(size.optionSize)
        .fontColor(this.selectedDifficulty === value ? '#FFFFFF' : '#000000')
    }
    .width('100%')
    .height(size.optionHeight)
    .backgroundColor(this.selectedDifficulty === value ? '#000000' : '#FFFFFF')
    .border({
      width: 3,
      color: '#000000'
    })
    .borderRadius(8)
    .margin({ bottom: 16 })
    .onClick(() => {
      this.selectedDifficulty = value;
    })
  }

  build() {
    Column({ space: 20 }) {
      // 标题
      Text('选择难度')
        .fontFamily('Muyao-Softbrush')
        .fontSize(this.dialogSize.titleSize)
        .fontColor('#000000')
        .fontWeight(FontWeight.Bold)

      // 难度选项
      Column({ space: 16 }) {
        this.DifficultyOption('简单 3 × 3', 3, this.dialogSize)
        this.DifficultyOption('中等 4 × 4', 4, this.dialogSize)
        this.DifficultyOption('困难 5 × 5', 5, this.dialogSize)
      }
      .width('100%')

      // 确认按钮
      Button() {
        Text('确认')
          .fontFamily('Muyao-Softbrush')
          .fontSize(this.dialogSize.btnTextSize)
          .fontColor('#FFFFFF')
      }
      .width('100%')
      .height(this.dialogSize.btnHeight)
      .backgroundColor('#000000')
      .borderRadius(8)
      .border({
        width: 4,
        color: '#000000'
      })
      .margin({ top: 16 })
      .onClick(() => {
        if (this.onDifficultySelected) {
          this.onDifficultySelected(this.selectedDifficulty);
        }
        this.controller.close();
      })
    }
    .width(this.dialogSize.width)
    .padding(this.dialogSize.padding)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .border({
      width: 4,
      color: '#000000'
    })
  }
}

