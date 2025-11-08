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
 * 圆角配置接口
 */
export interface BorderRadiusConfig {
  SMALL: number;
  MEDIUM: number;
  LARGE: number;
  PILL: number;
}

/**
 * 辉光效果配置接口
 */
export interface GlowConfig {
  RADIUS: number;
  COLOR: string;
  OPACITY: number;
}

/**
 * 辉光效果集合接口
 */
export interface GlowEffectConfig {
  PRIMARY: GlowConfig;
  SECONDARY: GlowConfig;
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
 * 荧光科技风颜色配置类
 * 高对比度暗黑模式 + 荧光绿点缀
 */
export class Colors {
  // 主色系 - 荧光绿
  static readonly ACCENT_PRIMARY: string = '#24FF00';      // 主荧光绿
  static readonly ACCENT_SECONDARY: string = '#E0FF1A';    // 次荧光黄绿
  
  // 背景色系 - 极暗模式
  static readonly BACKGROUND_BASE: string = '#121212';     // 主背景 - 近黑色
  static readonly SURFACE: string = '#232323';             // 卡片表面 - 深炭灰
  static readonly SURFACE_ELEVATED: string = '#2A2A2A';    // 悬浮表面
  
  // 文字色系
  static readonly TEXT_PRIMARY: string = '#FFFFFF';        // 主文字 - 纯白
  static readonly TEXT_SECONDARY: string = '#B3B3B3';      // 次文字 - 中灰
  static readonly TEXT_DISABLED: string = '#666666';       // 禁用文字
  
  // 功能色系
  static readonly SUCCESS: string = '#24FF00';             // 成功 - 荧光绿
  static readonly WARNING: string = '#E0FF1A';             // 警告 - 荧光黄绿
  static readonly DANGER: string = '#FF4D4F';              // 危险 - 红色
  
  // 游戏相关
  static readonly TILE_BG: string = '#2A2A2A';             // 方块背景
  static readonly EMPTY_BG: string = '#1A1A1A';            // 空格背景
  
  // 兼容旧属性
  static readonly PRIMARY: string = '#24FF00';
  static readonly BACKGROUND: string = '#121212';
  static readonly TEXT: string = '#FFFFFF';
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

  // 荧光科技风UI配置
  static readonly BORDER_RADIUS: BorderRadiusConfig = {
    SMALL: 12,
    MEDIUM: 16,
    LARGE: 24,
    PILL: 100  // 胶囊形状
  };

  // 辉光效果配置（霓虹灯效果）
  static readonly GLOW_EFFECT: GlowEffectConfig = {
    // 荧光绿辉光
    PRIMARY: {
      RADIUS: 20,
      COLOR: '#24FF00',
      OPACITY: 0.6
    },
    // 次要辉光
    SECONDARY: {
      RADIUS: 16,
      COLOR: '#E0FF1A',
      OPACITY: 0.5
    }
  };
}

