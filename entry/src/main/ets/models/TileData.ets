import { image } from '@kit.ImageKit';

/**
 * 方块数据模型
 */
export class TileData {
  id: number;                    // 方块ID（原始位置，用于胜利判断）
  currentIndex: number;          // 当前位置索引
  pixelMap: image.PixelMap | null;  // 方块图片
  isEmpty: boolean;              // 是否为空格
  isHint: boolean;               // 是否为提示方块（交换模式专用）

  constructor(id: number, currentIndex: number, pixelMap: image.PixelMap | null, isEmpty: boolean = false, isHint: boolean = false) {
    this.id = id;
    this.currentIndex = currentIndex;
    this.pixelMap = pixelMap;
    this.isEmpty = isEmpty;
    this.isHint = isHint;
  }
}


