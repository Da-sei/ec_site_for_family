import { Injectable, OnModuleInit } from '@nestjs/common';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  constructor() {
    const connectionString = process.env.DATABASE_URL;
    if (!connectionString) {
      throw new Error('DATABASE_URL is not set');
    }
    // Prisma 7 adapter package may be inferred as an error type by ESLint's type service.
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-call
    const adapter = new PrismaPg({ connectionString });
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    super({ adapter });
  }

  // アプリケーションが起動したときにデータベースに接続する
  async onModuleInit() {
    await this.$connect();
  }
}
