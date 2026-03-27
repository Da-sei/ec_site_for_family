export interface ItemDetailDto {
  id: number;
  title: string;
  description: string | null;
  category: { id: number; name: string };
  seller: { id: number; accountId: string; name: string };
  status: string;
  deliveryMethods: string[];
  images: { id: number; imageUrl: string; order: number }[];
  createdAt: Date;
}

export interface PaginatedItemsDto {
  items: ItemDetailDto[];
  total: number;
  offset: number;
  limit: number;
}