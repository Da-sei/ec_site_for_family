export interface RequestDetailRaw {
  id: number;
  itemId: number;
  requester: { id: number; accountId: string; name: string };
  status: string;
  deliveryMethod: string | null;
  createdAt: Date;
  completedAt: Date | null;
  item: { sellerId: number; status: string; groupId: number };
}

export interface IRequestRepository {
  createRequest(itemId: number, requesterId: number, deliveryMethod: string): Promise<RequestDetailRaw>;
  findRequestById(id: number): Promise<RequestDetailRaw | null>;
  findRequestsByItemId(itemId: number): Promise<RequestDetailRaw[]>;
  findRequestsByUserId(userId: number): Promise<RequestDetailRaw[]>;
  findCompletedRequests(userId: number): Promise<RequestDetailRaw[]>;
  findItemInfo(itemId: number): Promise<{ sellerId: number; status: string } | null>;
  approveRequest(requestId: number): Promise<RequestDetailRaw>;
  declineRequest(requestId: number): Promise<RequestDetailRaw>;
  cancelRequest(requestId: number): Promise<RequestDetailRaw>;
  completeRequest(requestId: number): Promise<RequestDetailRaw>;
}
