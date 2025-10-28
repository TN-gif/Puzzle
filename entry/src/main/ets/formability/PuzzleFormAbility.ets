import { FormExtensionAbility, formBindingData } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { GameStorage, SavedGameState } from '../utils/GameStorage';

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
    console.info('[FormAbility] onAddForm');
    
    // 准备卡片数据
    const formData: FormDataContent = this.createDefaultFormData();

    // 异步加载游戏状态
    this.loadGameStateAsync(want.parameters?.['formId'] as string);

    // 返回FormBindingData
    return formBindingData.createFormBindingData(formData);
  }

  /**
   * 创建默认卡片数据
   */
  private createDefaultFormData(): FormDataContent {
    return {
      title: '拼图游戏',
      gameMode: '交换模式',
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
      gameMode: gameState.gameMode === 'swap' ? '交换模式' : '华容道',
      gridSize: `${gameState.gridSize}×${gameState.gridSize}`,
      moveCount: gameState.moveCount,
      timeElapsed: this.formatTime(gameState.timeElapsed),
      hasActiveGame: true
    };
  }

  /**
   * 异步加载游戏状态
   */
  private async loadGameStateAsync(formId: string): Promise<void> {
    try {
      const gameState = await GameStorage.loadGameState();
      
      if (gameState && gameState.isPlaying) {
        const formData: FormDataContent = this.createFormDataFromGameState(gameState);

        // 更新卡片 - 注意：updateForm需要在新版本SDK中查阅正确API
        // formBindingData 模块没有直接的 updateForm 方法
        // 可能需要使用其他方式或等待SDK文档
        console.info('[FormAbility] 游戏状态已加载:', formData);
      }
    } catch (error) {
      console.error('[FormAbility] 加载游戏状态失败:', error);
    }
  }

  /**
   * 删除卡片时调用
   */
  onRemoveForm(formId: string): void {
    console.info('[FormAbility] onRemoveForm, formId:', formId);
  }

  /**
   * 卡片更新时调用
   */
  onUpdateForm(formId: string): void {
    console.info('[FormAbility] onUpdateForm, formId:', formId);
    
    // 重新加载游戏状态并更新卡片
    this.loadGameStateAsync(formId);
  }

  /**
   * 卡片事件处理
   */
  onFormEvent(formId: string, message: string): void {
    console.info('[FormAbility] onFormEvent, formId:', formId, 'message:', message);
    
    if (message === 'continueGame') {
      // 处理"继续游戏"按钮点击
      // 这里可以拉起应用并恢复游戏
      console.info('[FormAbility] 继续游戏');
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

