import type { DeliveryMethod } from './../../domain/type/item.repository.type';

export interface CreateItemInput {
  title: string;
  description?: string;
  categoryId: number;
  groupId: number;
  deliveryMethods?: DeliveryMethod[];
}

export interface UpdateItemInput {
  title?: string;
  description?: string;
  categoryId?: number;
  deliveryMethods?: DeliveryMethod[];
}
