import { Injectable, Inject } from '@nestjs/common';
import { PrismaService } from '../../../../prisma/prisma.service';
import { GroupEntity } from '../domain/entities/group.entity';
import { GroupMemberEntity } from '../domain/entities/groupMember.entity';
import { IGroupRepository } from '../domain/interfaces/group.repository.interface';

@Injectable()
export class GroupRepository implements IGroupRepository {

  constructor(
    @Inject(PrismaService) 
    private readonly prisma: PrismaService
  ) {}

  // グループの作成
  async createGroup(
    name: string, 
    ownerId: number
  ): Promise<GroupEntity> {
    const group = await this.prisma.groups.create({
      data: { name, ownerId },
    });
    // auto-register owner as member
    await this.prisma.groupMembers.create({
      data: { groupId: group.id, userId: ownerId },
    });
    return new GroupEntity(group);
  }

  // グループの取得
  async findGroupById(
    groupId: number
  ): Promise<GroupEntity | null> {
    const group = await this.prisma.groups.findUnique({ where: { id: groupId } });
    if (!group) return null;
    return new GroupEntity(group);
  }

  // 招待コードの作成
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
  } | null> {
    return this.prisma.inviteTokens.findUnique({
      where: { token },
      select: { id: true, groupId: true, token: true, expiresAt: true },
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

  async findMembersWithUser(groupId: number): Promise<{ userId: number; accountId: string; name: string; joinedAt: Date }[]> {
    const members = await this.prisma.groupMembers.findMany({
      where: { groupId },
      include: { user: true },
      orderBy: { joinedAt: 'asc' },
    });
    return members.map((m) => ({
      userId: m.userId,
      accountId: m.user.accountId,
      name: m.user.name,
      joinedAt: m.joinedAt,
    }));
  }

  async updateGroupName(groupId: number, name: string): Promise<GroupEntity> {
    const group = await this.prisma.groups.update({
      where: { id: groupId },
      data: { name },
    });
    return new GroupEntity(group);
  }

  async removeMember(groupId: number, userId: number): Promise<void> {
    await this.prisma.groupMembers.delete({
      where: { groupId_userId: { groupId, userId } },
    });
  }

  async transferOwner(groupId: number, newOwnerId: number): Promise<GroupEntity> {
    const group = await this.prisma.groups.update({
      where: { id: groupId },
      data: { ownerId: newOwnerId },
    });
    return new GroupEntity(group);
  }
}
