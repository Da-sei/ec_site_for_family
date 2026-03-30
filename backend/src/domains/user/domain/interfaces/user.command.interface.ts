import { UserEntity } from '../entity';

export interface UpdateUserData {
  name?: string;
  passwordHash?: string;
}

export interface IUserCommandRepository {
  // ユーザ情報の登録
  signIn(user: UserEntity): Promise<UserEntity>;
  // ユーザ情報の更新
  updateUser(id: number, data: UpdateUserData): Promise<UserEntity>;
}
