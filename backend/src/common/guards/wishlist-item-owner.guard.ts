import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  NotFoundException,
  Inject,
} from '@nestjs/common';
import { Request } from 'express';
import type { JwtPayload } from '../../domains/auth/decorators/current-user.decorator';
import { PrismaService } from '../../../prisma/prisma.service';

@Injectable()
export class WishlistItemOwnerGuard implements CanActivate {
  constructor(
    @Inject(PrismaService) private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context
      .switchToHttp()
      .getRequest<Request & { user: JwtPayload }>();
    const user = request.user;
    const idParam = request.params.id;
    const itemId = parseInt(
      Array.isArray(idParam) ? idParam[0] : idParam,
      10,
    );

    const item = await this.prisma.wishlistItems.findUnique({
      where: { id: itemId },
      select: { requesterId: true },
    });

    if (!item) {
      throw new NotFoundException('ウィッシュリストアイテムが見つかりません');
    }

    if (item.requesterId !== user.sub) {
      throw new ForbiddenException('この操作は許可されていません');
    }

    return true;
  }
}
