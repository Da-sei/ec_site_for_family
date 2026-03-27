import { ExecutionContext, ForbiddenException, NotFoundException } from '@nestjs/common';
import { WishlistItemOwnerGuard } from './wishlist-item-owner.guard';

const mockPrisma = {
  wishlistItems: {
    findUnique: jest.fn(),
  },
};

function makeContext(userId: number, itemId: string): ExecutionContext {
  return {
    switchToHttp: () => ({
      getRequest: () => ({
        user: { sub: userId, accountId: 'user1' },
        params: { id: itemId },
      }),
    }),
  } as unknown as ExecutionContext;
}

describe('WishlistItemOwnerGuard', () => {
  let guard: WishlistItemOwnerGuard;

  beforeEach(() => {
    jest.clearAllMocks();
    guard = new WishlistItemOwnerGuard(mockPrisma as any);
  });

  it('投稿者自身はアクセスを許可する', async () => {
    mockPrisma.wishlistItems.findUnique.mockResolvedValue({ requesterId: 1 });
    const result = await guard.canActivate(makeContext(1, '42'));
    expect(result).toBe(true);
  });

  it('存在しないIDの場合はNotFoundExceptionを投げる', async () => {
    mockPrisma.wishlistItems.findUnique.mockResolvedValue(null);
    await expect(guard.canActivate(makeContext(1, '99'))).rejects.toThrow(NotFoundException);
  });

  it('投稿者以外はForbiddenExceptionを投げる', async () => {
    mockPrisma.wishlistItems.findUnique.mockResolvedValue({ requesterId: 2 });
    await expect(guard.canActivate(makeContext(1, '42'))).rejects.toThrow(ForbiddenException);
  });
});
