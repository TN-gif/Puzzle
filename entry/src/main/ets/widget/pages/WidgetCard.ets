/**
 * 拼图游戏万能卡片布局 - 简约黑白风
 * 2x2 卡片尺寸
 */
@Entry(LocalStorage.getShared())
@Component
struct WidgetCard {
  @LocalStorageProp('title') title: string = '拼图游戏';
  @LocalStorageProp('gameMode') gameMode: string = '交换模式';
  @LocalStorageProp('gridSize') gridSize: string = '3×3';
  @LocalStorageProp('moveCount') moveCount: number = 0;
  @LocalStorageProp('timeElapsed') timeElapsed: string = '00:00';
  @LocalStorageProp('hasActiveGame') hasActiveGame: boolean = false;

  // 启动应用并跳转到指定页面（postCardAction是全局函数，无需导入）
  private launchApp(targetPage: string): void {
    postCardAction(this, {
      action: 'router',
      abilityName: 'EntryAbility',
      params: {
        targetPage: targetPage
      }
    });
  }

  build() {
    Column({ space: 10 }) {
      // 标题栏 - 简约黑白风
      Row() {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#000000')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12 })

      if (this.hasActiveGame) {
        // 有进行中的游戏
        Column({ space: 8 }) {
          // 游戏信息卡片
          Row({ space: 14 }) {
            Column({ space: 3 }) {
              Text('模式')
                .fontSize(10)
                .fontColor('#666666')
              Text(this.gameMode)
                .fontSize(12)
                .fontColor('#000000')
                .fontWeight(FontWeight.Bold)
            }
            .alignItems(HorizontalAlign.Start)

            Column({ space: 3 }) {
              Text('难度')
                .fontSize(10)
                .fontColor('#666666')
              Text(this.gridSize)
                .fontSize(12)
                .fontColor('#000000')
                .fontWeight(FontWeight.Bold)
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding({ left: 16, right: 16 })

          // 进度信息
          Row({ space: 14 }) {
            Row({ space: 4 }) {
              Text('用时:')
                .fontSize(12)
                .fontColor('#666666')
                .fontWeight(FontWeight.Medium)
              Text(this.timeElapsed)
                .fontSize(12)
                .fontColor('#000000')
                .fontWeight(FontWeight.Medium)
            }

            Row({ space: 4 }) {
              Text('步数:')
                .fontSize(12)
                .fontColor('#666666')
                .fontWeight(FontWeight.Medium)
              Text(`${this.moveCount}`)
                .fontSize(12)
                .fontColor('#000000')
                .fontWeight(FontWeight.Medium)
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16 })

          // 继续游戏按钮组 - 分为"继续"和"主题"两个按钮
          Row({ space: 8 }) {
            Button('继续')
              .width('45%')
              .height(36)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .backgroundColor('#000000')
              .fontColor('#FFFFFF')
              .borderRadius(8)
              .border({ width: 2, color: '#000000' })
              .onClick(() => {
                this.launchApp('pages/GamePage');  // 继续游戏
              })
            
            Button('主题')
              .width('45%')
              .height(36)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .backgroundColor('#FFFFFF')
              .fontColor('#000000')
              .borderRadius(8)
              .border({ width: 2, color: '#000000' })
              .onClick(() => {
                this.launchApp('pages/ThemeSelectionPage');  // 进入主题选择
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 2, bottom: 4 })
        }
        .layoutWeight(1)
      } else {
        // 无进行中的游戏
        Column({ space: 10 }) {
          Text('暂无进行中的游戏')
            .fontSize(12)
            .fontColor('#666666')

          Button('开始新游戏')
            .width('88%')
            .height(36)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .backgroundColor('#000000')
            .fontColor('#FFFFFF')
            .borderRadius(8)
            .border({ width: 2, color: '#000000' })
            .onClick(() => {
              this.launchApp('pages/ThemeSelectionPage');  // 开始新游戏：跳转到主题选择页面
            })
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')  // 卡片白色背景
    .border({ width: 3, color: '#000000' })  // 黑色边框
    .borderRadius(12)  // 圆角
    // 注意：服务卡片在 SDK 6.0.0 中点击会自动触发 FormAbility.onFormEvent
    // 无需手动添加 onClick 事件
  }
}

