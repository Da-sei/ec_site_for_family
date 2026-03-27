import { Injectable, Inject } from '@nestjs/common';
import { PrismaService } from '../../../../prisma/prisma.service';
import type { IFavoriteRepository } from '../domain/interfaces/favorite.repository.interface';
import type { ItemDetailRaw } from '../../item/domain/interfaces/item.repository.interface';

const itemInclude = {
  category: true,
  seller: { select: { id: true, accountId: true, name: true } },
  deliveryOptions: true,
  images: { orderBy: { order: 'asc' as const } },
};

function toDetailRaw(item: any): ItemDetailRaw {
  return {
    id: item.id,
    title: item.title,
    description: item.description ?? null,
    category: item.category,
    seller: item.seller,
    status: item.status,
    deliveryMethods: item.deliveryOptions.map((o: any) => o.method as string),
    images: item.images.map((i: any) => ({ id: i.id, imageUrl: i.imageUrl, order: i.order })),
    createdAt: item.createdAt,
    groupId: item.groupId,
    sellerId: item.sellerId,
  };
}

@Injectable()
export class FavoriteRepository implements IFavoriteRepository {

  constructor(
    @Inject(PrismaService) 
    private readonly prisma: PrismaService
  ) {}

  // お気に入りの追加
  async add(
    userId: number, 
    itemId: number
  ): Promise<void> {
    await this.prisma.favorites.upsert({
      where: { userId_itemId: { userId, itemId } },
      create: { userId, itemId },
      update: {},
    });
  }

  // お気に入りの削除
  async remove(
    userId: number, 
    itemId: number
  ): Promise<void> {
    await this.prisma.favorites.deleteMany({ where: { userId, itemId } });
  }

  async findFavoriteItemsByUser(
    userId: number
  ): Promise<ItemDetailRaw[]> {
    const favorites = await this.prisma.favorites.findMany({
      where: { userId },
      include: { item: { include: itemInclude } },
      orderBy: { createdAt: 'desc' },
    });
    return favorites.map((f) => toDetailRaw(f.item));
  }

  async isFavorited(
    userId: number, 
    itemId: number
  ): Promise<boolean> {
    const fav = await this.prisma.favorites.findUnique({
      where: { userId_itemId: { userId, itemId } },
    });
    return fav !== null;
  }
}
