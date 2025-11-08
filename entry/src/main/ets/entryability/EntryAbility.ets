import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { formProvider, formInfo, formBindingData } from '@kit.FormKit';
import { preferences } from '@kit.ArkData';
import font from '@ohos.font';
import { ScreenStateManager } from '../utils/ScreenStateManager';
import { GameStorage, SavedGameState } from '../utils/GameStorage';
import { audioManager } from '../utils/AudioManager';

const DOMAIN = 0x0000;
const TAG = 'EntryAbility';

/**
 * 卡片数据接口
 */
interface FormDataContent {
  title: string;
  gameMode: string;
  gridSize: string;
  moveCount: number;
  timeElapsed: string;
  hasActiveGame: boolean;
}

export default class EntryAbility extends UIAbility {
  private targetPage: string = 'pages/EntryPage'; // 默认启动页面

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    
    // 🔥 官方确认方案：添加启动时间戳，用于检测冷启动
    AppStorage.setOrCreate('lastLaunchTime', Date.now());
    hilog.info(DOMAIN, TAG, '🕐 记录启动时间: %{public}d', Date.now());
    
    // 检查是否从卡片启动
    if (want.parameters) {
      const targetPage = want.parameters['targetPage'] as string;
      if (targetPage) {
        this.targetPage = targetPage;
        hilog.info(DOMAIN, TAG, '从卡片启动，目标页面: %{public}s', targetPage);
      }
    }
    
    // 保存context和resourceManager到AppStorage，供全局使用
    AppStorage.setOrCreate('context', this.context);
    AppStorage.setOrCreate('resourceManager', this.context.resourceManager);
    hilog.info(DOMAIN, TAG, 'Context和ResourceManager已保存到AppStorage');
    
    // 初始化音频管理器
    audioManager.setContext(this.context);
    hilog.info(DOMAIN, TAG, 'AudioManager已初始化');
    
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
    hilog.info(DOMAIN, TAG, '========== 🔴 onDestroy 触发（应用被销毁）==========');
    
    // 🔥 关键：应用被销毁时，立即更新卡片显示"开始新游戏"
    // 因为游戏数据可能已被清除或应用被强制关闭
    this.updateAllFormsOnDestroy();
  }

  /**
   * 🔥 应用销毁时更新所有卡片
   * 使用 fire-and-forget 模式，不等待完成
   */
  private updateAllFormsOnDestroy(): void {
    // 使用异步立即执行函数（不阻塞 onDestroy）
    (async () => {
      try {
        hilog.info(DOMAIN, TAG, '🔄 开始更新卡片（应用销毁）');
        
        // 🔥 关键第一步：清除 preferences 中的游戏状态
        // 防止定时刷新时 FormAbility 读取到旧数据
        await GameStorage.clearGameState();
        hilog.info(DOMAIN, TAG, '✅ 游戏状态已清除（防止定时刷新读取旧数据）');
        
        // 第二步：读取卡片ID
        // 🔥 关键：使用应用级别的 context，确保与 FormAbility 共享同一存储
        const appContext = this.context.getApplicationContext();
        const dataPreferences: preferences.Preferences = await preferences.getPreferences(appContext, 'formIds');
        const formIdsStr: string = await dataPreferences.get('ids', '[]') as string;
        const formIds: Array<string> = JSON.parse(formIdsStr);
        
        hilog.info(DOMAIN, TAG, `📋 读取到 ${formIds.length} 个卡片`);
        
        if (formIds.length === 0) {
          hilog.warn(DOMAIN, TAG, '⚠️ 没有卡片，跳过更新');
          return;
        }
        
        // 第三步：创建"开始新游戏"的卡片数据
        const formData: FormDataContent = {
          title: '拼图游戏',
          gameMode: '交换',
          gridSize: '3×3',
          moveCount: 0,
          timeElapsed: '00:00',
          hasActiveGame: false
        };
        
        // 第四步：更新所有卡片
        for (const formId of formIds) {
          try {
            await formProvider.updateForm(formId, formBindingData.createFormBindingData(formData));
            hilog.info(DOMAIN, TAG, `✅ 卡片 ${formId} 更新成功`);
          } catch (error) {
            const err = error as Error;
            hilog.error(DOMAIN, TAG, `❌ 卡片 ${formId} 更新失败: ${err.message}`);
          }
        }
        
        hilog.info(DOMAIN, TAG, '✅ 所有卡片更新完成（应用销毁）');
      } catch (error) {
        const err = error as Error;
        hilog.error(DOMAIN, TAG, `❌ onDestroy 更新卡片失败: ${err.message}`);
      }
    })();
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    try {
      // 1. 初始化屏幕状态管理器（等待完成）
      const screenManager = ScreenStateManager.getInstance();
      await screenManager.init(windowStage);
      hilog.info(DOMAIN, TAG, '✅ 屏幕状态管理器初始化成功');

      // 2. 设置全屏模式（隐藏状态栏）
      const windowClass = await windowStage.getMainWindow();
      await windowClass.setWindowLayoutFullScreen(true);
      hilog.info(DOMAIN, TAG, '✅ 全屏模式设置成功');

      // 3. 加载目标页面（支持从卡片启动跳转）
      hilog.info(DOMAIN, TAG, '准备加载页面: %{public}s', this.targetPage);
      windowStage.loadContent(this.targetPage, (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
          // 如果加载失败，尝试加载默认页面
          if (this.targetPage !== 'pages/EntryPage') {
            hilog.info(DOMAIN, TAG, '目标页面加载失败，回退到默认页面');
            windowStage.loadContent('pages/EntryPage', (err2) => {
              if (err2.code) {
                hilog.error(DOMAIN, TAG, '默认页面也加载失败: %{public}s', JSON.stringify(err2));
              }
            });
          }
          return;
        }
        hilog.info(DOMAIN, 'testTag', '✅ 页面加载成功: %{public}s', this.targetPage);
        // 重置目标页面为默认值
        this.targetPage = 'pages/EntryPage';
      });
    } catch (err) {
      hilog.error(DOMAIN, TAG, '❌ 初始化失败: %{public}s', JSON.stringify(err));
    }
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
    
    // 清理屏幕状态管理器
    const screenManager = ScreenStateManager.getInstance();
    screenManager.destroy();
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
    
    // 恢复背景音乐播放
    audioManager.resumeBGM();
    hilog.info(DOMAIN, TAG, '应用回到前台，恢复音乐播放');
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 处理已运行应用被卡片再次唤起的情况
    hilog.info(DOMAIN, TAG, '========== onNewWant 触发 ==========');
    hilog.info(DOMAIN, TAG, 'want.parameters: %{public}s', JSON.stringify(want.parameters));
    
    if (want.parameters) {
      const targetPage = want.parameters['targetPage'] as string;
      if (targetPage) {
        hilog.info(DOMAIN, TAG, '🎯 卡片唤起应用，目标页面: %{public}s', targetPage);
        
        // 🔥 关键：保存到 AppStorage，让当前页面响应跳转
        AppStorage.setOrCreate('widgetTargetPage', targetPage);
        AppStorage.setOrCreate('widgetTargetPageTimestamp', Date.now());  // 添加时间戳确保触发更新
        
        hilog.info(DOMAIN, TAG, '✅ 目标页面已保存到 AppStorage');
      } else {
        hilog.warn(DOMAIN, TAG, '⚠️ 未找到 targetPage 参数');
      }
    } else {
      hilog.warn(DOMAIN, TAG, '⚠️ want.parameters 为空');
    }
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, TAG, '========== onBackground 触发 ==========');
    
    // 保存当前播放位置
    audioManager.savePlaybackPosition();
    hilog.info(DOMAIN, TAG, '已保存音乐播放位置');
    
    // 🔥 关键：主动更新所有卡片，实现实时同步
    this.updateAllForms();
  }

  /**
   * 更新所有服务卡片
   * 🔥 强硬手段：优先从 AppStorage（内存）读取实时状态，fallback 到 preferences
   */
  private async updateAllForms(): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, '========== 🔄 开始更新所有卡片 ==========');
      
      // 🔥 关键：使用应用级别的 context，确保与 FormAbility 共享同一存储
      const appContext = this.context.getApplicationContext();
      const dataPreferences: preferences.Preferences = await preferences.getPreferences(appContext, 'formIds');
      const formIdsStr: string = await dataPreferences.get('ids', '[]') as string;
      const formIds: Array<string> = JSON.parse(formIdsStr);
      
      hilog.info(DOMAIN, TAG, `📋 读取到 ${formIds.length} 个卡片ID: ${JSON.stringify(formIds)}`);
      
      if (formIds.length === 0) {
        hilog.warn(DOMAIN, TAG, '⚠️ 没有已添加的卡片，跳过更新');
        hilog.info(DOMAIN, TAG, '💡 提示：请先长按应用图标添加服务卡片到桌面');
        return;
      }
      
      // 🔥 关键：优先从 AppStorage 读取实时状态（零延迟）
      let gameState: SavedGameState | null = AppStorage.get<SavedGameState>('currentGameState') || null;
      
      if (gameState) {
        hilog.info(DOMAIN, TAG, '⚡ 从 AppStorage 读取到实时游戏状态');
        hilog.info(DOMAIN, TAG, `   - 模式: ${gameState.gameMode}`);
        hilog.info(DOMAIN, TAG, `   - 步数: ${gameState.moveCount}`);
        hilog.info(DOMAIN, TAG, `   - 用时: ${gameState.timeElapsed}秒`);
        hilog.info(DOMAIN, TAG, `   - 进行中: ${gameState.isPlaying}`);
      } else {
        // Fallback: 从 preferences 读取持久化状态
        hilog.info(DOMAIN, TAG, '💾 AppStorage无数据，从 preferences 读取...');
        gameState = await GameStorage.loadGameState();
        
        if (gameState) {
          hilog.info(DOMAIN, TAG, '📦 从 preferences 读取到游戏状态');
        } else {
          hilog.info(DOMAIN, TAG, '❌ 无游戏状态');
        }
      }
      
      // 🔥 根据游戏状态创建卡片数据
      let formData: FormDataContent;
      
      if (gameState && gameState.isPlaying) {
        // 有进行中的游戏
        const minutes = Math.floor(gameState.timeElapsed / 60);
        const seconds = gameState.timeElapsed % 60;
        const timeStr = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
        
        // 🔥 将英文模式转换为中文
        const gameModeChinese = gameState.gameMode === 'swap' ? '交换' : '滑动';
        
        formData = {
          title: '拼图游戏',
          gameMode: gameModeChinese,
          gridSize: `${gameState.gridSize}×${gameState.gridSize}`,
          moveCount: gameState.moveCount,
          timeElapsed: timeStr,
          hasActiveGame: true
        };
        
        hilog.info(DOMAIN, TAG, '📊 卡片将显示: 继续游戏 / 主题');
      } else {
        // 无游戏或游戏未进行中
        formData = {
          title: '拼图游戏',
          gameMode: '交换',
          gridSize: '3×3',
          moveCount: 0,
          timeElapsed: '00:00',
          hasActiveGame: false
        };
        
        hilog.info(DOMAIN, TAG, '📊 卡片将显示: 开始新游戏');
      }
      
      // 遍历所有卡片并更新
      for (const formId of formIds) {
        hilog.info(DOMAIN, TAG, `🔄 更新卡片: ${formId}`);
        
        try {
          await formProvider.updateForm(formId, formBindingData.createFormBindingData(formData));
          hilog.info(DOMAIN, TAG, `✅ 卡片 ${formId} 更新成功`);
        } catch (updateError) {
          const err = updateError as Error;
          hilog.error(DOMAIN, TAG, `❌ 卡片 ${formId} 更新失败：${JSON.stringify(updateError)}`);
          hilog.error(DOMAIN, TAG, `   详细信息：%{public}s`, err.message || '未知错误');
        }
      }
      
      hilog.info(DOMAIN, TAG, '========== ✅ 所有卡片更新完成 ==========');
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ 更新卡片过程出错: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 创建卡片数据
   */
  private createFormData(gameState: SavedGameState | null): FormDataContent {
    if (gameState && gameState.isPlaying) {
      // 有进行中的游戏
      const data: FormDataContent = {
        title: '拼图游戏',
        gameMode: gameState.gameMode === 'swap' ? '交换模式' : '华容道',
        gridSize: `${gameState.gridSize}×${gameState.gridSize}`,
        moveCount: gameState.moveCount,
        timeElapsed: this.formatTime(gameState.timeElapsed),
        hasActiveGame: true
      };
      return data;
    } else {
      // 无进行中的游戏
      const data: FormDataContent = {
        title: '拼图游戏',
        gameMode: '交换模式',
        gridSize: '3×3',
        moveCount: 0,
        timeElapsed: '00:00',
        hasActiveGame: false
      };
      return data;
    }
  }

  /**
   * 格式化时间
   */
  private formatTime(seconds: number): string {
    const mins: number = Math.floor(seconds / 60);
    const secs: number = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
}