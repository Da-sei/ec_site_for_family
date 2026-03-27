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

export interface CreateGroupDto {
  name: string;
}

export interface JoinGroupDto {
  token: string;
}
