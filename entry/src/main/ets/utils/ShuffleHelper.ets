import { TileData } from '../models/TileData';
import { GameConstants } from '../constants/GameConstants';

/**
 * 打乱结果接口
 */
export interface ShuffleResult {
  tiles: TileData[];
  emptyIndex: number;
}

/**
 * 打乱算法工具类
 */
export class ShuffleHelper {
  /**
   * 生成有解的打乱拼图
   * 使用模拟移动法：从正确状态开始，随机移动N次
   * @param tiles 方块数组
   * @param gridSize 网格大小
   * @returns 打乱后的方块数组和空格位置
   */
  static shuffle(tiles: TileData[], gridSize: number): ShuffleResult {
    // 复制数组避免修改原数组
    const shuffledTiles = tiles.map(tile => {
      return new TileData(tile.id, tile.currentIndex, tile.pixelMap, tile.isEmpty);
    });
    
    let emptyIndex = gridSize * gridSize - 1;  // 空格初始在最后
    
    // 模拟随机移动
    for (let i = 0; i < GameConstants.SHUFFLE_TIMES; i++) {
      // 获取所有可移动的方块索引
      const movableIndices = ShuffleHelper.getMovableIndices(emptyIndex, gridSize);
      
      // 随机选择一个
      const randomIndex = movableIndices[Math.floor(Math.random() * movableIndices.length)];
      
      // 交换
      ShuffleHelper.swapTiles(shuffledTiles, randomIndex, emptyIndex);
      emptyIndex = randomIndex;
    }
    
    return { tiles: shuffledTiles, emptyIndex };
  }

  /**
   * 获取所有可移动到空格的方块索引
   */
  private static getMovableIndices(emptyIndex: number, gridSize: number): number[] {
    const indices: number[] = [];
    const row = Math.floor(emptyIndex / gridSize);
    const col = emptyIndex % gridSize;
    
    // 上
    if (row > 0) indices.push((row - 1) * gridSize + col);
    // 下
    if (row < gridSize - 1) indices.push((row + 1) * gridSize + col);
    // 左
    if (col > 0) indices.push(row * gridSize + (col - 1));
    // 右
    if (col < gridSize - 1) indices.push(row * gridSize + (col + 1));
    
    return indices;
  }

  /**
   * 交换两个方块
   */
  private static swapTiles(tiles: TileData[], index1: number, index2: number): void {
    const temp = tiles[index1];
    tiles[index1] = tiles[index2];
    tiles[index2] = temp;
    
    // 更新currentIndex
    tiles[index1].currentIndex = index1;
    tiles[index2].currentIndex = index2;
  }

  /**
   * 交换模式的打乱
   * 随机打乱所有方块（包括空格）
   * @param tiles 方块数组
   * @param gridSize 网格大小
   * @returns 打乱后的方块数组
   */
  static shuffleForSwapMode(tiles: TileData[], gridSize: number): TileData[] {
    // 复制数组
    const shuffledTiles = tiles.map(tile => {
      return new TileData(tile.id, tile.currentIndex, tile.pixelMap, tile.isEmpty);
    });

    // Fisher-Yates 洗牌算法
    for (let i = shuffledTiles.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      ShuffleHelper.swapTiles(shuffledTiles, i, j);
    }

    return shuffledTiles;
  }

  /**
   * 判断两个位置是否相邻
   * @param index1 位置1
   * @param index2 位置2
   * @param gridSize 网格大小
   */
  static isAdjacent(index1: number, index2: number, gridSize: number): boolean {
    const row1 = Math.floor(index1 / gridSize);
    const col1 = index1 % gridSize;
    const row2 = Math.floor(index2 / gridSize);
    const col2 = index2 % gridSize;
    
    // 同一行且相差1列
    if (row1 === row2 && Math.abs(col1 - col2) === 1) {
      return true;
    }
    
    // 同一列且相差1行
    if (col1 === col2 && Math.abs(row1 - row2) === 1) {
      return true;
    }
    
    return false;
  }
}

