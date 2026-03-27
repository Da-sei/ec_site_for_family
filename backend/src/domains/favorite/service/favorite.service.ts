import { Injectable, Inject } from '@nestjs/common';
import type { IFavoriteRepository } from '../domain/interfaces/favorite.repository.interface';
import type { ItemDetailRaw } from '../../item/domain/interfaces/item.repository.interface';

@Injectable()
export class FavoriteService {
  constructor(
    @Inject('FAVORITE_REPOSITORY')
    private readonly favoriteRepo: IFavoriteRepository,
  ) {}

  async addFavorite(userId: number, itemId: number): Promise<void> {
    await this.favoriteRepo.add(userId, itemId);
  }

  async removeFavorite(userId: number, itemId: number): Promise<void> {
    await this.favoriteRepo.remove(userId, itemId);
  }

  async getMyFavorites(userId: number): Promise<ItemDetailRaw[]> {
    return this.favoriteRepo.findFavoriteItemsByUser(userId);
  }

  async isFavorited(userId: number, itemId: number): Promise<boolean> {
    return this.favoriteRepo.isFavorited(userId, itemId);
  }
}
