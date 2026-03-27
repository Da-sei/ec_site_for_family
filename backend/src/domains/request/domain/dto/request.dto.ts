export interface RequestDto {
  id: number;
  itemId: number;
  requester: { id: number; accountId: string; name: string };
  status: string;
  deliveryMethod: string | null;
  createdAt: Date;
  completedAt: Date | null;
}
