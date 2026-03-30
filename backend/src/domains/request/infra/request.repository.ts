import { Injectable, Inject } from '@nestjs/common';
import { PrismaService } from '../../../../prisma/prisma.service';
import {
  IRequestRepository,
  RequestDetailRaw,
} from '../domain/interfaces/request.repository.interface';

const requestInclude = {
  requester: { select: { id: true, accountId: true, name: true } },
  item: { select: { sellerId: true, status: true, groupId: true } },
};

function toRaw(r: any): RequestDetailRaw {
  return {
    id: r.id,
    itemId: r.itemId,
    requester: r.requester,
    status: r.status,
    deliveryMethod: r.deliveryMethod ?? null,
    createdAt: r.createdAt,
    completedAt: r.completedAt ?? null,
    item: r.item,
  };
}

@Injectable()
export class RequestRepository implements IRequestRepository {
  constructor(@Inject(PrismaService) private readonly prisma: PrismaService) {}

  async createRequest(itemId: number, requesterId: number, deliveryMethod: string): Promise<RequestDetailRaw> {
    const request = await this.prisma.requests.create({
      data: { itemId, requesterId, status: 'PENDING', deliveryMethod: deliveryMethod as import('@prisma/client').DeliveryMethod },
      include: requestInclude,
    });
    return toRaw(request);
  }

  async findRequestById(id: number): Promise<RequestDetailRaw | null> {
    const r = await this.prisma.requests.findUnique({
      where: { id },
      include: requestInclude,
    });
    if (!r) return null;
    return toRaw(r);
  }

  async findRequestsByItemId(itemId: number): Promise<RequestDetailRaw[]> {
    const requests = await this.prisma.requests.findMany({
      where: { itemId },
      include: requestInclude,
      orderBy: { createdAt: 'desc' },
    });
    return requests.map(toRaw);
  }

  async findRequestsByUserId(userId: number): Promise<RequestDetailRaw[]> {
    const requests = await this.prisma.requests.findMany({
      where: { requesterId: userId },
      include: requestInclude,
      orderBy: { createdAt: 'desc' },
    });
    return requests.map(toRaw);
  }

  async findCompletedRequests(userId: number): Promise<RequestDetailRaw[]> {
    const requests = await this.prisma.requests.findMany({
      where: {
        status: 'COMPLETED',
        OR: [
          { requesterId: userId },
          { item: { sellerId: userId } },
        ],
      },
      include: requestInclude,
      orderBy: { createdAt: 'desc' },
    });
    return requests.map(toRaw);
  }

  async findItemInfo(itemId: number): Promise<{ sellerId: number; status: string } | null> {
    const item = await this.prisma.items.findUnique({
      where: { id: itemId },
      select: { sellerId: true, status: true },
    });
    if (!item) return null;
    return { sellerId: item.sellerId, status: item.status };
  }

  async approveRequest(requestId: number): Promise<RequestDetailRaw> {
    const updated = await this.prisma.$transaction(async (tx) => {
      const req = await tx.requests.findUnique({ where: { id: requestId } });
      await tx.items.update({
        where: { id: req!.itemId },
        data: { status: 'IN_TRANSACTION' },
      });
      // 他のPENDINGリクエストを自動辞退
      await tx.requests.updateMany({
        where: { itemId: req!.itemId, id: { not: requestId }, status: 'PENDING' },
        data: { status: 'DECLINED' },
      });
      return tx.requests.update({
        where: { id: requestId },
        data: { status: 'APPROVED' },
        include: requestInclude,
      });
    });
    return toRaw(updated);
  }

  async declineRequest(requestId: number): Promise<RequestDetailRaw> {
    const r = await this.prisma.requests.update({
      where: { id: requestId },
      data: { status: 'DECLINED' },
      include: requestInclude,
    });
    return toRaw(r);
  }

  async cancelRequest(requestId: number): Promise<RequestDetailRaw> {
    const updated = await this.prisma.$transaction(async (tx) => {
      const req = await tx.requests.findUnique({ where: { id: requestId } });
      await tx.items.update({
        where: { id: req!.itemId },
        data: { status: 'AVAILABLE' },
      });
      return tx.requests.update({
        where: { id: requestId },
        data: { status: 'CANCELLED' },
        include: requestInclude,
      });
    });
    return toRaw(updated);
  }

  async completeRequest(requestId: number): Promise<RequestDetailRaw> {
    const updated = await this.prisma.$transaction(async (tx) => {
      const req = await tx.requests.findUnique({ where: { id: requestId } });
      await tx.items.update({
        where: { id: req!.itemId },
        data: { status: 'TRANSFERRED' },
      });
      return tx.requests.update({
        where: { id: requestId },
        data: { status: 'COMPLETED', completedAt: new Date() },
        include: requestInclude,
      });
    });
    return toRaw(updated);
  }
}
