import { router } from '@kit.ArkUI';
import { picker } from '@kit.CoreFileKit';
import { DifficultySelector } from '../components/DifficultySelector';
import { ImageSelector } from '../components/ImageSelector';
import { GameModeSelector } from '../components/GameModeSelector';
import { NetworkImageSelector } from '../components/NetworkImageSelector';
import { GameConstants, Colors } from '../constants/GameConstants';
import { ImageAssets } from '../constants/ImageAssets';

/**
 * 主页：难度选择、图片选择
 */
@Entry
@Component
struct HomePage {
  @State selectedMode: string = GameConstants.GAME_MODE.SWAP;  // 默认自由交换模式
  @State selectedDifficulty: number = 3;  // 默认简单难度
  @State selectedImageId: number = 1;     // 默认第一张图片
  @State customImageUri: string = '';     // 自定义图片URI
  @State networkImageUrl: string = '';    // 网络图片URL

  // 网络图片选择对话框
  private networkImageDialogController: CustomDialogController = new CustomDialogController({
    builder: NetworkImageSelector({
      onImageSelected: (imageUrl: string) => {
        this.networkImageUrl = imageUrl;
        this.selectedImageId = -2;  // 标记为网络图片
        console.info('选择的网络图片URL:', imageUrl);
      }
    }),
    autoCancel: true,
    customStyle: true
  });

  // 从相册选择图片
  async selectFromGallery(): Promise<void> {
    try {
      const photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.maxSelectNumber = 1;

      const photoPicker = new picker.PhotoViewPicker();
      const result = await photoPicker.select(photoSelectOptions);

      if (result && result.photoUris && result.photoUris.length > 0) {
        this.customImageUri = result.photoUris[0];
        this.selectedImageId = -1;  // 标记为自定义图片
        console.info('选择的图片URI:', this.customImageUri);
      }
    } catch (error) {
      console.error('选择图片失败:', error);
    }
  }

  // 开始游戏
  startGame(): void {
    // 准备参数
    let imageResource: Resource | string;
    let isCustomImage = false;
    let isNetworkImage = false;
    
    if (this.selectedImageId === -2 && this.networkImageUrl) {
      // 使用网络图片
      imageResource = this.networkImageUrl;
      isNetworkImage = true;
    } else if (this.selectedImageId === -1 && this.customImageUri) {
      // 使用相册图片
      imageResource = this.customImageUri;
      isCustomImage = true;
    } else {
      // 使用预设图片
      const presetImage = ImageAssets.PRESET_IMAGES.find(img => img.id === this.selectedImageId);
      imageResource = presetImage ? presetImage.resource : ImageAssets.PRESET_IMAGES[0].resource;
    }

    // 跳转到游戏页
    try {
      router.pushUrl({
        url: 'pages/GamePage',
        params: {
          gameMode: this.selectedMode,
          gridSize: this.selectedDifficulty,
          imageResource: imageResource,
          isCustomImage: isCustomImage,
          isNetworkImage: isNetworkImage
        }
      });
    } catch (err) {
      console.error('路由跳转失败:', err);
    }
  }

  build() {
    Column() {
      // 顶部标题区 - 荧光科技风
      Column({ space: 8 }) {
        // 装饰性荧光条纹
        Row({ space: 8 }) {
          Text('━')
            .fontSize(24)
            .fontColor(Colors.ACCENT_PRIMARY)
            .opacity(0.6)
          Text('🧩')
            .fontSize(56)
          Text('━')
            .fontSize(24)
            .fontColor(Colors.ACCENT_PRIMARY)
            .opacity(0.6)
        }

        Text('拼图游戏')
          .fontSize(40)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.ACCENT_PRIMARY)
          .letterSpacing(2)
          .shadow({
            radius: GameConstants.GLOW_EFFECT.PRIMARY.RADIUS,
            color: GameConstants.GLOW_EFFECT.PRIMARY.COLOR,
            offsetX: 0,
            offsetY: 0
          })

        Text('PUZZLE GAME')
          .fontSize(14)
          .fontColor(Colors.TEXT_DISABLED)
          .fontWeight(FontWeight.Medium)
          .letterSpacing(4)
          .opacity(0.7)

        Text('荧光科技风 · 挑战你的智力极限')
          .fontSize(15)
          .fontColor(Colors.TEXT_SECONDARY)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 4 })
      }
      .width('100%')
      .padding({ top: 40, bottom: 28 })

      // 滚动区域
      Scroll() {
        Column({ space: 16 }) {
          // 模式选择
          GameModeSelector({ selectedMode: $selectedMode })

          // 难度选择
          DifficultySelector({ selectedDifficulty: $selectedDifficulty })

          // 图片选择
          ImageSelector({ 
            selectedImageId: $selectedImageId,
            onCustomImageSelect: () => {
              this.selectFromGallery();
            }
          })

          // 网络图片按钮 - 荧光科技风
          Button() {
            Row({ space: 10 }) {
              Text('🌐')
                .fontSize(22)
              Column({ space: 2 }) {
                Text(this.networkImageUrl ? '✓ 已选择网络图片' : '从网络搜索图片')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                if (this.selectedImageId === -2) {
                  Text('点击更换图片')
                    .fontSize(12)
                    .fontColor(Colors.TEXT_DISABLED)
                }
              }
              .alignItems(HorizontalAlign.Start)
            }
          }
          .width('100%')
          .height(this.selectedImageId === -2 ? 64 : 56)
          .backgroundColor(this.selectedImageId === -2 ? Colors.SURFACE_ELEVATED : Colors.SURFACE)
          .fontColor(this.selectedImageId === -2 ? Colors.ACCENT_PRIMARY : Colors.TEXT_SECONDARY)
          .border({ 
            width: this.selectedImageId === -2 ? 2 : 1, 
            color: this.selectedImageId === -2 ? Colors.ACCENT_PRIMARY : Colors.TEXT_DISABLED
          })
          .borderRadius(GameConstants.BORDER_RADIUS.MEDIUM)
          .shadow({
            radius: this.selectedImageId === -2 ? GameConstants.GLOW_EFFECT.PRIMARY.RADIUS : 0,
            color: GameConstants.GLOW_EFFECT.PRIMARY.COLOR,
            offsetX: 0,
            offsetY: 0
          })
          .onClick(() => {
            this.networkImageDialogController = new CustomDialogController({
              builder: NetworkImageSelector({
                onImageSelected: (imageUrl: string) => {
                  this.networkImageUrl = imageUrl;
                  this.selectedImageId = -2;
                }
              }),
              autoCancel: true,
              customStyle: true
            });
            this.networkImageDialogController.open();
          })

          // 开始游戏按钮 - 荧光科技风（带霓虹辉光）
          Button() {
            Row({ space: 12 }) {
              Text('🎮')
                .fontSize(24)
              Text('开始游戏')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .letterSpacing(2)
              Text('▶')
                .fontSize(16)
            }
          }
          .width('100%')
          .height(64)
          .backgroundColor(Colors.ACCENT_PRIMARY)
          .fontColor(Colors.BACKGROUND_BASE)
          .borderRadius(GameConstants.BORDER_RADIUS.PILL)
          .shadow({
            radius: GameConstants.GLOW_EFFECT.PRIMARY.RADIUS * 1.5,
            color: GameConstants.GLOW_EFFECT.PRIMARY.COLOR,
            offsetX: 0,
            offsetY: 0
          })
          .margin({ top: 32, bottom: 24 })
          .onClick(() => {
            this.startGame();
          })
        }
        .padding(16)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Colors.BACKGROUND_BASE)
  }
}

