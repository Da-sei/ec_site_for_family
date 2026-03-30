import { GroupEntity } from '../entities/group.entity';
import { GroupMemberEntity } from '../entities/groupMember.entity';

export interface MemberWithUser {
  userId: number;
  accountId: string;
  name: string;
  joinedAt: Date;
}

export interface IGroupRepository {
  createGroup(name: string, ownerId: number): Promise<GroupEntity>;
  findGroupById(groupId: number): Promise<GroupEntity | null>;
  createInviteToken(groupId: number, token: string, expiresAt: Date): Promise<{ token: string; expiresAt: Date }>;
  findInviteToken(token: string): Promise<{
    id: number;
    groupId: number;
    token: string;
    expiresAt: Date;
  } | null>;
  addMember(groupId: number, userId: number): Promise<GroupMemberEntity>;
  isMember(groupId: number, userId: number): Promise<boolean>;
  findGroupsByUserId(userId: number): Promise<GroupEntity[]>;
  findMembersWithUser(groupId: number): Promise<MemberWithUser[]>;
  updateGroupName(groupId: number, name: string): Promise<GroupEntity>;
  removeMember(groupId: number, userId: number): Promise<void>;
  transferOwner(groupId: number, newOwnerId: number): Promise<GroupEntity>;
}
