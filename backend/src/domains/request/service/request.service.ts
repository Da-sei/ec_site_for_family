import {
  Injectable,
  Inject,
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import type {
  IRequestRepository,
  RequestDetailRaw,
} from '../domain/interfaces/request.repository.interface';
import type { RequestDto } from '../domain/dto/request.dto';

function toDto(raw: RequestDetailRaw): RequestDto {
  return {
    id: raw.id,
    itemId: raw.itemId,
    requester: raw.requester,
    status: raw.status,
    deliveryMethod: raw.deliveryMethod,
    createdAt: raw.createdAt,
    completedAt: raw.completedAt,
  };
}

@Injectable()
export class RequestService {
  constructor(
    @Inject('REQUEST_REPOSITORY')
    private readonly requestRepo: IRequestRepository,
  ) {}

  async createRequest(itemId: number, requesterId: number, deliveryMethod: string): Promise<RequestDto> {
    const itemInfo = await this.requestRepo.findItemInfo(itemId);

    if (!itemInfo) {
      throw new NotFoundException('商品が見つかりません');
    }

    if (itemInfo.sellerId === requesterId) {
      throw new BadRequestException('自分の出品には申し込みできません');
    }

    if (itemInfo.status !== 'AVAILABLE') {
      throw new ConflictException('この商品はすでに取引中または譲渡済みです');
    }

    const raw = await this.requestRepo.createRequest(itemId, requesterId, deliveryMethod);
    return toDto(raw);
  }

  async approveRequest(requestId: number, sellerId: number): Promise<RequestDto> {
    const request = await this.requestRepo.findRequestById(requestId);
    if (!request) throw new NotFoundException('申し込みが見つかりません');
    if (request.item.sellerId !== sellerId) throw new ForbiddenException('この操作は許可されていません');
    const raw = await this.requestRepo.approveRequest(requestId);
    return toDto(raw);
  }

  async declineRequest(requestId: number, sellerId: number): Promise<RequestDto> {
    const request = await this.requestRepo.findRequestById(requestId);
    if (!request) throw new NotFoundException('申し込みが見つかりません');
    if (request.item.sellerId !== sellerId) throw new ForbiddenException('この操作は許可されていません');
    const raw = await this.requestRepo.declineRequest(requestId);
    return toDto(raw);
  }

  async cancelRequest(requestId: number, userId: number): Promise<RequestDto> {
    const request = await this.requestRepo.findRequestById(requestId);
    if (!request) throw new NotFoundException('申し込みが見つかりません');
    const isSeller = request.item.sellerId === userId;
    const isRequester = request.requester.id === userId;
    if (!isSeller && !isRequester) throw new ForbiddenException('この操作は許可されていません');
    const raw = await this.requestRepo.cancelRequest(requestId);
    return toDto(raw);
  }

  async completeRequest(requestId: number, userId: number): Promise<RequestDto> {
    const request = await this.requestRepo.findRequestById(requestId);
    if (!request) throw new NotFoundException('申し込みが見つかりません');
    const isSeller = request.item.sellerId === userId;
    const isRequester = request.requester.id === userId;
    if (!isRequester && !isSeller) throw new ForbiddenException('この操作は許可されていません');
    if (isSeller && !isRequester) throw new ForbiddenException('申請者のみ取引を完了できます');
    const raw = await this.requestRepo.completeRequest(requestId);
    return toDto(raw);
  }

  async getHistory(userId: number): Promise<RequestDto[]> {
    const requests = await this.requestRepo.findCompletedRequests(userId);
    return requests.map(toDto);
  }

  async getMyRequests(userId: number): Promise<RequestDto[]> {
    const requests = await this.requestRepo.findRequestsByUserId(userId);
    return requests.map(toDto);
  }

  async getRequestsByItemId(itemId: number, userId: number): Promise<RequestDto[]> {
    const requests = await this.requestRepo.findRequestsByItemId(itemId);
    if (requests.length === 0) {
      // verify user is seller of the item before returning empty
      const itemInfo = await this.requestRepo.findItemInfo(itemId);
      if (!itemInfo) throw new NotFoundException('商品が見つかりません');
      if (itemInfo.sellerId !== userId) throw new ForbiddenException('この操作は許可されていません');
      return [];
    }
    if (requests[0].item.sellerId !== userId) {
      throw new ForbiddenException('この操作は許可されていません');
    }
    return requests.map(toDto);
  }
}
