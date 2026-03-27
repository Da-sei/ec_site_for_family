import { ItemStatus } from "./type/item.repository.type"

export class ItemEntity {
  public readonly id: number;
  public readonly title: string;
  public readonly description: string | null;
  public readonly sellerId: number;
  public readonly groupId: number;
  public readonly categoryId: number;
  public readonly status: ItemStatus;
  public readonly createdAt: Date;
  public readonly updatedAt: Date;

  constructor({
    id,
    title,
    description,
    sellerId,
    groupId,
    categoryId,
    status,
    createdAt,
    updatedAt
  }:{
    id: number;
    title: string;
    description: string | null;
    sellerId: number;
    groupId: number;
    categoryId: number;
    status: ItemStatus;
    createdAt: Date;
    updatedAt: Date;
  }) {
    this.id = id;
    this.title = title;
    this.description = description;
    this.sellerId = sellerId;
    this.groupId = groupId;
    this.categoryId = categoryId;
    this.status = status;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }
}
