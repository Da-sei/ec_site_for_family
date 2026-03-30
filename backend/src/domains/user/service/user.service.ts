import { Injectable, Inject, NotFoundException, BadRequestException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { UserEntity } from '../domain/entity';
import type { IUserQueryRepository } from '../domain/interfaces/user.query.interface';
import type { IUserCommandRepository } from '../domain/interfaces/user.command.interface';

@Injectable()
export class UserService {
  constructor(
    @Inject('USER_QUERY_REPOSITORY')
    private readonly userQueryRepo: IUserQueryRepository,
    @Inject('USER_COMMAND_REPOSITORY')
    private readonly userCommandRepo: IUserCommandRepository,
  ) {}

  // ユーザ情報の取得
  async getProfile(userId: number): Promise<UserEntity | null> {
    return this.userQueryRepo.findById(userId);
  }

  // ユーザ情報の更新
  async updateProfile(
    userId: number,
    dto: { name?: string; currentPassword?: string; newPassword?: string },
  ): Promise<UserEntity> {
    const user = await this.userQueryRepo.findById(userId);
    if (!user) throw new NotFoundException('ユーザーが見つかりません');

    const data: { name?: string; passwordHash?: string } = {};

    if (dto.name !== undefined) {
      data.name = dto.name;
    }

    if (dto.newPassword) {
      if (!dto.currentPassword) {
        throw new BadRequestException('現在のパスワードが必要です');
      }
      const isMatch = await bcrypt.compare(dto.currentPassword, user.passwordHash);
      if (!isMatch) {
        throw new BadRequestException('現在のパスワードが正しくありません');
      }
      data.passwordHash = await bcrypt.hash(dto.newPassword, 10);
    }

    return this.userCommandRepo.updateUser(userId, data);
  }
}
