import { image } from '@kit.ImageKit';
import { TileData } from '../models/TileData';

/**
 * 图片分割工具类
 */
export class ImageSlicer {
  /**
   * 将图片切割为 N×N 的小图片
   * @param pixelMap 原始图片
   * @param gridSize 网格大小（3/4/5）
   * @returns 方块数据数组
   */
  static async sliceImage(pixelMap: image.PixelMap, gridSize: number): Promise<TileData[]> {
    const tiles: TileData[] = [];
    
    // 获取图片信息
    const imageInfo = await pixelMap.getImageInfo();
    const width = imageInfo.size.width;
    const height = imageInfo.size.height;
    
    // 计算每个方块的尺寸
    const tileWidth = Math.floor(width / gridSize);
    const tileHeight = Math.floor(height / gridSize);
    
    // 循环切割
    for (let row = 0; row < gridSize; row++) {
      for (let col = 0; col < gridSize; col++) {
        const index = row * gridSize + col;
        const isLast = (index === gridSize * gridSize - 1);
        
        if (isLast) {
          // 最后一个位置是空格
          tiles.push(new TileData(index, index, null, true));
        } else {
          // 裁剪区域
          const region: image.Region = {
            x: col * tileWidth,
            y: row * tileHeight,
            size: { width: tileWidth, height: tileHeight }
          };
          
          // 读取区域像素数据
          const bufferSize = tileWidth * tileHeight * 4; // RGBA 每像素4字节
          const buffer = new ArrayBuffer(bufferSize);
          
          // 构造PositionArea参数
          const positionArea: image.PositionArea = {
            pixels: buffer,
            offset: 0,
            stride: tileWidth * 4,
            region: region
          };
          
          await pixelMap.readPixels(positionArea);
          
          // 创建新的PixelMap
          const createOpts: image.InitializationOptions = {
            size: { width: tileWidth, height: tileHeight },
            pixelFormat: image.PixelMapFormat.RGBA_8888
          };
          const tilePM = await image.createPixelMap(buffer, createOpts);
          
          tiles.push(new TileData(index, index, tilePM, false));
        }
      }
    }
    
    return tiles;
  }
}

