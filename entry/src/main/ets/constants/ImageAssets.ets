/**
 * 预设图片资源接口
 */
export interface PresetImage {
  id: number;
  name: string;
  resource: Resource;
}

/**
 * 角色信息接口
 */
export interface CharacterInfo {
  id: string;
  name: string;
  displayImage: string;  // 角色显示图路径
  images: string[];      // 该角色的所有拼图图片路径
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
 * 图片资源路径常量
 */
export class ImageAssets {
  // 预设图片资源（保留兼容旧代码）
  static readonly PRESET_IMAGES: PresetImage[] = [
    {
      id: 1,
      name: '风景',
      resource: $r('app.media.background')
    },
    {
      id: 2,
      name: '图标',
      resource: $r('app.media.foreground')
    },
    {
      id: 3,
      name: '启动图',
      resource: $r('app.media.startIcon')
    }
  ];

  // 角色信息配置
  static readonly CHARACTERS: CharacterInfo[] = [
    {
      id: 'laite',
      name: '莱特',
      displayImage: 'images/choose character/莱特角色显示图.jpg',
      images: [
        'images/Lai Te/莱特1.jpg',
        'images/Lai Te/莱特2.jpg',
        'images/Lai Te/莱特3.jpg',
        'images/Lai Te/莱特4.jpg',
        'images/Lai Te/莱特5.jpg',
        'images/Lai Te/莱特6.jpg'
      ]
    },
    {
      id: 'weiweian',
      name: '薇薇安',
      displayImage: 'images/choose character/薇薇安角色显示图.png',
      images: [
        'images/Wei weian/薇薇安1.jpg',
        'images/Wei weian/薇薇安2.jpg',
        'images/Wei weian/薇薇安3.jpg',
        'images/Wei weian/薇薇安4.jpg',
        'images/Wei weian/薇薇安5.jpg',
        'images/Wei weian/薇薇安6.jpg',
        'images/Wei weian/薇薇安7.jpg',
        'images/Wei weian/薇薇安8.jpg'
      ]
    }
  ];

  // 邦布专辑图片
  static readonly BANGBU_IMAGES: string[] = [
    'images/Bang Bu/邦布1.jpg',
    'images/Bang Bu/邦布2.jpg',
    'images/Bang Bu/邦布3.jpg',
    'images/Bang Bu/邦布4.jpg',
    'images/Bang Bu/邦布5.jpg',
    'images/Bang Bu/邦布6.jpg',
    'images/Bang Bu/邦布7.jpg',
    'images/Bang Bu/邦布8.jpg',
    'images/Bang Bu/邦布9.jpg'
  ];

  // 背景图片路径
  static readonly BACKGROUNDS: BackgroundPaths = {
    ENTRY_PAGE: 'images/主页面背景图.jpg',
    THEME_SELECTION: 'images/主题选择页面背景.jpg',
    OTHER_PAGES: 'images/其余页面背景图.png'
  };

  // 图标路径
  static readonly ICONS: IconPaths = {
    BACK: 'images/icon/返回.png'
  };

  /**
   * 根据角色ID获取角色信息
   */
  static getCharacterById(id: string): CharacterInfo | undefined {
    return ImageAssets.CHARACTERS.find((char: CharacterInfo) => char.id === id);
  }

  /**
   * 获取角色显示图路径
   */
  static getCharacterDisplayImage(id: string): string {
    const character = ImageAssets.getCharacterById(id);
    return character ? character.displayImage : '';
  }

  /**
   * 获取角色图片列表
   */
  static getCharacterImages(id: string): string[] {
    const character = ImageAssets.getCharacterById(id);
    return character ? character.images : [];
  }
}
