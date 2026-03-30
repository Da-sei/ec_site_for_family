import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Inject,
} from '@nestjs/common';
import { Request } from 'express';
import type { JwtPayload } from '../../domains/auth/decorators/current-user.decorator';
import { PrismaService } from '../../../prisma/prisma.service';

@Injectable()
export class GroupMemberGuard implements CanActivate {
  constructor(@Inject(PrismaService) private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request & { user: JwtPayload }>();
    const user = request.user;

    let groupId: number | null = null;

    // First try query param groupId
    const groupIdParam = request.query.groupId;
    if (groupIdParam && typeof groupIdParam === 'string') {
      groupId = parseInt(groupIdParam, 10);
    } else if (Array.isArray(groupIdParam) && groupIdParam.length > 0 && typeof groupIdParam[0] === 'string') {
      groupId = parseInt(groupIdParam[0] as string, 10);
    }

    // Try request body groupId (POST /items など)
    if (!groupId && request.body?.groupId != null) {
      const bodyGroupId = request.body.groupId;
      if (typeof bodyGroupId === 'number') {
        groupId = bodyGroupId;
      } else if (typeof bodyGroupId === 'string') {
        groupId = parseInt(bodyGroupId, 10);
      }
    }

    // If route has :id param and no groupId query, look up item's groupId
    if (!groupId && request.params.id) {
      const rawId = request.params.id;
      const itemId = parseInt(typeof rawId === 'string' ? rawId : rawId[0], 10);
      const item = await this.prisma.items.findUnique({
        where: { id: itemId },
        select: { groupId: true },
      });
      if (item) {
        groupId = item.groupId;
      }
    }

    if (!groupId) {
      throw new ForbiddenException('グループIDが必要です');
    }

    const member = await this.prisma.groupMembers.findUnique({
      where: { groupId_userId: { groupId, userId: user.sub } },
    });

    if (!member) {
      throw new ForbiddenException('このグループのメンバーではありません');
    }

    return true;
  }
}
