import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { http } from '@kit.NetworkKit';
import { resourceManager } from '@kit.LocalizationKit';

/**
 * URI转换工具类
 */
export class UriConverter {
  /**
   * 将相册URI转换为PixelMap
   * @param uri 图片URI
   * @returns PixelMap对象
   */
  static async uriToPixelMap(uri: string): Promise<image.PixelMap> {
    try {
      // 打开文件
      const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      
      // 创建ImageSource
      const imageSource = image.createImageSource(file.fd);
      
      // 创建PixelMap
      const pixelMap = await imageSource.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      });
      
      // 关闭文件
      fileIo.closeSync(file);
      
      return pixelMap;
    } catch (error) {
      console.error('URI转PixelMap失败:', error);
      if (error instanceof Error) {
        throw error;
      }
      throw new Error('URI转PixelMap失败: ' + String(error));
    }
  }

  /**
   * 从Resource转换为PixelMap
   * @param resource 资源对象
   * @returns PixelMap对象
   */
  static async resourceToPixelMap(resource: Resource): Promise<image.PixelMap> {
    try {
      // 获取context从AppStorage
      const context = AppStorage.get<resourceManager.ResourceManager>('resourceManager');
      if (!context) {
        throw new Error('ResourceManager未初始化');
      }
      
      // 从Resource获取媒体内容
      const resourceMgr = context;
      const mediaData = await resourceMgr.getMediaContent(resource);
      
      // 创建ImageSource
      const imageSource = image.createImageSource(mediaData.buffer);
      const pixelMap = await imageSource.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      });
      return pixelMap;
    } catch (error) {
      console.error('Resource转PixelMap失败:', error);
      if (error instanceof Error) {
        throw error;
      }
      throw new Error('Resource转PixelMap失败: ' + String(error));
    }
  }

  /**
   * 从网络URL下载并转换为PixelMap
   * @param url 图片URL
   * @returns PixelMap对象
   */
  static async urlToPixelMap(url: string): Promise<image.PixelMap> {
    try {
      // 创建HTTP请求
      const httpRequest = http.createHttp();
      
      // 下载图片
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: 10000,
        readTimeout: 30000
      });

      if (response.responseCode === 200 && response.result) {
        // 将ArrayBuffer转换为ImageSource
        const imageSource = image.createImageSource(response.result as ArrayBuffer);
        
        // 创建PixelMap
        const pixelMap = await imageSource.createPixelMap({
          desiredPixelFormat: image.PixelMapFormat.RGBA_8888
        });
        
        return pixelMap;
      } else {
        throw new Error(`HTTP请求失败: ${response.responseCode}`);
      }
    } catch (error) {
      console.error('URL转PixelMap失败:', error);
      if (error instanceof Error) {
        throw error;
      }
      throw new Error('URL转PixelMap失败: ' + String(error));
    }
  }
}

