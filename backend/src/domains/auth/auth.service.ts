import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { randomUUID } from 'crypto';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../../../prisma/prisma.service';
import { UserEntity } from '../user/domain/entity';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  async validateUser(accountId: string, password: string): Promise<UserEntity | null> {
    const record = await this.prisma.users.findUnique({ where: { accountId } });
    if (!record) return null;

    const isMatch = await bcrypt.compare(password, record.passwordHash);
    if (!isMatch) return null;

    return new UserEntity({
      id: record.id,
      accountId: record.accountId,
      name: record.name,
      passwordHash: record.passwordHash,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    });
  }

  async register(name: string, password: string): Promise<{ accountId: string; accessToken: string }> {
    const accountId = randomUUID();
    const passwordHash = await bcrypt.hash(password, 10);
    const now = new Date();

    const record = await this.prisma.users.create({
      data: {
        accountId,
        name,
        passwordHash,
        createdAt: now,
        updatedAt: now,
      },
    });

    const user = new UserEntity({
      id: record.id,
      accountId: record.accountId,
      name: record.name,
      passwordHash: record.passwordHash,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    });

    const accessToken = this.jwtService.sign({ sub: user.id, accountId: user.accountId });
    return { accountId: user.accountId, accessToken };
  }

  login(user: UserEntity): { accessToken: string } {
    const accessToken = this.jwtService.sign({ sub: user.id, accountId: user.accountId });
    return { accessToken };
  }
}
