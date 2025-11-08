import { media } from '@kit.MediaKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

/**
 * 音频管理器（单例模式）
 * 负责背景音乐播放、音量控制和状态持久化
 */
export class AudioManager {
  private static instance: AudioManager;
  
  private bgmPlayer: media.AVPlayer | null = null;      // BGM播放器
  private bgmVolume: number = 0.5;                      // BGM音量（默认50%）
  private currentBGMPath: string = '';                  // 当前BGM路径
  private context?: common.UIAbilityContext;            // 应用上下文
  private preferencesStore: preferences.Preferences | null = null;  // 数据持久化
  private pendingSeekPosition: number = 0;              // 待跳转的播放位置（毫秒）
  
  private constructor() {
    // 私有构造函数，确保单例
  }
  
  /**
   * 获取单例实例
   */
  static getInstance(): AudioManager {
    if (!AudioManager.instance) {
      AudioManager.instance = new AudioManager();
    }
    return AudioManager.instance;
  }
  
  /**
   * 设置应用上下文并初始化
   */
  async setContext(context: common.UIAbilityContext): Promise<void> {
    this.context = context;
    await this.initPreferences();
    console.info('[AudioManager] 音频服务初始化完成');
  }
  
  /**
   * 初始化数据持久化
   */
  private async initPreferences(): Promise<void> {
    try {
      this.preferencesStore = await preferences.getPreferences(
        this.context!,
        'audio_settings'
      );
      await this.loadVolumeSettings();
      console.info('[AudioManager] Preferences初始化成功');
    } catch (error) {
      console.error('[AudioManager] Preferences初始化失败:', error);
    }
  }
  
  /**
   * 加载保存的音量设置
   */
  private async loadVolumeSettings(): Promise<void> {
    try {
      if (this.preferencesStore) {
        const savedVolume = await this.preferencesStore.get('bgm_volume', 0.5) as number;
        this.bgmVolume = Math.max(0, Math.min(1, savedVolume));
        console.info('[AudioManager] 加载音量设置:', this.bgmVolume);
        
        // 同步到全局状态
        AppStorage.setOrCreate('isSoundMuted', this.bgmVolume === 0);
      }
    } catch (error) {
      console.error('[AudioManager] 加载音量设置失败:', error);
    }
  }
  
  /**
   * 保存音量设置
   */
  private async saveVolumeSettings(): Promise<void> {
    try {
      if (this.preferencesStore) {
        await this.preferencesStore.put('bgm_volume', this.bgmVolume);
        await this.preferencesStore.flush();
        console.info('[AudioManager] 音量设置已保存:', this.bgmVolume);
      }
    } catch (error) {
      console.error('[AudioManager] 保存音量设置失败:', error);
    }
  }
  
  /**
   * 播放背景音乐
   */
  async playBGM(resourcePath: string): Promise<void> {
    try {
      // 保存当前音乐路径到全局存储（用于恢复播放）
      AppStorage.setOrCreate('currentMusicPath', resourcePath);
      
      // 路径去重检查：如果已在播放相同的BGM，跳过
      if (this.currentBGMPath === resourcePath && 
          this.bgmPlayer && 
          this.bgmPlayer.state === 'playing') {
        console.info('[AudioManager] 相同BGM已在播放，跳过:', resourcePath);
        return;
      }
      
      console.info('[AudioManager] 开始播放BGM:', resourcePath);
      
      // 停止并释放旧播放器
      if (this.bgmPlayer) {
        try {
          if (this.bgmPlayer.state === 'playing') {
            await this.bgmPlayer.stop();
          }
          await this.bgmPlayer.release();
        } catch (error) {
          console.error('[AudioManager] 释放旧播放器失败:', error);
        }
        this.bgmPlayer = null;
      }
      
      // 创建新播放器
      this.bgmPlayer = await media.createAVPlayer();
      console.info('[AudioManager] AVPlayer创建成功');
      
      // 第一次设置音量
      this.bgmPlayer.setVolume(this.bgmVolume);
      console.info('[AudioManager] 初始音量已设置:', this.bgmVolume);
      
      // 注册状态监听器
      this.bgmPlayer.on('stateChange', async (state: string) => {
        console.info('[AudioManager] 状态变化:', state);
        
        if (state === 'initialized') {
          console.info('[AudioManager] 已初始化，开始准备播放');
          await this.bgmPlayer?.prepare();
        }
        
        if (state === 'prepared') {
          console.info('[AudioManager] 准备完成，设置循环并播放');
          if (this.bgmPlayer) {
            this.bgmPlayer.loop = true;
            // 第二次设置音量（确保生效）
            this.bgmPlayer.setVolume(this.bgmVolume);
            console.info('[AudioManager] prepared状态音量已设置:', this.bgmVolume);
            await this.bgmPlayer.play();
          }
        }
        
        if (state === 'playing') {
          this.currentBGMPath = resourcePath;
          console.info('[AudioManager] 正在播放:', resourcePath);
          
          // 如果有待跳转的位置，执行跳转
          if (this.pendingSeekPosition > 0 && this.bgmPlayer) {
            console.info('[AudioManager] 跳转到播放位置:', this.pendingSeekPosition, 'ms');
            this.bgmPlayer.seek(this.pendingSeekPosition);
            this.pendingSeekPosition = 0;  // 清除待跳转位置
          }
        }
      });
      
      // 注册错误监听器
      this.bgmPlayer.on('error', (error) => {
        console.error('[AudioManager] 播放错误:', JSON.stringify(error));
      });
      
      // 加载音频资源
      if (!this.context) {
        console.error('[AudioManager] Context未设置');
        return;
      }
      
      const fd = await this.context.resourceManager.getRawFd(resourcePath);
      console.info('[AudioManager] 音频资源加载成功:', resourcePath);
      
      // 设置文件源（触发状态机）
      this.bgmPlayer.fdSrc = {
        fd: fd.fd,
        offset: fd.offset,
        length: fd.length
      };
      
    } catch (error) {
      console.error('[AudioManager] 播放BGM失败:', error);
    }
  }
  
  /**
   * 停止背景音乐
   */
  async stopBGM(): Promise<void> {
    try {
      if (this.bgmPlayer) {
        if (this.bgmPlayer.state === 'playing') {
          await this.bgmPlayer.stop();
        }
        await this.bgmPlayer.release();
        this.bgmPlayer = null;
        this.currentBGMPath = '';
        console.info('[AudioManager] BGM已停止');
      }
    } catch (error) {
      console.error('[AudioManager] 停止BGM失败:', error);
    }
  }
  
  /**
   * 设置BGM音量
   */
  setBGMVolume(volume: number): void {
    this.bgmVolume = Math.max(0, Math.min(1, volume));
    
    // 应用到当前播放器
    if (this.bgmPlayer) {
      this.bgmPlayer.setVolume(this.bgmVolume);
    }
    
    // 保存到持久化存储
    this.saveVolumeSettings();
    
    // 同步到全局状态
    AppStorage.setOrCreate('isSoundMuted', this.bgmVolume === 0);
    
    console.info('[AudioManager] 音量已设置:', this.bgmVolume);
  }
  
  /**
   * 获取当前BGM音量
   */
  getBGMVolume(): number {
    return this.bgmVolume;
  }
  
  /**
   * 切换静音状态
   */
  toggleMute(): void {
    if (this.bgmVolume === 0) {
      // 当前静音，恢复音量（恢复到50%）
      this.setBGMVolume(0.5);
    } else {
      // 当前有声音，静音
      this.setBGMVolume(0);
    }
  }
  
  /**
   * 检查是否静音
   */
  isMuted(): boolean {
    return this.bgmVolume === 0;
  }
  
  /**
   * 恢复播放（应用回到前台时调用）
   */
  async resumeBGM(): Promise<void> {
    try {
      // 从全局存储中获取之前播放的音乐路径
      const savedMusicPath = AppStorage.get<string>('currentMusicPath');
      
      if (!savedMusicPath) {
        console.info('[AudioManager] 无保存的音乐路径，跳过恢复');
        return;
      }
      
      // 检查播放器状态
      if (this.bgmPlayer) {
        const state = this.bgmPlayer.state;
        console.info('[AudioManager] 当前播放器状态:', state);
        
        // 如果已经在播放相同的音乐，跳过
        if (state === 'playing' && this.currentBGMPath === savedMusicPath) {
          console.info('[AudioManager] 音乐已在播放，跳过恢复:', savedMusicPath);
          return;
        }
        
        // 如果播放器已停止或暂停，且路径相同，则重新播放
        if ((state === 'stopped' || state === 'paused' || state === 'idle') && 
            this.currentBGMPath === savedMusicPath) {
          console.info('[AudioManager] 播放器已停止，恢复播放:', savedMusicPath);
          // 清除当前路径，强制重新播放
          this.currentBGMPath = '';
          await this.playBGM(savedMusicPath);
          // 恢复播放位置
          await this.restorePlaybackPosition();
          return;
        }
      }
      
      // 播放器不存在或路径不同，正常播放（会走路径去重检查）
      console.info('[AudioManager] 调用 playBGM 播放音乐:', savedMusicPath);
      await this.playBGM(savedMusicPath);
      // 恢复播放位置
      await this.restorePlaybackPosition();
    } catch (error) {
      console.error('[AudioManager] 恢复播放失败:', error);
    }
  }
  
  /**
   * 保存当前播放位置（应用进入后台时调用）
   */
  savePlaybackPosition(): void {
    try {
      if (this.bgmPlayer && this.bgmPlayer.state === 'playing') {
        const currentTime = this.bgmPlayer.currentTime;
        console.info('[AudioManager] 保存播放位置:', currentTime, 'ms');
        
        // 保存到 AppStorage（快速访问）
        AppStorage.setOrCreate('musicPlaybackPosition', currentTime);
        
        // 同时保存到 Preferences（持久化）
        if (this.preferencesStore) {
          this.preferencesStore.put('music_position', currentTime);
          this.preferencesStore.flush();
        }
      }
    } catch (error) {
      console.error('[AudioManager] 保存播放位置失败:', error);
    }
  }
  
  /**
   * 恢复到保存的播放位置
   */
  private async restorePlaybackPosition(): Promise<void> {
    try {
      // 先从 AppStorage 读取（更快）
      let savedPosition = AppStorage.get<number>('musicPlaybackPosition');
      
      // 如果 AppStorage 没有，从 Preferences 读取
      if (!savedPosition && this.preferencesStore) {
        savedPosition = await this.preferencesStore.get('music_position', 0) as number;
      }
      
      if (savedPosition && savedPosition > 0) {
        console.info('[AudioManager] 检测到保存的播放位置:', savedPosition, 'ms');
        
        if (this.bgmPlayer) {
          // 如果播放器已经在播放，直接 seek
          if (this.bgmPlayer.state === 'playing') {
            console.info('[AudioManager] 立即跳转到播放位置:', savedPosition, 'ms');
            this.bgmPlayer.seek(savedPosition);
          } else {
            // 否则设置待跳转位置，等播放器进入 playing 状态后再跳转
            console.info('[AudioManager] 设置待跳转位置:', savedPosition, 'ms');
            this.pendingSeekPosition = savedPosition;
          }
        }
        
        // 清除保存的位置，避免重复使用
        AppStorage.setOrCreate('musicPlaybackPosition', 0);
        if (this.preferencesStore) {
          await this.preferencesStore.put('music_position', 0);
          await this.preferencesStore.flush();
        }
      }
    } catch (error) {
      console.error('[AudioManager] 恢复播放位置失败:', error);
    }
  }
}

// 导出单例实例
export const audioManager = AudioManager.getInstance();

