import {
  Injectable,
  Inject,
  ForbiddenException,
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import type { IGroupRepository, MemberWithUser } from '../domain/interfaces/group.repository.interface';
import { GroupEntity } from './../domain/entities/group.entity';
import { GroupMemberEntity } from './../domain/entities/groupMember.entity';

@Injectable()
export class GroupService {

  constructor(
    @Inject('GROUP_REPOSITORY')
    private readonly groupRepo: IGroupRepository,
  ) {}

  async createGroup(
    name: string, 
    ownerId: number
  ): Promise<GroupEntity> {
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

  async joinGroup(
    token: string,
    userId: number
  ): Promise<GroupMemberEntity> {
    const invite = await this.groupRepo.findInviteToken(token);
    if (!invite || invite.expiresAt < new Date()) {
      throw new BadRequestException('招待リンクが無効または期限切れです');
    }

    const alreadyMember = await this.groupRepo.isMember(invite.groupId, userId);
    if (alreadyMember) {
      throw new ConflictException('すでにこのグループのメンバーです');
    }

    return this.groupRepo.addMember(invite.groupId, userId);
  }

  async transferOwner(
    groupId: number,
    newOwnerId: number,
    requesterId: number,
  ): Promise<GroupEntity> {
    const group = await this.groupRepo.findGroupById(groupId);
    if (!group) throw new NotFoundException('グループが見つかりません');
    if (group.ownerId !== requesterId) {
      throw new ForbiddenException('グループオーナーのみオーナーを移譲できます');
    }
    if (newOwnerId === requesterId) {
      throw new BadRequestException('自分自身に移譲はできません');
    }
    const isMember = await this.groupRepo.isMember(groupId, newOwnerId);
    if (!isMember) {
      throw new BadRequestException('移譲先のユーザーはグループメンバーではありません');
    }
    return this.groupRepo.transferOwner(groupId, newOwnerId);
  }

  async getMyGroups(
    userId: number
  ): Promise<GroupEntity[]> {
    return this.groupRepo.findGroupsByUserId(userId);
  }

  async getMembers(
    groupId: number,
    requesterId: number,
  ): Promise<MemberWithUser[]> {
    const isMember = await this.groupRepo.isMember(groupId, requesterId);
    if (!isMember) {
      throw new ForbiddenException('グループのメンバーのみ閲覧できます');
    }
    return this.groupRepo.findMembersWithUser(groupId);
  }

  async updateGroup(
    groupId: number,
    name: string,
    requesterId: number,
  ): Promise<GroupEntity> {
    const group = await this.groupRepo.findGroupById(groupId);
    if (!group) throw new NotFoundException('グループが見つかりません');
    if (group.ownerId !== requesterId) {
      throw new ForbiddenException('グループオーナーのみ編集できます');
    }
    if (!name || name.trim().length === 0) {
      throw new BadRequestException('グループ名は必須です');
    }
    return this.groupRepo.updateGroupName(groupId, name.trim());
  }

  async leaveGroup(groupId: number, userId: number): Promise<void> {
    const group = await this.groupRepo.findGroupById(groupId);
    if (!group) throw new NotFoundException('グループが見つかりません');
    if (group.ownerId === userId) {
      throw new BadRequestException('オーナーはグループを退出できません。先にオーナーを譲渡してください');
    }
    const isMember = await this.groupRepo.isMember(groupId, userId);
    if (!isMember) throw new BadRequestException('このグループのメンバーではありません');
    await this.groupRepo.removeMember(groupId, userId);
  }

  async removeGroupMember(
    groupId: number,
    targetUserId: number,
    requesterId: number,
  ): Promise<void> {
    const group = await this.groupRepo.findGroupById(groupId);
    if (!group) throw new NotFoundException('グループが見つかりません');
    if (group.ownerId !== requesterId) {
      throw new ForbiddenException('グループオーナーのみメンバーを除名できます');
    }
    if (targetUserId === requesterId) {
      throw new BadRequestException('自分自身を除名できません');
    }
    const isMember = await this.groupRepo.isMember(groupId, targetUserId);
    if (!isMember) throw new BadRequestException('対象ユーザーはメンバーではありません');
    await this.groupRepo.removeMember(groupId, targetUserId);
  }
}
