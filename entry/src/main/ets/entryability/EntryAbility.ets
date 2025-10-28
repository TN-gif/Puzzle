import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import font from '@ohos.font';

const DOMAIN = 0x0000;
const TAG = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    
    // 保存context和resourceManager到AppStorage，供全局使用
    AppStorage.setOrCreate('context', this.context);
    AppStorage.setOrCreate('resourceManager', this.context.resourceManager);
    hilog.info(DOMAIN, TAG, 'Context和ResourceManager已保存到AppStorage');
    
    // 注册自定义字体（如果有）
    this.registerCustomFont();
    
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate');
  }

  /**
   * 注册自定义字体
   */
  private registerCustomFont(): void {
    try {
      // 如果有自定义字体文件，在这里注册
      // 例如：entry/src/main/resources/rawfile/fonts/CustomFont.ttf
      // font.registerFontSync({
      //   familyName: 'CustomFont',
      //   familySrc: $rawfile('fonts/CustomFont.ttf')
      // });
      // hilog.info(DOMAIN, TAG, '自定义字体注册成功');
    } catch (error) {
      hilog.error(DOMAIN, TAG, '字体注册失败: %{public}s', JSON.stringify(error));
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/HomePage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}