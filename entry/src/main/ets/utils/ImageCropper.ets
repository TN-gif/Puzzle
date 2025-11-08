import { image } from '@kit.ImageKit';

/**
 * 图片裁剪工具类
 */
export class ImageCropper {
  /**
   * 将图片裁剪为正方形（取中心区域）
   * @param pixelMap 原始图片
   * @returns 裁剪后的正方形图片
   */
  static async cropToSquare(pixelMap: image.PixelMap): Promise<image.PixelMap> {
    try {
      // 获取图片信息
      const imageInfo = await pixelMap.getImageInfo();
      const width = imageInfo.size.width;
      const height = imageInfo.size.height;
      
      console.info(`[ImageCropper] 原始图片尺寸: ${width}x${height}`);
      
      // 如果已经是正方形，直接返回
      if (width === height) {
        console.info('[ImageCropper] 图片已经是正方形，无需裁剪');
        return pixelMap;
      }
      
      // 计算正方形边长（取较小值）
      const squareSize = Math.min(width, height);
      
      // 计算裁剪起始位置（中心裁剪）
      const offsetX = Math.floor((width - squareSize) / 2);
      const offsetY = Math.floor((height - squareSize) / 2);
      
      console.info(`[ImageCropper] 裁剪区域: x=${offsetX}, y=${offsetY}, size=${squareSize}x${squareSize}`);
      
      // 定义裁剪区域
      const region: image.Region = {
        x: offsetX,
        y: offsetY,
        size: { width: squareSize, height: squareSize }
      };
      
      // 读取区域像素数据
      const bufferSize = squareSize * squareSize * 4; // RGBA 每像素4字节
      const buffer = new ArrayBuffer(bufferSize);
      
      // 构造PositionArea参数
      const positionArea: image.PositionArea = {
        pixels: buffer,
        offset: 0,
        stride: squareSize * 4,
        region: region
      };
      
      await pixelMap.readPixels(positionArea);
      
      // 创建新的正方形PixelMap
      const createOpts: image.InitializationOptions = {
        size: { width: squareSize, height: squareSize },
        pixelFormat: image.PixelMapFormat.RGBA_8888
      };
      
      const squarePixelMap = await image.createPixelMap(buffer, createOpts);
      
      console.info('[ImageCropper] ✅ 裁剪完成，生成正方形图片');
      
      return squarePixelMap;
      
    } catch (error) {
      console.error('[ImageCropper] ❌ 裁剪失败:', error);
      // 裁剪失败时返回原图
      return pixelMap;
    }
  }
}

