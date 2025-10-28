import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { GameState } from '../models/GameState';

/**
 * 保存的游戏状态接口
 */
export interface SavedGameState {
  gameMode: string;
  gridSize: number;
  moveCount: number;
  timeElapsed: number;
  isPlaying: boolean;
}

/**
 * 最佳记录接口
 */
export interface BestRecord {
  moveCount: number;
  timeElapsed: number;
}

/**
 * 游戏数据持久化工具
 * 符合ArkTS规范：使用AppStorage获取context
 */
export class GameStorage {
  private static readonly PREFERENCES_NAME = 'puzzle_game_prefs';
  private static readonly KEY_GAME_STATE = 'game_state';
  private static readonly KEY_BEST_RECORD = 'best_record';

  /**
   * 从AppStorage获取context
   */
  private static getContext(): common.UIAbilityContext {
    const context = AppStorage.get<common.UIAbilityContext>('context');
    if (!context) {
      throw new Error('Context未初始化，请确保在EntryAbility中已调用AppStorage.setOrCreate');
    }
    return context;
  }

  /**
   * 保存游戏状态
   */
  static async saveGameState(state: SavedGameState): Promise<void> {
    try {
      const context = GameStorage.getContext();
      const prefs = await preferences.getPreferences(context, GameStorage.PREFERENCES_NAME);
      await prefs.put(GameStorage.KEY_GAME_STATE, JSON.stringify(state));
      await prefs.flush();
      console.info('游戏状态已保存');
    } catch (error) {
      console.error('保存游戏状态失败:', error);
    }
  }

  /**
   * 读取游戏状态
   */
  static async loadGameState(): Promise<SavedGameState | null> {
    try {
      const context = GameStorage.getContext();
      const prefs = await preferences.getPreferences(context, GameStorage.PREFERENCES_NAME);
      const stateStr = await prefs.get(GameStorage.KEY_GAME_STATE, '');
      
      if (stateStr) {
        return JSON.parse(stateStr as string) as SavedGameState;
      }
      return null;
    } catch (error) {
      console.error('读取游戏状态失败:', error);
      return null;
    }
  }

  /**
   * 清除游戏状态
   */
  static async clearGameState(): Promise<void> {
    try {
      const context = GameStorage.getContext();
      const prefs = await preferences.getPreferences(context, GameStorage.PREFERENCES_NAME);
      await prefs.delete(GameStorage.KEY_GAME_STATE);
      await prefs.flush();
      console.info('游戏状态已清除');
    } catch (error) {
      console.error('清除游戏状态失败:', error);
    }
  }

  /**
   * 保存最佳记录
   */
  static async saveBestRecord(gridSize: number, moveCount: number, timeElapsed: number): Promise<void> {
    try {
      const context = GameStorage.getContext();
      const prefs = await preferences.getPreferences(context, GameStorage.PREFERENCES_NAME);
      const key = `best_${gridSize}x${gridSize}`;
      
      // 读取现有记录
      const existing = await prefs.get(key, '');
      let shouldSave = true;
      
      if (existing) {
        const existingRecord = JSON.parse(existing as string) as BestRecord;
        // 只有更好的成绩才保存（更少步数或更短时间）
        if (existingRecord.moveCount < moveCount || existingRecord.timeElapsed < timeElapsed) {
          shouldSave = false;
        }
      }
      
      if (shouldSave) {
        await prefs.put(key, JSON.stringify({ moveCount, timeElapsed }));
        await prefs.flush();
        console.info('最佳记录已更新');
      }
    } catch (error) {
      console.error('保存最佳记录失败:', error);
    }
  }

  /**
   * 读取最佳记录
   */
  static async loadBestRecord(gridSize: number): Promise<BestRecord | null> {
    try {
      const context = GameStorage.getContext();
      const prefs = await preferences.getPreferences(context, GameStorage.PREFERENCES_NAME);
      const key = `best_${gridSize}x${gridSize}`;
      const recordStr = await prefs.get(key, '');
      
      if (recordStr) {
        return JSON.parse(recordStr as string) as BestRecord;
      }
      return null;
    } catch (error) {
      console.error('读取最佳记录失败:', error);
      return null;
    }
  }
}

