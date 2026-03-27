import { Injectable, Inject } from '@nestjs/common';
import { UserEntity } from '../domain/entity';
import type { IUserQueryRepository } from '../domain/interfaces/user.query.interface';

@Injectable()
export class UserService {
  constructor(
    @Inject('USER_QUERY_REPOSITORY')
    private readonly userQueryRepo: IUserQueryRepository,
  ) {}

  // ユーザ情報の取得
  async getProfile(userId: number): Promise<UserEntity | null> {
    return this.userQueryRepo.findById(userId);
  }
}
