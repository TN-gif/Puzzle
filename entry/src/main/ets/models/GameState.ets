import { TileData } from './TileData';
import { image } from '@kit.ImageKit';

/**
 * 游戏状态数据模型
 */
export class GameState {
  gridSize: number;              // 难度（3/4/5）
  tiles: TileData[];             // 方块数据数组
  emptyIndex: number;            // 空格位置
  moveCount: number;             // 步数
  timeElapsed: number;           // 耗时（秒）
  isPlaying: boolean;            // 游戏状态
  originalPixelMap: image.PixelMap | null;  // 原始完整图片
  gameMode: string;              // 游戏模式（huarong/swap）
  selectedTileIndex: number;     // 交换模式下选中的方块索引

  constructor(gridSize: number = 3, gameMode: string = 'swap') {
    this.gridSize = gridSize;
    this.tiles = [];
    this.emptyIndex = gridSize * gridSize - 1;  // 空格默认在最后
    this.moveCount = 0;
    this.timeElapsed = 0;
    this.isPlaying = false;
    this.originalPixelMap = null;
    this.gameMode = gameMode;
    this.selectedTileIndex = -1;
  }

  // 重置游戏状态
  reset(): void {
    this.moveCount = 0;
    this.timeElapsed = 0;
    this.isPlaying = false;
  }
}

