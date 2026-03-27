import { GroupEntity } from '../entities/group.entity';
import { GroupMemberEntity } from '../entities/groupMember.entity';

export interface IGroupRepository {
  createGroup(name: string, ownerId: number): Promise<GroupEntity>;
  findGroupById(groupId: number): Promise<GroupEntity | null>;
  createInviteToken(groupId: number, token: string, expiresAt: Date): Promise<{ token: string; expiresAt: Date }>;
  findInviteToken(token: string): Promise<{
    id: number;
    groupId: number;
    token: string;
    expiresAt: Date;
    usedAt: Date | null;
  } | null>;
  markTokenUsed(tokenId: number): Promise<void>;
  addMember(groupId: number, userId: number): Promise<GroupMemberEntity>;
  isMember(groupId: number, userId: number): Promise<boolean>;
  findGroupsByUserId(userId: number): Promise<GroupEntity[]>;
}
