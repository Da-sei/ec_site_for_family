import type { ItemDetailRaw } from '../../../item/domain/interfaces/item.repository.interface';

export interface IFavoriteRepository {
  add(userId: number, itemId: number): Promise<void>;
  remove(userId: number, itemId: number): Promise<void>;
  findFavoriteItemsByUser(userId: number): Promise<ItemDetailRaw[]>;
  isFavorited(userId: number, itemId: number): Promise<boolean>;
}
