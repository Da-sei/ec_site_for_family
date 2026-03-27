import { Injectable, Inject } from '@nestjs/common';
import { PrismaService } from '../../../../prisma/prisma.service';
import type {
  IWishlistRepository,
  WishlistItemRaw,
} from '../domain/interfaces/wishlist.repository.interface';

const requesterSelect = {
  select: { id: true, accountId: true, name: true },
} as const;

function toRaw(item: any): WishlistItemRaw {
  return {
    id: item.id,
    title: item.title,
    description: item.description ?? null,
    groupId: item.groupId,
    requesterId: item.requesterId,
    requester: item.requester,
    createdAt: item.createdAt,
    updatedAt: item.updatedAt,
  };
}

@Injectable()
export class WishlistRepository implements IWishlistRepository {
  constructor(
    @Inject(PrismaService) private readonly prisma: PrismaService,
  ) {}

  async create(data: {
    title: string;
    description?: string;
    groupId: number;
    requesterId: number;
  }): Promise<WishlistItemRaw> {
    const item = await this.prisma.wishlistItems.create({
      data,
      include: { requester: requesterSelect },
    });
    return toRaw(item);
  }

  async findByGroupId(groupId: number): Promise<WishlistItemRaw[]> {
    const items = await this.prisma.wishlistItems.findMany({
      where: { groupId },
      include: { requester: requesterSelect },
      orderBy: { createdAt: 'desc' },
    });
    return items.map(toRaw);
  }

  async findById(id: number): Promise<WishlistItemRaw | null> {
    const item = await this.prisma.wishlistItems.findUnique({
      where: { id },
      include: { requester: requesterSelect },
    });
    return item ? toRaw(item) : null;
  }

  async update(
    id: number,
    data: { title?: string; description?: string },
  ): Promise<WishlistItemRaw> {
    const item = await this.prisma.wishlistItems.update({
      where: { id },
      data,
      include: { requester: requesterSelect },
    });
    return toRaw(item);
  }

  async delete(id: number): Promise<void> {
    await this.prisma.wishlistItems.delete({ where: { id } });
  }
}
