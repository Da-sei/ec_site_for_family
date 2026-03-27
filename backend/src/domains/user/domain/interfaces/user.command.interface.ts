import { UserEntity } from '../entity';

export interface IUserCommandRepository {
  // ユーザ情報の登録
  signIn(user: UserEntity): Promise<UserEntity>;
}
