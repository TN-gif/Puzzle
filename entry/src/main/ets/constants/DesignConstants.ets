import { ScreenState } from '../utils/ScreenStateManager';

/**
 * 按钮配置接口
 */
interface ButtonConfig {
  WIDTH: number;
  HEIGHT: number;
  FONT_SIZE: number;
  BORDER_WIDTH: number;
  BORDER_RADIUS: number;
}

/**
 * 返回按钮配置接口
 */
interface BackButtonConfig {
  SIZE: number;
  ICON_SIZE: number;
}

/**
 * 按钮配置集合接口
 */
interface ButtonConfigMap {
  TRIPLE: ButtonConfig;
  DOUBLE: ButtonConfig;
  SINGLE: ButtonConfig;
}

/**
 * 返回按钮配置集合接口
 */
interface BackButtonConfigMap {
  TRIPLE: BackButtonConfig;
  DOUBLE: BackButtonConfig;
  SINGLE: BackButtonConfig;
}

/**
 * 背景图片路径接口
 */
interface BackgroundPaths {
  ENTRY_PAGE: string;
  THEME_SELECTION: string;
  OTHER_PAGES: string;
}

/**
 * 图标路径接口
 */
interface IconPaths {
  BACK: string;
}

/**
 * 颜色配置接口
 */
interface ColorConfig {
  BUTTON_BG: string;
  BUTTON_TEXT: string;
  BUTTON_BORDER: string;
}

/**
 * 原型设计常量配置
 * 根据原型文档定义的尺寸规范
 */
export class DesignConstants {
  // 自定义字体路径
  static readonly CUSTOM_FONT_PATH: string = 'fonts/Muyao-Softbrush.ttf';
  
  // 背景图片路径
  static readonly BACKGROUND: BackgroundPaths = {
    ENTRY_PAGE: 'images/主页面背景图.jpg',
    THEME_SELECTION: 'images/主题选择页面背景.jpg',
    OTHER_PAGES: 'images/其余页面背景图.png'
  };

  // 返回图标
  static readonly ICON: IconPaths = {
    BACK: 'images/icon/返回.png'
  };

  // 通用按钮样式配置（按原型文档）
  // 注意：大多数页面在三种模式下都使用相同尺寸（254x74）
  // 只有 ThemeSelectionPage 有特殊尺寸，需要单独定义
  static readonly BUTTON: ButtonConfigMap = {
    TRIPLE: {
      WIDTH: 254,
      HEIGHT: 74,
      FONT_SIZE: 48,
      BORDER_WIDTH: 4,
      BORDER_RADIUS: 25
    },
    DOUBLE: {
      WIDTH: 254,
      HEIGHT: 74,
      FONT_SIZE: 48,
      BORDER_WIDTH: 4,
      BORDER_RADIUS: 25
    },
    SINGLE: {
      WIDTH: 254,
      HEIGHT: 74,
      FONT_SIZE: 48,
      BORDER_WIDTH: 4,
      BORDER_RADIUS: 25
    }
  };

  // 主题选择页面专用按钮配置（三种模式尺寸不同）
  static readonly THEME_BUTTON: ButtonConfigMap = {
    TRIPLE: {
      WIDTH: 254,
      HEIGHT: 74,
      FONT_SIZE: 48,
      BORDER_WIDTH: 4,
      BORDER_RADIUS: 25
    },
    DOUBLE: {
      WIDTH: 207,
      HEIGHT: 68,
      FONT_SIZE: 40,
      BORDER_WIDTH: 4,
      BORDER_RADIUS: 25
    },
    SINGLE: {
      WIDTH: 174,
      HEIGHT: 60,
      FONT_SIZE: 35,
      BORDER_WIDTH: 4,
      BORDER_RADIUS: 25
    }
  };

  // 游戏页面专用按钮配置（切换难度/切换模式按钮）
  static readonly GAME_WIDE_BUTTON: ButtonConfigMap = {
    TRIPLE: {
      WIDTH: 287,
      HEIGHT: 74,
      FONT_SIZE: 48,
      BORDER_WIDTH: 4,
      BORDER_RADIUS: 25
    },
    DOUBLE: {
      WIDTH: 287,
      HEIGHT: 74,
      FONT_SIZE: 48,
      BORDER_WIDTH: 4,
      BORDER_RADIUS: 25
    },
    SINGLE: {
      WIDTH: 206,
      HEIGHT: 65,
      FONT_SIZE: 35,
      BORDER_WIDTH: 4,
      BORDER_RADIUS: 25
    }
  };

  // 游戏页面小按钮配置（重新开始/偷看答案按钮）
  static readonly GAME_SMALL_BUTTON: ButtonConfigMap = {
    TRIPLE: {
      WIDTH: 254,
      HEIGHT: 74,
      FONT_SIZE: 48,
      BORDER_WIDTH: 4,
      BORDER_RADIUS: 25
    },
    DOUBLE: {
      WIDTH: 254,
      HEIGHT: 74,
      FONT_SIZE: 48,
      BORDER_WIDTH: 4,
      BORDER_RADIUS: 25
    },
    SINGLE: {
      WIDTH: 190,
      HEIGHT: 65,
      FONT_SIZE: 35,
      BORDER_WIDTH: 4,
      BORDER_RADIUS: 25
    }
  };

  // 返回按钮配置
  static readonly BACK_BUTTON: BackButtonConfigMap = {
    TRIPLE: {
      SIZE: 60,
      ICON_SIZE: 37
    },
    DOUBLE: {
      SIZE: 60,
      ICON_SIZE: 37
    },
    SINGLE: {
      SIZE: 35,
      ICON_SIZE: 20
    }
  };

  // 按钮颜色（原型设计中的白色按钮黑色文字）
  static readonly COLORS: ColorConfig = {
    BUTTON_BG: 'rgba(255, 255, 255, 0.91)',  // 91%不透明
    BUTTON_TEXT: '#000000',
    BUTTON_BORDER: 'transparent'  // 无边框颜色
  };
  
  // 返回按钮背景色
  static readonly BACK_BUTTON_BG = 'rgba(255, 255, 255, 0.9)';  // 90%不透明

  // 根据屏幕状态获取按钮配置
  static getButtonConfig(screenState: ScreenState): ButtonConfig {
    switch (screenState) {
      case ScreenState.TRIPLE:
        return DesignConstants.BUTTON.TRIPLE;
      case ScreenState.DOUBLE:
        return DesignConstants.BUTTON.DOUBLE;
      case ScreenState.SINGLE:
        return DesignConstants.BUTTON.SINGLE;
      default:
        return DesignConstants.BUTTON.TRIPLE;
    }
  }

  // 根据屏幕状态获取主题选择页面按钮配置
  static getThemeButtonConfig(screenState: ScreenState): ButtonConfig {
    switch (screenState) {
      case ScreenState.TRIPLE:
        return DesignConstants.THEME_BUTTON.TRIPLE;
      case ScreenState.DOUBLE:
        return DesignConstants.THEME_BUTTON.DOUBLE;
      case ScreenState.SINGLE:
        return DesignConstants.THEME_BUTTON.SINGLE;
      default:
        return DesignConstants.THEME_BUTTON.TRIPLE;
    }
  }

  // 根据屏幕状态获取游戏页面宽按钮配置（切换难度/切换模式）
  static getGameWideButtonConfig(screenState: ScreenState): ButtonConfig {
    switch (screenState) {
      case ScreenState.TRIPLE:
        return DesignConstants.GAME_WIDE_BUTTON.TRIPLE;
      case ScreenState.DOUBLE:
        return DesignConstants.GAME_WIDE_BUTTON.DOUBLE;
      case ScreenState.SINGLE:
        return DesignConstants.GAME_WIDE_BUTTON.SINGLE;
      default:
        return DesignConstants.GAME_WIDE_BUTTON.TRIPLE;
    }
  }

  // 根据屏幕状态获取游戏页面小按钮配置（重新开始/偷看答案）
  static getGameSmallButtonConfig(screenState: ScreenState): ButtonConfig {
    switch (screenState) {
      case ScreenState.TRIPLE:
        return DesignConstants.GAME_SMALL_BUTTON.TRIPLE;
      case ScreenState.DOUBLE:
        return DesignConstants.GAME_SMALL_BUTTON.DOUBLE;
      case ScreenState.SINGLE:
        return DesignConstants.GAME_SMALL_BUTTON.SINGLE;
      default:
        return DesignConstants.GAME_SMALL_BUTTON.TRIPLE;
    }
  }

  // 根据屏幕状态获取返回按钮配置
  static getBackButtonConfig(screenState: ScreenState): BackButtonConfig {
    switch (screenState) {
      case ScreenState.TRIPLE:
        return DesignConstants.BACK_BUTTON.TRIPLE;
      case ScreenState.DOUBLE:
        return DesignConstants.BACK_BUTTON.DOUBLE;
      case ScreenState.SINGLE:
        return DesignConstants.BACK_BUTTON.SINGLE;
      default:
        return DesignConstants.BACK_BUTTON.TRIPLE;
    }
  }
}
