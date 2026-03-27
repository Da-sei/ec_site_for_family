import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { WishlistService } from './wishlist.service';

const mockRepo = {
  create: jest.fn(),
  findByGroupId: jest.fn(),
  findById: jest.fn(),
  update: jest.fn(),
  delete: jest.fn(),
};

const mockPrisma = {
  groupMembers: {
    findUnique: jest.fn(),
  },
};

const rawItem = {
  id: 1,
  title: 'テストアイテム',
  description: null,
  groupId: 10,
  requesterId: 5,
  requester: { id: 5, accountId: 'user5', name: 'ユーザー5' },
  createdAt: new Date('2026-01-01'),
  updatedAt: new Date('2026-01-01'),
};

describe('WishlistService', () => {
  let service: WishlistService;

  beforeEach(() => {
    jest.clearAllMocks();
    service = new WishlistService(mockRepo as any, mockPrisma as any);
  });

  describe('createWishlistItem', () => {
    it('グループメンバーはアイテムを作成できる', async () => {
      mockPrisma.groupMembers.findUnique.mockResolvedValue({ id: 1 });
      mockRepo.create.mockResolvedValue(rawItem);

      const result = await service.createWishlistItem(5, {
        title: 'テストアイテム',
        groupId: 10,
      });

      expect(result.id).toBe(1);
      expect(result.title).toBe('テストアイテム');
    });

    it('非グループメンバーはForbiddenExceptionが投げられる', async () => {
      mockPrisma.groupMembers.findUnique.mockResolvedValue(null);

      await expect(
        service.createWishlistItem(5, { title: 'テスト', groupId: 10 }),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('getWishlistItems', () => {
    it('グループのウィッシュリスト一覧を返す', async () => {
      mockRepo.findByGroupId.mockResolvedValue([rawItem]);
      const result = await service.getWishlistItems(10);
      expect(result).toHaveLength(1);
    });
  });

  describe('getWishlistItemById', () => {
    it('グループメンバーはアイテム詳細を取得できる', async () => {
      mockRepo.findById.mockResolvedValue(rawItem);
      mockPrisma.groupMembers.findUnique.mockResolvedValue({ id: 1 });

      const result = await service.getWishlistItemById(1, 5);
      expect(result.id).toBe(1);
    });

    it('存在しないIDはNotFoundExceptionが投げられる', async () => {
      mockRepo.findById.mockResolvedValue(null);

      await expect(service.getWishlistItemById(99, 5)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('非グループメンバーはForbiddenExceptionが投げられる', async () => {
      mockRepo.findById.mockResolvedValue(rawItem);
      mockPrisma.groupMembers.findUnique.mockResolvedValue(null);

      await expect(service.getWishlistItemById(1, 99)).rejects.toThrow(
        ForbiddenException,
      );
    });
  });

  describe('updateWishlistItem', () => {
    it('アイテムを更新してDTOを返す', async () => {
      const updated = { ...rawItem, title: '更新後' };
      mockRepo.update.mockResolvedValue(updated);

      const result = await service.updateWishlistItem(1, { title: '更新後' });
      expect(result.title).toBe('更新後');
    });
  });

  describe('deleteWishlistItem', () => {
    it('アイテムを削除する', async () => {
      mockRepo.delete.mockResolvedValue(undefined);
      await expect(service.deleteWishlistItem(1)).resolves.toBeUndefined();
    });
  });
});
