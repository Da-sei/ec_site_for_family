export class GroupEntity {
  public readonly id: number;
  public readonly name: string;
  public readonly ownerId: number;
  public readonly createdAt: Date;

  constructor({
    id,
    name,
    ownerId,
    createdAt,
  }: {
    id: number;
    name: string;
    ownerId: number;
    createdAt: Date;
  }) {
    this.id = id;
    this.name = name;
    this.ownerId = ownerId;
    this.createdAt = createdAt;
  }
}