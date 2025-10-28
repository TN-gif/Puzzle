/**
 * 拼图游戏万能卡片布局
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

  build() {
    Column({ space: 8 }) {
      // 标题栏
      Row() {
        Text('🧩')
          .fontSize(16)
        
        Text(this.title)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ left: 4 })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8 })

      if (this.hasActiveGame) {
        // 有进行中的游戏
        Column({ space: 6 }) {
          // 游戏信息
          Row({ space: 12 }) {
            Column({ space: 2 }) {
              Text('模式')
                .fontSize(10)
                .fontColor('#999999')
              Text(this.gameMode)
                .fontSize(12)
                .fontColor('#333333')
                .fontWeight(FontWeight.Medium)
            }
            .alignItems(HorizontalAlign.Start)

            Column({ space: 2 }) {
              Text('难度')
                .fontSize(10)
                .fontColor('#999999')
              Text(this.gridSize)
                .fontSize(12)
                .fontColor('#333333')
                .fontWeight(FontWeight.Medium)
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding({ left: 12, right: 12 })

          // 进度信息
          Row({ space: 12 }) {
            Row({ space: 4 }) {
              Text('⏱️')
                .fontSize(12)
              Text(this.timeElapsed)
                .fontSize(12)
                .fontColor('#666666')
            }

            Row({ space: 4 }) {
              Text('👣')
                .fontSize(12)
              Text(`${this.moveCount}步`)
                .fontSize(12)
                .fontColor('#666666')
            }
          }
          .width('100%')
          .padding({ left: 12, right: 12 })

          // 继续游戏按钮
          Button('继续游戏')
            .width('90%')
            .height(32)
            .fontSize(12)
            .backgroundColor('#1890FF')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
      } else {
        // 无进行中的游戏
        Column({ space: 8 }) {
          Text('暂无进行中的游戏')
            .fontSize(12)
            .fontColor('#999999')

          Button('开始新游戏')
            .width('90%')
            .height(32)
            .fontSize(12)
            .backgroundColor('#52C41A')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}

