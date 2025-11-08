import { connection } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 网络状态类型
 */
export enum NetworkStatus {
  CONNECTED = 'connected',
  DISCONNECTED = 'disconnected',
  UNKNOWN = 'unknown'
}

/**
 * 网络类型
 */
export enum NetworkType {
  WIFI = 'WIFI',
  CELLULAR = 'CELLULAR',
  ETHERNET = 'ETHERNET',
  UNKNOWN = 'UNKNOWN'
}

/**
 * 网络信息接口
 */
export interface NetworkInfo {
  status: NetworkStatus;
  type: NetworkType;
  isAvailable: boolean;
}

/**
 * 网络助手类
 * 提供网络状态检测、监听等功能
 */
export class NetworkHelper {
  private static instance: NetworkHelper;
  private netConnection: connection.NetConnection | null = null;

  private constructor() {
    this.initNetConnection();
  }

  /**
   * 获取单例实例
   */
  static getInstance(): NetworkHelper {
    if (!NetworkHelper.instance) {
      NetworkHelper.instance = new NetworkHelper();
    }
    return NetworkHelper.instance;
  }

  /**
   * 初始化网络连接监听
   */
  private initNetConnection(): void {
    try {
      this.netConnection = connection.createNetConnection();
      console.info('[NetworkHelper] 网络连接监听器初始化成功');
    } catch (error) {
      console.error('[NetworkHelper] 初始化网络监听失败:', error);
    }
  }

  /**
   * 检查是否有可用网络
   */
  async hasNetwork(): Promise<boolean> {
    try {
      const hasDefaultNet = await connection.hasDefaultNet();
      console.info(`[NetworkHelper] 默认网络状态: ${hasDefaultNet}`);
      return hasDefaultNet;
    } catch (error) {
      console.error('[NetworkHelper] 检查网络状态失败:', error);
      return false;
    }
  }

  /**
   * 获取当前网络信息
   */
  async getNetworkInfo(): Promise<NetworkInfo> {
    try {
      const hasNet = await this.hasNetwork();
      
      if (!hasNet) {
        return {
          status: NetworkStatus.DISCONNECTED,
          type: NetworkType.UNKNOWN,
          isAvailable: false
        };
      }

      // 获取默认网络
      const netHandle = await connection.getDefaultNet();
      const netCapabilities = await connection.getNetCapabilities(netHandle);
      
      // 判断网络类型
      let networkType = NetworkType.UNKNOWN;
      if (netCapabilities.bearerTypes.includes(connection.NetBearType.BEARER_WIFI)) {
        networkType = NetworkType.WIFI;
      } else if (netCapabilities.bearerTypes.includes(connection.NetBearType.BEARER_CELLULAR)) {
        networkType = NetworkType.CELLULAR;
      } else if (netCapabilities.bearerTypes.includes(connection.NetBearType.BEARER_ETHERNET)) {
        networkType = NetworkType.ETHERNET;
      }

      console.info(`[NetworkHelper] 网络类型: ${networkType}`);

      return {
        status: NetworkStatus.CONNECTED,
        type: networkType,
        isAvailable: true
      };
    } catch (error) {
      console.error('[NetworkHelper] 获取网络信息失败:', error);
      return {
        status: NetworkStatus.UNKNOWN,
        type: NetworkType.UNKNOWN,
        isAvailable: false
      };
    }
  }

  /**
   * 监听网络状态变化
   */
  onNetworkChange(callback: (isAvailable: boolean) => void): void {
    if (!this.netConnection) {
      console.warn('[NetworkHelper] 网络监听器未初始化');
      return;
    }

    try {
      // 监听网络可用
      this.netConnection.on('netAvailable', (netHandle: connection.NetHandle) => {
        console.info('[NetworkHelper] 网络已连接:', netHandle.netId);
        callback(true);
      });

      // 监听网络丢失
      this.netConnection.on('netLost', (netHandle: connection.NetHandle) => {
        console.warn('[NetworkHelper] 网络已断开:', netHandle.netId);
        callback(false);
      });

      // 注册默认网络
      this.netConnection.register((error: BusinessError) => {
        if (error) {
          console.error('[NetworkHelper] 注册网络监听失败:', error);
        } else {
          console.info('[NetworkHelper] 网络监听已启动');
        }
      });
    } catch (error) {
      console.error('[NetworkHelper] 设置网络监听失败:', error);
    }
  }

  /**
   * 取消网络监听
   */
  offNetworkChange(): void {
    if (this.netConnection) {
      try {
        this.netConnection.unregister((error: BusinessError) => {
          if (error) {
            console.error('[NetworkHelper] 取消网络监听失败:', error);
          } else {
            console.info('[NetworkHelper] 网络监听已停止');
          }
        });
      } catch (error) {
        console.error('[NetworkHelper] 取消监听异常:', error);
      }
    }
  }

  /**
   * 诊断网络问题
   */
  async diagnoseNetwork(): Promise<string> {
    const info = await this.getNetworkInfo();
    
    if (!info.isAvailable) {
      return '网络不可用，请检查网络连接';
    }

    switch (info.type) {
      case NetworkType.WIFI:
        return 'WIFI已连接';
      case NetworkType.CELLULAR:
        return '移动网络已连接';
      case NetworkType.ETHERNET:
        return '以太网已连接';
      default:
        return '网络类型未知';
    }
  }
}

