import { Injectable, Inject } from '@nestjs/common';
import { PrismaService } from '../../../../prisma/prisma.service';
import { UserEntity } from '../domain/entity';
import { IUserQueryRepository } from '../domain/interfaces/user.query.interface';

@Injectable()
export class UserQueryRepository implements IUserQueryRepository {
  constructor(@Inject(PrismaService) private readonly prisma: PrismaService) {}

  // ユーザ情報の取得
  async findById(id: number): Promise<UserEntity | null> {
    const record = await this.prisma.users.findUnique({ where: { id } });

    if (!record) return null;
    
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
