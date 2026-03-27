export interface WishlistItemRaw {
  id: number;
  title: string;
  description: string | null;
  groupId: number;
  requesterId: number;
  requester: { id: number; accountId: string; name: string };
  createdAt: Date;
  updatedAt: Date;
}

export interface IWishlistRepository {
  create(data: {
    title: string;
    description?: string;
    groupId: number;
    requesterId: number;
  }): Promise<WishlistItemRaw>;

  findByGroupId(groupId: number): Promise<WishlistItemRaw[]>;

  findById(id: number): Promise<WishlistItemRaw | null>;

  update(
    id: number,
    data: { title?: string; description?: string },
  ): Promise<WishlistItemRaw>;

  delete(id: number): Promise<void>;
}
