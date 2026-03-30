import { Injectable, Inject } from '@nestjs/common';
import { PrismaService } from '../../../../prisma/prisma.service';
import { UserEntity } from '../domain/entity';
import { IUserCommandRepository, UpdateUserData } from '../domain/interfaces/user.command.interface';

@Injectable()
export class UserCommandRepository implements IUserCommandRepository {
  constructor(@Inject(PrismaService) private readonly prisma: PrismaService) {}

  // ユーザの登録
  async signIn(user: UserEntity): Promise<UserEntity> {
    const registeredUser = await this.prisma.users.create({
      data: {
        accountId: user.accountId,
        name: user.name,
        passwordHash: user.passwordHash,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      },
    });

    return new UserEntity({
      id: registeredUser.id,
      accountId: registeredUser.accountId,
      name: registeredUser.name,
      passwordHash: registeredUser.passwordHash,
      createdAt: registeredUser.createdAt,
      updatedAt: registeredUser.updatedAt,
    });
  }

  // ユーザ情報の更新
  async updateUser(id: number, data: UpdateUserData): Promise<UserEntity> {
    const record = await this.prisma.users.update({
      where: { id },
      data: {
        ...(data.name !== undefined && { name: data.name }),
        ...(data.passwordHash !== undefined && { passwordHash: data.passwordHash }),
        updatedAt: new Date(),
      },
    });
    return new UserEntity({
      id: record.id,
      accountId: record.accountId,
      name: record.name,
      passwordHash: record.passwordHash,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    });
  }
}
