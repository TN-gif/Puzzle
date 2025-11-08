import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { http } from '@kit.NetworkKit';
import { resourceManager } from '@kit.LocalizationKit';
import { NetworkHelper } from './NetworkHelper';
import { BusinessError } from '@kit.BasicServicesKit';

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
   * 从rawfile路径转换为PixelMap
   * @param rawfilePath rawfile路径（如：images/xxx.jpg）
   * @returns PixelMap对象
   */
  static async rawfileToPixelMap(rawfilePath: string): Promise<image.PixelMap> {
    try {
      // 获取context从AppStorage
      const context = AppStorage.get<resourceManager.ResourceManager>('resourceManager');
      if (!context) {
        throw new Error('ResourceManager未初始化');
      }
      
      // 从rawfile读取数据
      const resourceMgr = context;
      const rawfileData = await resourceMgr.getRawFileContent(rawfilePath);
      
      // 创建ImageSource
      const imageSource = image.createImageSource(rawfileData.buffer);
      const pixelMap = await imageSource.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      });
      return pixelMap;
    } catch (error) {
      console.error('Rawfile转PixelMap失败:', error);
      if (error instanceof Error) {
        throw error;
      }
      throw new Error('Rawfile转PixelMap失败: ' + String(error));
    }
  }

  /**
   * 从网络URL下载并转换为PixelMap（带重试机制）
   * @param url 图片URL
   * @param retryCount 重试次数（默认3次）
   * @returns PixelMap对象
   */
  static async urlToPixelMap(url: string, retryCount: number = 3): Promise<image.PixelMap> {
    // 1. 尝试检查网络状态（不阻塞，仅用于日志）
    try {
      const networkHelper = NetworkHelper.getInstance();
      const networkInfo = await networkHelper.getNetworkInfo();
      console.info(`[UriConverter] 网络状态: ${networkInfo.type}, ${networkInfo.status}`);
    } catch (error) {
      // 网络检查失败不影响下载，某些模拟器环境下可能无法检查网络状态
      console.warn('[UriConverter] 网络状态检查失败，但继续尝试下载:', error);
    }

    // 2. 带重试的下载逻辑
    let lastError: Error | null = null;
    
    for (let attempt = 1; attempt <= retryCount; attempt++) {
      try {
        console.info(`[UriConverter] 第${attempt}次尝试下载: ${url}`);
        
        const pixelMap = await UriConverter.downloadImage(url);
        
        console.info(`[UriConverter] 下载成功！尝试次数: ${attempt}`);
        return pixelMap;
        
      } catch (error) {
        lastError = error as Error;
        console.warn(`[UriConverter] 第${attempt}次下载失败:`, error);
        
        // 如果不是最后一次尝试，等待后重试
        if (attempt < retryCount) {
          const delayMs = UriConverter.getRetryDelay(attempt);
          console.info(`[UriConverter] ${delayMs}ms后重试...`);
          await UriConverter.sleep(delayMs);
        }
      }
    }

    // 所有重试都失败
    const errorMessage = UriConverter.parseHttpError(lastError);
    console.error(`[UriConverter] 下载彻底失败（重试${retryCount}次）: ${errorMessage}`);
    throw new Error(errorMessage);
  }

  /**
   * 实际的图片下载逻辑
   */
  private static async downloadImage(url: string): Promise<image.PixelMap> {
    const httpRequest = http.createHttp();
    
    try {
      // 发送HTTP请求（增加超时时间）
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: 15000,  // 连接超时15秒
        readTimeout: 30000,      // 读取超时30秒
        header: {
          'User-Agent': 'HarmonyOS-PuzzleGame/1.0',
          'Accept': 'image/*'
        }
      });

      console.info(`[UriConverter] HTTP响应码: ${response.responseCode}`);

      // 检查响应状态
      if (response.responseCode === 200 && response.result) {
        // 将ArrayBuffer转换为ImageSource
        const imageSource = image.createImageSource(response.result as ArrayBuffer);
        
        // 创建PixelMap
        const pixelMap = await imageSource.createPixelMap({
          desiredPixelFormat: image.PixelMapFormat.RGBA_8888
        });
        
        return pixelMap;
      } else if (response.responseCode === 403) {
        throw new Error('访问被拒绝(403)，可能需要配置代理');
      } else if (response.responseCode === 404) {
        throw new Error('图片不存在(404)');
      } else if (response.responseCode >= 500) {
        throw new Error(`服务器错误(${response.responseCode})`);
      } else {
        throw new Error(`HTTP请求失败: ${response.responseCode}`);
      }
    } finally {
      // 确保关闭HTTP连接
      httpRequest.destroy();
    }
  }

  /**
   * 计算重试延迟（指数退避）
   */
  private static getRetryDelay(attemptNumber: number): number {
    // 指数退避：1秒、2秒、4秒
    const baseDelay = 1000;
    const delay = baseDelay * Math.pow(2, attemptNumber - 1);
    // 添加随机抖动（0-500ms）
    const jitter = Math.random() * 500;
    return delay + jitter;
  }

  /**
   * 休眠函数
   */
  private static sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * 解析HTTP错误信息
   */
  private static parseHttpError(error: Error | null): string {
    if (!error) {
      return '未知网络错误';
    }

    const errorMsg = error.message || String(error);
    
    // 根据错误码提供友好提示
    if (errorMsg.includes('2300006')) {
      return '网络连接失败：DNS解析错误，请检查网络设置';
    } else if (errorMsg.includes('2300007')) {
      return '网络连接失败：无法连接到服务器，请检查网络或代理设置';
    } else if (errorMsg.includes('2300008')) {
      return '网络连接失败：服务器返回数据异常';
    } else if (errorMsg.includes('2300009')) {
      return '网络连接失败：请求超时，请检查网络速度';
    } else if (errorMsg.includes('timeout')) {
      return '网络请求超时，请检查网络连接';
    } else if (errorMsg.includes('403')) {
      return '访问被拒绝，可能需要配置网络代理';
    } else if (errorMsg.includes('404')) {
      return '图片资源不存在';
    } else if (errorMsg.includes('网络不可用')) {
      return errorMsg;
    } else {
      return `网络错误: ${errorMsg}`;
    }
  }
}

