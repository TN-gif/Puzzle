/**
 * API配置常量
 */
export class ApiConstants {
  // ============ 国内图片API（推荐使用） ============
  
  // 1. 必应每日壁纸API（推荐！无需密钥，稳定可靠）
  static readonly BING_IMAGE_URL: string = 'https://api.dujin.org/bing/1920.php';
  
  // 2. Lorem Picsum（国内可访问，随机图片）
  static readonly PICSUM_BASE_URL: string = 'https://picsum.photos';
  
  // 3. 随机风景图（国内API）
  static readonly RANDOM_IMAGE_APIS: string[] = [
    'https://api.dujin.org/bing/1920.php',           // 必应壁纸
    'https://api.ixiaowai.cn/gqapi/gqapi.php',       // 高清壁纸
    'https://api.ixiaowai.cn/mcapi/mcapi.php',       // 二次元图片
    'https://api.btstu.cn/sjbz/api.php?lx=fengjing', // 风景图片
    'https://api.btstu.cn/sjbz/api.php?lx=dongman',  // 动漫图片
  ];
  
  // 当前使用的API（可切换）
  static readonly CURRENT_RANDOM_API: string = ApiConstants.RANDOM_IMAGE_APIS[0];
  
  // ============ 国外图片API（需要代理） ============
  
  // Pixabay API配置（需要密钥）
  static readonly PIXABAY_API_KEY: string = '52975196-3f8e0640643de588511b69447';
  static readonly PIXABAY_BASE_URL: string = 'https://pixabay.com/api/';
  
  // Unsplash API配置（被墙，不推荐使用）
  static readonly UNSPLASH_BASE_URL: string = 'https://source.unsplash.com';
  
  // 默认搜索关键字
  static readonly DEFAULT_KEYWORDS: string[] = [
    '自然', '动物', '城市', '美食', '风景',
    'nature', 'animal', 'city', 'food', 'landscape'
  ];
}


