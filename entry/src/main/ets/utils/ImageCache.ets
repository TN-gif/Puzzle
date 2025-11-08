import { image } from '@kit.ImageKit';

/**
 * 图片缓存工具类
 * 用于在页面间传递 PixelMap（因为路由参数无法直接传递）
 */
export class ImageCache {
  private static cachedPixelMap: image.PixelMap | null = null;
  
  /**
   * 缓存图片
   * @param pixelMap 要缓存的图片
   */
  static set(pixelMap: image.PixelMap): void {
    // 释放旧的缓存
    if (ImageCache.cachedPixelMap) {
      console.info('[ImageCache] 释放旧的缓存图片');
      ImageCache.cachedPixelMap.release();
    }
    
    ImageCache.cachedPixelMap = pixelMap;
    console.info('[ImageCache] ✅ 图片已缓存');
  }
  
  /**
   * 获取缓存的图片
   * @returns 缓存的图片，如果没有则返回null
   */
  static get(): image.PixelMap | null {
    return ImageCache.cachedPixelMap;
  }
  
  /**
   * 清除缓存
   */
  static clear(): void {
    if (ImageCache.cachedPixelMap) {
      console.info('[ImageCache] 清除缓存');
      ImageCache.cachedPixelMap.release();
      ImageCache.cachedPixelMap = null;
    }
  }
  
  /**
   * 检查是否有缓存
   * @returns 是否有缓存
   */
  static has(): boolean {
    return ImageCache.cachedPixelMap !== null;
  }
}

