import { Injectable, Inject } from '@nestjs/common';
import { PrismaService } from '../../../../prisma/prisma.service';
import { GroupEntity } from '../domain/entities/group.entity';
import { GroupMemberEntity } from '../domain/entities/groupMember.entity';
import { IGroupRepository } from '../domain/interfaces/group.repository.interface';

@Injectable()
export class GroupRepository implements IGroupRepository {
  constructor(@Inject(PrismaService) private readonly prisma: PrismaService) {}

  async createGroup(name: string, ownerId: number): Promise<GroupEntity> {
    const group = await this.prisma.groups.create({
      data: { name, ownerId },
    });
    // auto-register owner as member
    await this.prisma.groupMembers.create({
      data: { groupId: group.id, userId: ownerId },
    });
    return new GroupEntity(group);
  }

  async findGroupById(groupId: number): Promise<GroupEntity | null> {
    const group = await this.prisma.groups.findUnique({ where: { id: groupId } });
    if (!group) return null;
    return new GroupEntity(group);
  }

  async createInviteToken(
    groupId: number,
    token: string,
    expiresAt: Date,
  ): Promise<{ token: string; expiresAt: Date }> {
    const invite = await this.prisma.inviteTokens.create({
      data: { groupId, token, expiresAt },
    });
    return { token: invite.token, expiresAt: invite.expiresAt };
  }

  async findInviteToken(token: string): Promise<{
    id: number;
    groupId: number;
    token: string;
    expiresAt: Date;
    usedAt: Date | null;
  } | null> {
    return this.prisma.inviteTokens.findUnique({ where: { token } });
  }

  async markTokenUsed(tokenId: number): Promise<void> {
    await this.prisma.inviteTokens.update({
      where: { id: tokenId },
      data: { usedAt: new Date() },
    });
  }

  async addMember(groupId: number, userId: number): Promise<GroupMemberEntity> {
    const member = await this.prisma.groupMembers.create({
      data: { groupId, userId },
    });
    return new GroupMemberEntity(member);
  }

  async isMember(groupId: number, userId: number): Promise<boolean> {
    const member = await this.prisma.groupMembers.findUnique({
      where: { groupId_userId: { groupId, userId } },
    });
    return member !== null;
  }

  async findGroupsByUserId(userId: number): Promise<GroupEntity[]> {
    const members = await this.prisma.groupMembers.findMany({
      where: { userId },
      include: { group: true },
    });
    return members.map((m) => new GroupEntity(m.group));
  }
}
