import { FormExtensionAbility, formBindingData, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { GameStorage, SavedGameState } from '../utils/GameStorage';
import { hilog } from '@kit.PerformanceAnalysisKit';

// 日志常量
const DOMAIN = 0xFE00;
const TAG = 'FormAbility';

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

/**
 * 拼图游戏万能卡片扩展能力
 */
export default class PuzzleFormAbility extends FormExtensionAbility {
  /**
   * 创建卡片时调用
   */
  onAddForm(want: Want): formBindingData.FormBindingData {
    hilog.info(DOMAIN, TAG, '========== onAddForm 调用 ==========');
    hilog.info(DOMAIN, TAG, 'want.parameters: %{public}s', JSON.stringify(want.parameters));
    
    // 尝试多种方式获取卡片ID
    const formId: string = (want.parameters?.['ohos.extra.param.key.form_identity'] as string) ||
                           (want.parameters?.['formId'] as string) ||
                           (want.parameters?.['id'] as string) || '';
    
    hilog.info(DOMAIN, TAG, '获取到的卡片ID: %{public}s', formId);
    
    if (formId) {
      // 🔥 立即开始保存，不等待完成（系统保证后台任务会执行）
      this.saveFormId(formId).then(() => {
        hilog.info(DOMAIN, TAG, '✅ 卡片ID保存完成');
      }).catch((error: Error) => {
        hilog.error(DOMAIN, TAG, '❌ 卡片ID保存失败: %{public}s', error.message);
      });
    } else {
      hilog.warn(DOMAIN, TAG, '⚠️ 无法获取卡片ID');
    }
    
    // 准备卡片数据
    const formData: FormDataContent = this.createDefaultFormData();

    // 异步加载游戏状态
    this.loadGameStateAsync(formId);

    // 返回FormBindingData
    return formBindingData.createFormBindingData(formData);
  }

  /**
   * 保存卡片ID到持久化存储
   */
  private async saveFormId(formId: string): Promise<void> {
    try {
      // 🔥 关键：使用应用级别的 context，确保与 EntryAbility 共享同一存储
      const appContext = this.context.getApplicationContext();
      const dataPreferences: preferences.Preferences = await preferences.getPreferences(appContext, 'formIds');
      
      // 读取现有的卡片ID列表
      const formIdsStr: string = await dataPreferences.get('ids', '[]') as string;
      const formIds: Array<string> = JSON.parse(formIdsStr);
      
      hilog.info(DOMAIN, TAG, '📖 读取到现有卡片ID: %{public}s', JSON.stringify(formIds));
      
      // 添加新ID
      if (!formIds.includes(formId)) {
        formIds.push(formId);
        await dataPreferences.put('ids', JSON.stringify(formIds));
        await dataPreferences.flush();
        hilog.info(DOMAIN, TAG, '✅ 卡片ID已保存: %{public}s 总数: %{public}d', formId, formIds.length);
        hilog.info(DOMAIN, TAG, '📋 当前所有卡片ID: %{public}s', JSON.stringify(formIds));
      } else {
        hilog.info(DOMAIN, TAG, 'ℹ️ 卡片ID已存在，跳过保存: %{public}s', formId);
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ 保存卡片ID失败: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 创建默认卡片数据
   */
  private createDefaultFormData(): FormDataContent {
    return {
      title: '拼图游戏',
      gameMode: '交换',
      gridSize: '3×3',
      moveCount: 0,
      timeElapsed: '00:00',
      hasActiveGame: false
    };
  }

  /**
   * 从游戏状态创建卡片数据
   */
  private createFormDataFromGameState(gameState: SavedGameState): FormDataContent {
    return {
      title: '拼图游戏',
      gameMode: gameState.gameMode === 'swap' ? '交换' : '滑动',
      gridSize: `${gameState.gridSize}×${gameState.gridSize}`,
      moveCount: gameState.moveCount,
      timeElapsed: this.formatTime(gameState.timeElapsed),
      hasActiveGame: true
    };
  }

  /**
   * 异步加载游戏状态并更新卡片
   */
  private async loadGameStateAsync(formId: string): Promise<void> {
    try {
      const gameState = await GameStorage.loadGameState();
      
      let formData: FormDataContent;
      
        if (gameState && gameState.isPlaying) {
          formData = this.createFormDataFromGameState(gameState);
          hilog.info(DOMAIN, TAG, '检测到进行中的游戏，更新卡片显示继续游戏');
        } else {
          formData = this.createDefaultFormData();
          hilog.info(DOMAIN, TAG, '无进行中的游戏，显示开始新游戏');
        }
  
        // 使用 formProvider.updateForm 更新卡片
        await formProvider.updateForm(formId, formBindingData.createFormBindingData(formData));
        hilog.info(DOMAIN, TAG, '卡片更新成功, formId: %{public}s', formId);
      } catch (error) {
        hilog.error(DOMAIN, TAG, '更新卡片失败: %{public}s', JSON.stringify(error));
      }
  }

  /**
   * 🔥 加载游戏状态并清理过期数据
   * 方案二：智能检测过期数据（超过24小时）
   */
  private async loadGameStateWithCleanupCheck(formId: string): Promise<void> {
    try {
      const gameState = await GameStorage.loadGameState();
      
      let formData: FormDataContent;
      
      if (gameState && gameState.isPlaying) {
        // 🔥 检测游戏是否过期（超过8分钟未更新）
        // 原因：清除后台时 onDestroy() 不会被调用，只能依赖系统定时刷新（5分钟）
        // 设置为 8 分钟确保下次刷新时一定触发清理
        const savedTime = gameState.timestamp || 0;
        const currentTime = Date.now();
        const hoursSinceUpdate = (currentTime - savedTime) / (1000 * 60 * 60);
        
        if (savedTime > 0 && hoursSinceUpdate > 0.133) {  // 0.133 小时 = 8 分钟
          hilog.warn(DOMAIN, TAG, '⚠️ 游戏数据过期（%.1f 小时未更新），清除状态', hoursSinceUpdate);
          
          // 清除过期游戏状态
          await GameStorage.clearGameState();
          
          // 显示"开始新游戏"
          formData = this.createDefaultFormData();
          hilog.info(DOMAIN, TAG, '📊 卡片显示: 开始新游戏（数据已过期）');
        } else {
          // 游戏状态有效
          formData = this.createFormDataFromGameState(gameState);
          hilog.info(DOMAIN, TAG, '📊 卡片显示: 继续游戏（数据有效，%.1f 小时前更新）', hoursSinceUpdate);
        }
      } else {
        formData = this.createDefaultFormData();
        hilog.info(DOMAIN, TAG, '📊 卡片显示: 开始新游戏（无游戏数据）');
      }

      // 更新卡片
      await formProvider.updateForm(formId, formBindingData.createFormBindingData(formData));
      hilog.info(DOMAIN, TAG, '✅ 卡片更新成功');
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ 更新卡片失败: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 删除卡片时调用
   */
  onRemoveForm(formId: string): void {
    hilog.info(DOMAIN, TAG, '========== onRemoveForm 调用 ==========');
    hilog.info(DOMAIN, TAG, '删除卡片ID: %{public}s', formId);
    
    // 从持久化存储移除卡片ID
    this.removeFormId(formId);
  }

  /**
   * 从持久化存储移除卡片ID
   */
  private async removeFormId(formId: string): Promise<void> {
    try {
      // 🔥 关键：使用应用级别的 context，确保与 EntryAbility 共享同一存储
      const appContext = this.context.getApplicationContext();
      const dataPreferences: preferences.Preferences = await preferences.getPreferences(appContext, 'formIds');
      
      // 读取现有的卡片ID列表
      const formIdsStr: string = await dataPreferences.get('ids', '[]') as string;
      const formIds: Array<string> = JSON.parse(formIdsStr);
      
      hilog.info(DOMAIN, TAG, '📖 删除前的卡片ID列表: %{public}s', JSON.stringify(formIds));
      
      // 移除ID
      const index: number = formIds.indexOf(formId);
      if (index > -1) {
        formIds.splice(index, 1);
        await dataPreferences.put('ids', JSON.stringify(formIds));
        await dataPreferences.flush();
        hilog.info(DOMAIN, TAG, '✅ 卡片ID已移除: %{public}s 剩余: %{public}d', formId, formIds.length);
        hilog.info(DOMAIN, TAG, '📋 删除后的卡片ID列表: %{public}s', JSON.stringify(formIds));
      } else {
        hilog.warn(DOMAIN, TAG, '⚠️ 要删除的卡片ID不存在: %{public}s', formId);
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, '❌ 移除卡片ID失败: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 卡片更新时调用
   */
  onUpdateForm(formId: string): void {
    hilog.info(DOMAIN, TAG, '========== onUpdateForm 触发（系统刷新）==========');
    hilog.info(DOMAIN, TAG, 'formId: %{public}s', formId);
    
    // 🔥 使用带过期检测的加载方法
    this.loadGameStateWithCleanupCheck(formId);
  }

  /**
   * 卡片事件处理
   * 注意：SDK 6.0.0(20) 中 FormExtensionContext 不支持 startAbility
   * 卡片点击启动应用需要通过系统默认行为实现
   */
  onFormEvent(formId: string, message: string): void {
    hilog.info(DOMAIN, TAG, 'onFormEvent, formId: %{public}s, message: %{public}s', formId, message);
    
    // 解析消息（明确类型）
    try {
      interface MessageParams {
        action: string;
      }
      const params: MessageParams = JSON.parse(message) as MessageParams;
      const action: string = params.action;
      
      if (action === 'launchApp' || action === 'continueGame') {
        hilog.info(DOMAIN, TAG, '收到启动请求，action: %{public}s', action);
        // 注意：FormExtensionContext 不支持直接启动应用
        // 应用启动需要依赖系统卡片点击的默认行为
      }
    } catch (e) {
      // 处理错误（catch 不能有类型注解）
      if (e instanceof Error) {
        hilog.error(DOMAIN, TAG, '解析消息失败: %{public}s', e.message);
      } else {
        hilog.error(DOMAIN, TAG, '未知错误: %{public}s', String(e));
      }
      
      // 记录原始消息
      hilog.info(DOMAIN, TAG, '原始消息: %{public}s', message);
    }
  }

  /**
   * 格式化时间
   */
  private formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
}

