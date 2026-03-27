export class GroupMemberEntity {
  public readonly id: number;
  public readonly groupId: number;
  public readonly userId: number;
  public readonly joinedAt: Date;

  constructor({
    id,
    groupId,
    userId,
    joinedAt,
  }: {
    id: number;
    groupId: number;
    userId: number;
    joinedAt: Date;
  }) {
    this.id = id;
    this.groupId = groupId;
    this.userId = userId;
    this.joinedAt = joinedAt;
  }
}
