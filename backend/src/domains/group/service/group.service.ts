import {
  Injectable,
  Inject,
  ForbiddenException,
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import type { IGroupRepository } from '../domain/interfaces/group.repository.interface';
import { GroupEntity } from './../domain/entities/group.entity';
import { GroupMemberEntity } from './../domain/entities/groupMember.entity';

@Injectable()
export class GroupService {
  constructor(
    @Inject('GROUP_REPOSITORY')
    private readonly groupRepo: IGroupRepository,
  ) {}

  async createGroup(name: string, ownerId: number): Promise<GroupEntity> {
    return this.groupRepo.createGroup(name, ownerId);
  }

  async issueInviteToken(
    groupId: number,
    requesterId: number,
  ): Promise<{ token: string; expiresAt: Date }> {
    const group = await this.groupRepo.findGroupById(groupId);
    if (!group) {
      throw new NotFoundException('グループが見つかりません');
    }
    if (group.ownerId !== requesterId) {
      throw new ForbiddenException('グループオーナーのみ招待トークンを発行できます');
    }
    const token = uuidv4();
    const expiresAt = new Date(Date.now() + 48 * 60 * 60 * 1000);
    return this.groupRepo.createInviteToken(groupId, token, expiresAt);
  }

  async joinGroup(token: string, userId: number): Promise<GroupMemberEntity> {
    const invite = await this.groupRepo.findInviteToken(token);
    if (
      !invite ||
      invite.usedAt !== null ||
      invite.expiresAt < new Date()
    ) {
      throw new BadRequestException('招待リンクが無効または期限切れです');
    }

    const alreadyMember = await this.groupRepo.isMember(invite.groupId, userId);
    if (alreadyMember) {
      throw new ConflictException('すでにこのグループのメンバーです');
    }

    await this.groupRepo.markTokenUsed(invite.id);
    return this.groupRepo.addMember(invite.groupId, userId);
  }

  async getMyGroups(userId: number): Promise<GroupEntity[]> {
    return this.groupRepo.findGroupsByUserId(userId);
  }
}
