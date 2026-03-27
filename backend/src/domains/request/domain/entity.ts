import { RequestStatus } from './type/request.type';

export class RequestEntity {
  public readonly id: number;
  public readonly itemId: number;
  public readonly requesterId: number;
  public readonly status: RequestStatus;
  public readonly createdAt: Date;
  public readonly updatedAt: Date;
  public readonly completedAt: Date | null;

  constructor({
    id,
    itemId,
    requesterId,
    status,
    createdAt,
    updatedAt,
    completedAt
  }: {
    id: number;
    itemId: number;
    requesterId: number;
    status: RequestStatus;
    createdAt: Date;
    updatedAt: Date;
    completedAt: Date | null;
  }) {
    this.id = id;
    this.itemId = itemId;
    this.requesterId = requesterId;
    this.status = status;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
    this.completedAt = completedAt;
  }
}
