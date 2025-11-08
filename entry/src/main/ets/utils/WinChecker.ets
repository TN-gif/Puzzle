import { TileData } from '../models/TileData';

/**
 * 胜利判断工具类
 */
export class WinChecker {
  /**
   * 检查是否完成拼图
   * 判断标准：每个方块的id等于其currentIndex
   * @param tiles 方块数组
   * @returns 是否胜利
   */
  static checkWin(tiles: TileData[]): boolean {
    for (let i = 0; i < tiles.length; i++) {
      if (tiles[i].id !== tiles[i].currentIndex) {
        return false;
      }
    }
    return true;
  }

  /**
   * 恢复正确答案
   * @param tiles 方块数组
   */
  static restoreAnswer(tiles: TileData[]): TileData[] {
    // 按id排序
    const sortedTiles = [...tiles].sort((a, b) => a.id - b.id);
    
    // 更新currentIndex
    sortedTiles.forEach((tile, index) => {
      tile.currentIndex = index;
    });
    
    return sortedTiles;
  }
}


