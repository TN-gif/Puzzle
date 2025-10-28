/**
 * 模式选项接口
 */
export interface ModeOption {
  label: string;
  value: string;
  desc: string;
}

/**
 * 难度选项接口
 */
export interface DifficultyOption {
  label: string;
  value: number;
}

/**
 * 游戏模式接口
 */
export interface GameModeConfig {
  HUARONG: string;
  SWAP: string;
}

/**
 * 动画时长配置接口
 */
export interface AnimationConfig {
  TILE_MOVE: number;
  SHUFFLE: number;
  WIN: number;
  PEEK_FADE: number;
}

/**
 * 颜色配置接口
 */
export interface ColorConfig {
  PRIMARY: string;
  BACKGROUND: string;
  TILE_BG: string;
  EMPTY_BG: string;
  TEXT: string;
  TEXT_OVERLAY: string;
}

/**
 * 游戏模式常量类
 */
export class GameMode {
  static readonly HUARONG: string = 'huarong';    // 华容道模式
  static readonly SWAP: string = 'swap';           // 自由交换模式
}

/**
 * 动画时长配置类
 */
export class AnimationDuration {
  static readonly TILE_MOVE: number = 200;        // 方块移动动画
  static readonly SHUFFLE: number = 50;           // 洗牌动画延迟
  static readonly WIN: number = 300;              // 胜利动画
  static readonly PEEK_FADE: number = 200;        // 偷看原图淡入淡出
}

/**
 * 颜色配置类
 */
export class Colors {
  static readonly PRIMARY: string = '#1890FF';
  static readonly BACKGROUND: string = '#F5F5F5';
  static readonly TILE_BG: string = '#FFFFFF';
  static readonly EMPTY_BG: string = '#E8E8E8';
  static readonly TEXT: string = '#333333';
  static readonly TEXT_OVERLAY: string = '#FFFFFF';
}

/**
 * 游戏常量定义
 * 符合ArkTS规范：使用静态常量类和明确类型
 */
export class GameConstants {
  // 游戏模式常量
  static readonly GAME_MODE: GameModeConfig = {
    HUARONG: GameMode.HUARONG,
    SWAP: GameMode.SWAP
  };

  // 模式选项
  static readonly MODE_OPTIONS: ModeOption[] = [
    { label: '华容道模式', value: GameMode.HUARONG, desc: '经典玩法，移动方块到空格' },
    { label: '自由交换模式', value: GameMode.SWAP, desc: '拖拽任意方块交换位置' }
  ];

  // 难度选项
  static readonly DIFFICULTY_OPTIONS: DifficultyOption[] = [
    { label: '简单 (3×3)', value: 3 },
    { label: '中等 (4×4)', value: 4 },
    { label: '困难 (5×5)', value: 5 }
  ];

  // 动画时长配置
  static readonly ANIMATION_DURATION: AnimationConfig = {
    TILE_MOVE: AnimationDuration.TILE_MOVE,
    SHUFFLE: AnimationDuration.SHUFFLE,
    WIN: AnimationDuration.WIN,
    PEEK_FADE: AnimationDuration.PEEK_FADE
  };

  // 方块间隙
  static readonly GRID_GAP: number = 4;

  // 打乱次数
  static readonly SHUFFLE_TIMES: number = 100;

  // 颜色配置
  static readonly COLORS: ColorConfig = {
    PRIMARY: Colors.PRIMARY,
    BACKGROUND: Colors.BACKGROUND,
    TILE_BG: Colors.TILE_BG,
    EMPTY_BG: Colors.EMPTY_BG,
    TEXT: Colors.TEXT,
    TEXT_OVERLAY: Colors.TEXT_OVERLAY
  };

  // 折叠屏断点
  static readonly BREAKPOINT_WIDTH: number = 600;

  // 音效配置
  static readonly SOUND_ENABLED: boolean = true;
}

