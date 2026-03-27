import { Injectable, Inject } from '@nestjs/common';
import { PrismaService } from '../../../../prisma/prisma.service';
import {
  IItemRepository,
  ItemDetailRaw,
  CreateItemData,
  UpdateItemData,
  FindItemsOptions,
} from '../domain/interfaces/item.repository.interface';

const itemInclude = {
  category: true,
  seller: { select: { id: true, accountId: true, name: true } },
  deliveryOptions: true,
  images: { orderBy: { order: 'asc' as const } },
};

function toDetailRaw(
  item: any
): ItemDetailRaw {
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
export class ItemRepository implements IItemRepository {

  constructor(
    @Inject(PrismaService) 
    private readonly prisma: PrismaService
  ) {}

  async createItem(data: CreateItemData): Promise<ItemDetailRaw> {
    const item = await this.prisma.items.create({
      data: {
        title: data.title,
        description: data.description,
        sellerId: data.sellerId,
        groupId: data.groupId,
        categoryId: data.categoryId,
        status: 'AVAILABLE',
        deliveryOptions: {
          create: (data.deliveryMethods ?? []).map((method) => ({ method })),
        },
      },
      include: itemInclude,
    });
    return toDetailRaw(item);
  }

  async findItemById(
    id: number
  ): Promise<ItemDetailRaw | null> {
    const item = await this.prisma.items.findUnique({
      where: { id },
      include: itemInclude,
    });
    if (!item) return null;
    return toDetailRaw(item);
  }

  async findItems(
    opts: FindItemsOptions
  ): Promise<{ items: ItemDetailRaw[]; total: number }> {
    const where: any = {
      groupId: opts.groupId,
      status: { in: ['AVAILABLE', 'IN_TRANSACTION'] },
    };
    if (opts.keyword) {
      where.OR = [
        { title: { contains: opts.keyword, mode: 'insensitive' } },
        { description: { contains: opts.keyword, mode: 'insensitive' } },
      ];
    }
    if (opts.categoryId) {
      where.categoryId = opts.categoryId;
    }

    const [items, total] = await Promise.all([
      this.prisma.items.findMany({
        where,
        include: itemInclude,
        orderBy: { createdAt: 'desc' },
        skip: opts.offset,
        take: opts.limit,
      }),
      this.prisma.items.count({ where }),
    ]);

    return { items: items.map(toDetailRaw), total };
  }

  async updateItem(
    id: number, 
    data: UpdateItemData
  ): Promise<ItemDetailRaw> {
    if (data.deliveryMethods) {
      await this.prisma.itemDeliveryOptions.deleteMany({ where: { itemId: id } });
      await this.prisma.itemDeliveryOptions.createMany({
        data: data.deliveryMethods.map((method) => ({ itemId: id, method })),
      });
    }

    const item = await this.prisma.items.update({
      where: { id },
      data: {
        ...(data.title !== undefined && { title: data.title }),
        ...(data.description !== undefined && { description: data.description }),
        ...(data.categoryId !== undefined && { categoryId: data.categoryId }),
      },
      include: itemInclude,
    });
    return toDetailRaw(item);
  }

  async deleteItem(
    id: number
  ): Promise<void> {
    await this.prisma.items.update({
      where: { id },
      data: { status: 'DELETED' },
    });
  }

  async addImage(
    itemId: number,
    imageUrl: string,
    order: number,
  ): Promise<{ id: number; imageUrl: string; order: number }> {
    return this.prisma.itemImages.create({
      data: { itemId, imageUrl, order },
    });
  }

  async getNextImageOrder(
    itemId: number
  ): Promise<number> {
    const last = await this.prisma.itemImages.findFirst({
      where: { itemId },
      orderBy: { order: 'desc' },
    });
    return last ? last.order + 1 : 0;
  }
}
