import { http } from '@kit.NetworkKit';
import { ApiConstants } from '../constants/ApiConstants';

/**
 * 图片数据接口
 */
export interface ImageData {
  id: number;
  previewURL: string;
  webformatURL: string;
  largeImageURL: string;
  tags: string;
}

/**
 * Pixabay API 响应接口
 */
interface PixabayResponse {
  total: number;
  totalHits: number;
  hits: ImageData[];
}

/**
 * 网络图片服务类
 */
export class NetworkImageService {
  /**
   * 搜索图片
   * @param keyword 关键字
   * @param page 页码
   * @returns 图片数据数组
   */
  static async searchImages(keyword: string, page: number = 1): Promise<ImageData[]> {
    try {
      // 构造请求URL
      const url = `${ApiConstants.PIXABAY_BASE_URL}?key=${ApiConstants.PIXABAY_API_KEY}&q=${encodeURIComponent(keyword)}&image_type=photo&per_page=20&page=${page}`;

      // 创建HTTP请求
      const httpRequest = http.createHttp();
      
      // 发送GET请求
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: 10000,
        readTimeout: 10000
      });

      // 解析响应
      if (response.responseCode === 200) {
        const resultStr = response.result as string;
        const result: PixabayResponse = JSON.parse(resultStr) as PixabayResponse;
        
        if (result && result.hits && Array.isArray(result.hits)) {
          return result.hits;
        }
      }

      console.error('搜索图片失败:', response.responseCode);
      return [];
    } catch (error) {
      console.error('搜索图片异常:', error);
      return [];
    }
  }

  /**
   * 获取随机图片
   * @returns 图片数据数组
   */
  static async getRandomImages(): Promise<ImageData[]> {
    // 随机选择一个关键字
    const randomKeyword = ApiConstants.DEFAULT_KEYWORDS[
      Math.floor(Math.random() * ApiConstants.DEFAULT_KEYWORDS.length)
    ];
    
    return await NetworkImageService.searchImages(randomKeyword);
  }
}

