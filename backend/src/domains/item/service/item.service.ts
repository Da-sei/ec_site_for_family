import {
  Injectable,
  Inject,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import type { IItemRepository, ItemDetailRaw, FindItemsOptions } from '../domain/interfaces/item.repository.interface';
import type { ItemDetailDto, PaginatedItemsDto } from '../domain/dto/item.dto';
import type { CreateItemInput, UpdateItemInput } from './dto/item.dto';
import { StorageService } from '../../../storage/storage.service';

function toDto(raw: ItemDetailRaw): ItemDetailDto {
  return {
    id: raw.id,
    title: raw.title,
    description: raw.description,
    category: raw.category,
    seller: raw.seller,
    status: raw.status,
    deliveryMethods: raw.deliveryMethods,
    images: raw.images,
    createdAt: raw.createdAt,
  };
}

@Injectable()
export class ItemService {

  constructor(
    @Inject('ITEM_REPOSITORY')
    private readonly itemRepo: IItemRepository,
    private readonly storageService: StorageService,
  ) {}

  async createItem(input: CreateItemInput, sellerId: number): Promise<ItemDetailDto> {
    const raw = await this.itemRepo.createItem({
      ...input,
      sellerId,
    });
    return toDto(raw);
  }

  async getItemById(id: number): Promise<ItemDetailDto> {
    const raw = await this.itemRepo.findItemById(id);
    if (!raw) throw new NotFoundException('商品が見つかりません');
    return toDto(raw);
  }

  async getItems(opts: FindItemsOptions): Promise<PaginatedItemsDto> {
    const { items, total } = await this.itemRepo.findItems(opts);
    return {
      items: items.map(toDto),
      total,
      offset: opts.offset,
      limit: opts.limit,
    };
  }

  async getMyItems(sellerId: number, offset: number, limit: number): Promise<PaginatedItemsDto> {
    const { items, total } = await this.itemRepo.findMyItems(sellerId, offset, limit);
    return { items: items.map(toDto), total, offset, limit };
  }

  async updateItem(id: number, sellerId: number, input: UpdateItemInput): Promise<ItemDetailDto> {
    const existing = await this.itemRepo.findItemById(id);
    if (!existing) throw new NotFoundException('商品が見つかりません');
    if (existing.sellerId !== sellerId) throw new ForbiddenException('この操作は許可されていません');
    const raw = await this.itemRepo.updateItem(id, input);
    return toDto(raw);
  }

  async deleteItem(id: number, sellerId: number): Promise<void> {
    const existing = await this.itemRepo.findItemById(id);
    if (!existing) throw new NotFoundException('商品が見つかりません');
    if (existing.sellerId !== sellerId) throw new ForbiddenException('この操作は許可されていません');
    await this.itemRepo.deleteItem(id);
  }

  async addImage(
    itemId: number,
    sellerId: number,
    imageUrl: string,
  ): Promise<{ id: number; imageUrl: string; order: number }> {
    const existing = await this.itemRepo.findItemById(itemId);
    if (!existing) throw new NotFoundException('商品が見つかりません');
    if (existing.sellerId !== sellerId) throw new ForbiddenException('この操作は許可されていません');
    const order = await this.itemRepo.getNextImageOrder(itemId);
    return this.itemRepo.addImage(itemId, imageUrl, order);
  }

  async getItemGroupId(itemId: number): Promise<number | null> {
    const raw = await this.itemRepo.findItemById(itemId);
    return raw ? raw.groupId : null;
  }

  async deleteImage(
    itemId: number,
    imageId: number,
    sellerId: number,
  ): Promise<void> {
    const existing = await this.itemRepo.findItemById(itemId);
    if (!existing) throw new NotFoundException('商品が見つかりません');
    if (existing.sellerId !== sellerId) throw new ForbiddenException('この操作は許可されていません');
    const deleted = await this.itemRepo.deleteImage(imageId);
    if (!deleted) throw new NotFoundException('画像が見つかりません');
    await this.storageService.delete(deleted.imageUrl);
  }
}
