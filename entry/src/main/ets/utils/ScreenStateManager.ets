import { display, window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 屏幕状态枚举
 */
export enum ScreenState {
  TRIPLE = 'triple',   // 三屏
  DOUBLE = 'double',   // 双屏
  SINGLE = 'single'    // 单屏
}

/**
 * 折叠屏状态管理器
 * 负责检测设备折叠状态并提供响应式回调
 * 实现基于官方最佳实践建议
 */
export class ScreenStateManager {
  private static instance: ScreenStateManager | null = null;
  private currentState: ScreenState = ScreenState.TRIPLE;
  private currentOrientation: window.Orientation = window.Orientation.LANDSCAPE;
  private listeners: ((state: ScreenState) => void)[] = [];
  private windowStage: window.WindowStage | null = null;
  private mainWindow: window.Window | null = null;
  private updateTimer: number = -1;
  private readonly DEBOUNCE_TIME: number = 200; // 防抖时间（官方建议200ms）
  private readonly ORIENTATION_WAIT_TIME: number = 100; // 方向切换等待时间（官方建议）
  private isTransitioning: boolean = false; // 折叠状态过渡标志位（官方建议）

  private constructor() {}

  static getInstance(): ScreenStateManager {
    if (!ScreenStateManager.instance) {
      ScreenStateManager.instance = new ScreenStateManager();
    }
    return ScreenStateManager.instance;
  }

  /**
   * 初始化屏幕状态管理器
   */
  async init(windowStage: window.WindowStage): Promise<void> {
    this.windowStage = windowStage;
    
    try {
      this.mainWindow = await windowStage.getMainWindow();
      
      // 检查是否为折叠屏设备（增强检测 - 官方建议）
      const isFoldable: boolean = display.isFoldable();
      const allDisplays: Array<display.Display> = await display.getAllDisplays();
      const isFoldableEnhanced: boolean = isFoldable || allDisplays.length > 1;
      
      console.info(`[ScreenStateManager] 设备折叠支持: ${isFoldable}, 增强检测: ${isFoldableEnhanced}`);
      console.info(`[ScreenStateManager] 显示屏数量: ${allDisplays.length}`);
      
      await this.updateScreenState();
      this.registerFoldStatusListener();
    } catch (err) {
      console.error('[ScreenStateManager] ❌ 初始化失败:', err);
    }
  }

  /**
   * 更新屏幕状态（带防抖 - 官方建议）
   */
  private handleStateChange(): void {
    clearTimeout(this.updateTimer);
    this.updateTimer = setTimeout(() => {
      this.updateScreenState();
    }, this.DEBOUNCE_TIME);
  }

  /**
   * 更新屏幕状态（核心逻辑 - 修正版）
   * 执行顺序：
   * 1. 获取折叠状态
   * 2. 获取窗口尺寸
   * 3. 判断目标状态和方向
   * 4. 检查状态是否变化（如果没变化直接返回）
   * 5. 设置屏幕方向
   * 6. 等待方向切换完成
   * 7. 更新状态
   * 8. 通知监听器
   */
  private async updateScreenState(): Promise<void> {
    try {
      if (!this.mainWindow) {
        return;
      }

      // 步骤1：获取折叠状态（主判断依据）
      const foldStatus: display.FoldStatus = display.getFoldStatus();
      
      // 步骤2：获取窗口尺寸和像素密度
      const windowProperties: window.WindowProperties = this.mainWindow.getWindowProperties();
      const rect: window.Rect = windowProperties.windowRect;
      let widthPx: number = rect.width;   // 物理像素
      let heightPx: number = rect.height; // 物理像素
      
      // 获取像素密度以转换为vp
      const displayClass = display.getDefaultDisplaySync();
      const densityPixels: number = displayClass.densityPixels;
      
      // 规范化尺寸：确保我们总是用较大的值作为"展开宽度"来判断
      // 这样可以避免当前方向影响判断
      const dimension1Vp: number = widthPx / densityPixels;
      const dimension2Vp: number = heightPx / densityPixels;
      const maxDimensionVp: number = Math.max(dimension1Vp, dimension2Vp);
      const minDimensionVp: number = Math.min(dimension1Vp, dimension2Vp);
      
      console.info(`[ScreenStateManager] 📊 折叠状态: ${foldStatus}`);
      console.info(`[ScreenStateManager] 📐 窗口尺寸(物理像素): ${widthPx}px × ${heightPx}px`);
      console.info(`[ScreenStateManager] 📐 像素密度: ${densityPixels}`);
      console.info(`[ScreenStateManager] 📐 尺寸范围(vp): ${minDimensionVp.toFixed(0)}vp ~ ${maxDimensionVp.toFixed(0)}vp`);

      // 步骤3：根据折叠状态和窗口尺寸判断目标模式和方向
      // 注意：在华为折叠屏上，双屏和三屏都可能是EXPANDED状态，需要结合尺寸判断
      let newState: ScreenState;
      let targetOrientation: window.Orientation;
      
      if (foldStatus === display.FoldStatus.FOLD_STATUS_FOLDED) {
        // 完全折叠 → 单屏横屏
        newState = ScreenState.SINGLE;
        targetOrientation = window.Orientation.LANDSCAPE;
        console.info('[ScreenStateManager] 📱 完全折叠(FOLDED) → 单屏横屏');
        
      } else if (foldStatus === display.FoldStatus.FOLD_STATUS_HALF_FOLDED) {
        // 半折叠 → 双屏竖屏
        newState = ScreenState.DOUBLE;
        targetOrientation = window.Orientation.PORTRAIT;
        console.info('[ScreenStateManager] 📱 半折叠(HALF_FOLDED) → 双屏竖屏');
        
      } else {
        // FOLD_STATUS_EXPANDED 展开状态 → 根据窗口尺寸判断双屏或三屏
        // 设计尺寸：双屏 712vp × 776vp，三屏 1107vp × 776vp
        // 阈值设为 900vp
        if (maxDimensionVp >= 900) {
          // 最大维度 ≥ 900vp → 三屏横屏
          newState = ScreenState.TRIPLE;
          targetOrientation = window.Orientation.LANDSCAPE;
          console.info(`[ScreenStateManager] 📺 展开态(${maxDimensionVp.toFixed(0)}vp) → 三屏横屏`);
        } else {
          // 最大维度 < 900vp → 双屏竖屏
          newState = ScreenState.DOUBLE;
          targetOrientation = window.Orientation.PORTRAIT;
          console.info(`[ScreenStateManager] 📱 展开态(${maxDimensionVp.toFixed(0)}vp) → 双屏竖屏`);
        }
      }

      // 步骤4：检查状态和方向是否变化
      const stateChanged: boolean = this.currentState !== newState;
      const orientationChanged: boolean = this.currentOrientation !== targetOrientation;
      
      console.info(`[ScreenStateManager] 当前状态: ${this.currentState}, 目标状态: ${newState}, 状态变化: ${stateChanged}`);
      console.info(`[ScreenStateManager] 当前方向: ${this.currentOrientation === window.Orientation.LANDSCAPE ? '横屏' : this.currentOrientation === window.Orientation.PORTRAIT ? '竖屏' : '未知'}, 目标方向: ${targetOrientation === window.Orientation.LANDSCAPE ? '横屏' : '竖屏'}, 方向变化: ${orientationChanged}`);
      
      // 如果状态和方向都未变化，直接返回
      if (!stateChanged && !orientationChanged) {
        console.info('[ScreenStateManager] ⏭️  状态和方向都未变化，跳过更新');
        return;
      }

      // 步骤5：设置屏幕方向（官方建议：module.json5已设置portrait基准，此处仅处理特殊情况）
      if (orientationChanged) {
        console.info(`[ScreenStateManager] 🔄 方向需要改变，设置为: ${targetOrientation === window.Orientation.LANDSCAPE ? '横屏' : '竖屏'}`);
        await this.mainWindow.setPreferredOrientation(targetOrientation);
        await new Promise<void>(resolve => setTimeout(resolve, this.ORIENTATION_WAIT_TIME));
        this.currentOrientation = targetOrientation;
        console.info('[ScreenStateManager] ✅ 方向设置完成');
      } else {
        console.info('[ScreenStateManager] ⏭️  方向无需改变，跳过方向设置');
      }
      
      // 步骤6：更新状态
      if (stateChanged) {
        this.currentState = newState;
        console.info(`[ScreenStateManager] 🎯 状态已更新: ${this.currentState}`);
      }
      
      // 步骤7：通知监听器
      this.notifyListeners();
      console.info('[ScreenStateManager] 📢 已通知监听器');
      
    } catch (err) {
      console.error('[ScreenStateManager] ❌ 更新失败:', err);
    }
  }

  /**
   * 注册折叠状态变化监听器（采用官方建议的双事件协同机制）
   */
  private registerFoldStatusListener(): void {
    try {
      // 主监听：折叠状态变化（官方推荐优先级1，主导信号）
      display.on('foldStatusChange', async (foldStatus: display.FoldStatus) => {
        console.info(`[ScreenStateManager] 🔔 [主导] 折叠状态变化事件: ${foldStatus}`);
        // 设置过渡标志位，避免折叠过程中的中间状态干扰
        this.isTransitioning = true;
        console.info('[ScreenStateManager] 🚩 过渡标志位已设置，窗口尺寸变化将被忽略');
        
        // 处理状态变化
        await this.handleStateChangeAsync(foldStatus);
        
        // 清除过渡标志位
        this.isTransitioning = false;
        console.info('[ScreenStateManager] ✅ 过渡标志位已清除');
      });

      // 辅助监听：窗口大小变化（官方推荐优先级2，仅作补充）
      if (this.mainWindow) {
        this.mainWindow.on('windowSizeChange', (size: window.Size) => {
          console.info(`[ScreenStateManager] 🔔 [辅助] 窗口大小变化事件: ${size.width}×${size.height}`);
          
          // 官方建议：折叠过渡期间忽略窗口尺寸变化，避免中间状态干扰
          if (this.isTransitioning) {
            console.info('[ScreenStateManager] ⏭️  过渡期间，跳过窗口尺寸变化处理');
            return;
          }
          
          // 非过渡期间才处理窗口尺寸变化
          this.handleStateChange();
        });
      }
      
      console.info('[ScreenStateManager] ✅ 监听器注册成功（双事件协同机制）');
    } catch (err) {
      console.error('[ScreenStateManager] ❌ 注册监听器失败:', err);
    }
  }

  /**
   * 处理状态变化（异步版本，用于 foldStatusChange 主导事件）
   */
  private async handleStateChangeAsync(foldStatus: display.FoldStatus): Promise<void> {
    // 清除之前的防抖定时器
    clearTimeout(this.updateTimer);
    // 直接更新状态，不需要防抖
    await this.updateScreenState();
  }

  /**
   * 添加状态变化监听器
   */
  addListener(listener: (state: ScreenState) => void): void {
    this.listeners.push(listener);
  }

  /**
   * 移除状态变化监听器
   */
  removeListener(listener: (state: ScreenState) => void): void {
    const index = this.listeners.indexOf(listener);
    if (index > -1) {
      this.listeners.splice(index, 1);
    }
  }

  /**
   * 通知所有监听器
   */
  private notifyListeners(): void {
    this.listeners.forEach(listener => {
      listener(this.currentState);
    });
  }

  /**
   * 获取当前屏幕状态
   */
  getCurrentState(): ScreenState {
    return this.currentState;
  }

  /**
   * 清理资源
   */
  destroy(): void {
    try {
      // 清除防抖定时器
      if (this.updateTimer !== -1) {
        clearTimeout(this.updateTimer);
      }
      
      // 取消折叠状态监听
      display.off('foldStatusChange');
      
      // 取消窗口大小监听
      if (this.mainWindow) {
        this.mainWindow.off('windowSizeChange');
      }
      
      this.listeners = [];
      console.info('[ScreenStateManager] ✅ 资源清理完成');
    } catch (err) {
      console.error('[ScreenStateManager] ❌ 清理资源失败:', err);
    }
  }
}

