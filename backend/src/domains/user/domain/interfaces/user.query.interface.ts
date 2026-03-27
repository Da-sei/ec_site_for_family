import { UserEntity } from '../entity';

export interface IUserQueryRepository {
  // ユーザ情報にの取得
  findById(id: number): Promise<UserEntity | null>;
}
