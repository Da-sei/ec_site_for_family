export interface GroupDto {
  id: number;
  name: string;
  ownerId: number;
  createdAt: Date;
}

export interface GroupMemberDto {
  groupId: number;
  userId: number;
  joinedAt: Date;
}

export interface GroupMemberDetailDto {
  userId: number;
  accountId: string;
  name: string;
  joinedAt: Date;
  isOwner: boolean;
}

export interface CreateGroupDto {
  name: string;
}

export interface UpdateGroupDto {
  name: string;
}

export interface JoinGroupDto {
  token: string;
}

export interface TransferOwnerDto {
  newOwnerId: number;
}
