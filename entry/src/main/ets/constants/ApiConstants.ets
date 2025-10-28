/**
 * API配置常量
 */
export class ApiConstants {
  // Pixabay API配置
  // 获取API Key: https://pixabay.com/api/docs/
  // 注册后在 https://pixabay.com/api/docs/ 页面获取你的API Key
  static readonly PIXABAY_API_KEY = '52975196-3f8e0640643de588511b69447';  // 请替换为你的API Key
  static readonly PIXABAY_BASE_URL = 'https://pixabay.com/api/';
  
  // 默认搜索关键字
  static readonly DEFAULT_KEYWORDS = [
    '自然', '动物', '城市', '美食', '风景',
    'nature', 'animal', 'city', 'food', 'landscape'
  ];
}

