import { DeliveryMethod } from './../type/item.repository.type';

export interface ItemDetailRaw {
  id: number;
  title: string;
  description: string | null;
  category: { id: number; name: string };
  seller: { id: number; accountId: string; name: string };
  status: string;
  deliveryMethods: string[];
  images: { id: number; imageUrl: string; order: number }[];
  createdAt: Date;
  groupId: number;
  sellerId: number;
}

export interface CreateItemData {
  title: string;
  description?: string;
  categoryId: number;
  groupId: number;
  sellerId: number;
  deliveryMethods?: DeliveryMethod[];
}

export interface UpdateItemData {
  title?: string;
  description?: string;
  categoryId?: number;
  deliveryMethods?: DeliveryMethod[];
}

export interface FindItemsOptions {
  groupId: number;
  keyword?: string;
  categoryId?: number;
  offset: number;
  limit: number;
}

export interface IItemRepository {
  createItem(data: CreateItemData): Promise<ItemDetailRaw>;
  findItemById(id: number): Promise<ItemDetailRaw | null>;
  findItems(opts: FindItemsOptions): Promise<{ items: ItemDetailRaw[]; total: number }>;
  findMyItems(sellerId: number, offset: number, limit: number): Promise<{ items: ItemDetailRaw[]; total: number }>;
  updateItem(id: number, data: UpdateItemData): Promise<ItemDetailRaw>;
  deleteItem(id: number): Promise<void>;
  addImage(itemId: number, imageUrl: string, order: number): Promise<{ id: number; imageUrl: string; order: number }>;
  getNextImageOrder(itemId: number): Promise<number>;
  deleteImage(imageId: number): Promise<{ imageUrl: string } | null>;
}
