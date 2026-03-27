import { Injectable, Inject } from '@nestjs/common';
import { PrismaService } from '../../../../prisma/prisma.service';
import { UserEntity } from '../domain/entity';
import { IUserCommandRepository } from '../domain/interfaces/user.command.interface';

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
}
