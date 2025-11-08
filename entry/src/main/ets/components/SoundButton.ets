import { audioManager } from '../utils/AudioManager';

/**
 * 声音控制按钮组件
 * 可复用的声音开关按钮，放置在所有页面的右上角
 */
@Component
export struct SoundButton {
  // 使用 @StorageLink 同步全局静音状态
  @StorageLink('isSoundMuted') isMuted: boolean = false;
  
  // 按钮尺寸（根据不同屏幕状态）
  buttonSize: number = 60;       // 按钮外框大小
  iconSize: number = 32;         // 图标大小
  
  build() {
    Button() {
      Image(this.isMuted ? 
        $rawfile('images/icon/静音.png') : 
        $rawfile('images/icon/声音.png'))
        .width(this.iconSize)
        .height(this.iconSize)
    }
    .width(this.buttonSize)
    .height(this.buttonSize)
    .backgroundColor('rgba(255, 255, 255, 0.9)')
    .borderRadius(this.buttonSize / 2)
    .onClick(() => {
      // 切换静音状态
      audioManager.toggleMute();
      // 更新全局状态（AudioManager 内部已经更新）
      this.isMuted = audioManager.isMuted();
      console.info('[SoundButton] 声音状态切换:', this.isMuted ? '静音' : '开启');
    })
  }
}

