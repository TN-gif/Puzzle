/**
 * 预设图片资源接口
 */
export interface PresetImage {
  id: number;
  name: string;
  resource: Resource;
}

/**
 * 图片资源路径常量
 */
export class ImageAssets {
  // 预设图片资源
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
}

