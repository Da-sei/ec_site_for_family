import {
  Injectable,
  Inject,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../../prisma/prisma.service';
import type {
  IWishlistRepository,
  WishlistItemRaw,
} from '../domain/interfaces/wishlist.repository.interface';

export interface WishlistItemDto {
  id: number;
  title: string;
  description: string | null;
  groupId: number;
  requesterId: number;
  requester: { id: number; accountId: string; name: string };
  createdAt: string;
  updatedAt: string;
}

function toDto(raw: WishlistItemRaw): WishlistItemDto {
  return {
    id: raw.id,
    title: raw.title,
    description: raw.description,
    groupId: raw.groupId,
    requesterId: raw.requesterId,
    requester: raw.requester,
    createdAt: raw.createdAt.toISOString(),
    updatedAt: raw.updatedAt.toISOString(),
  };
}

@Injectable()
export class WishlistService {
  constructor(
    @Inject('WISHLIST_REPOSITORY')
    private readonly wishlistRepo: IWishlistRepository,
    @Inject(PrismaService)
    private readonly prisma: PrismaService,
  ) {}

  async createWishlistItem(
    userId: number,
    dto: { title: string; description?: string; groupId: number },
  ): Promise<WishlistItemDto> {
    const member = await this.prisma.groupMembers.findUnique({
      where: { groupId_userId: { groupId: dto.groupId, userId } },
    });
    if (!member) {
      throw new ForbiddenException('このグループのメンバーではありません');
    }
    const item = await this.wishlistRepo.create({
      title: dto.title,
      description: dto.description,
      groupId: dto.groupId,
      requesterId: userId,
    });
    return toDto(item);
  }

  async getWishlistItems(groupId: number): Promise<WishlistItemDto[]> {
    const items = await this.wishlistRepo.findByGroupId(groupId);
    return items.map(toDto);
  }

  async getWishlistItemById(
    id: number,
    userId: number,
  ): Promise<WishlistItemDto> {
    const item = await this.wishlistRepo.findById(id);
    if (!item) {
      throw new NotFoundException('ウィッシュリストアイテムが見つかりません');
    }
    const member = await this.prisma.groupMembers.findUnique({
      where: { groupId_userId: { groupId: item.groupId, userId } },
    });
    if (!member) {
      throw new ForbiddenException('このグループのメンバーではありません');
    }
    return toDto(item);
  }

  async updateWishlistItem(
    id: number,
    dto: { title?: string; description?: string },
  ): Promise<WishlistItemDto> {
    const item = await this.wishlistRepo.update(id, dto);
    return toDto(item);
  }

  async deleteWishlistItem(id: number): Promise<void> {
    await this.wishlistRepo.delete(id);
  }
}
