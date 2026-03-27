export class UserEntity {
  public readonly id: number;
  public readonly accountId: string;
  public readonly name: string;
  public readonly passwordHash: string;
  public readonly createdAt: Date;
  public readonly updatedAt: Date;

  constructor({
    id,
    accountId,
    name,
    passwordHash,
    createdAt,
    updatedAt,
  }: {
    id: number;
    accountId: string;
    name: string;
    passwordHash: string;
    createdAt: Date;
    updatedAt: Date;
  }) {
    this.id = id;
    this.accountId = accountId;
    this.name = name;
    this.passwordHash = passwordHash;
    this.createdAt = createdAt;
    this.updatedAt = updatedAt;
  }

  // ユーザ情報の登録
  register(): UserEntity {
    return new UserEntity({
      ...this,
    });
  }

  // ユーザ情報の更新
  updated({
    name,
  }: {
    name: string;
  }): UserEntity {
    return new UserEntity({
      ...this,
      name,
      updatedAt: new Date(),
    });
  }
}
