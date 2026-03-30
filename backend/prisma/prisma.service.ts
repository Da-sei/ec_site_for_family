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
    // sslmode in the URL is parsed by pg-connection-string and overrides our ssl option,
    // so we strip it and configure ssl explicitly to allow Supabase's certificate chain.
    const cleanUrl = connectionString.replace(/[?&]sslmode=[^&]*/g, '').replace(/[?&]$/, '');
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-call
    const adapter = new PrismaPg({ connectionString: cleanUrl, ssl: { rejectUnauthorized: false } });
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    super({ adapter });
  }

  // アプリケーションが起動したときにデータベースに接続する
  async onModuleInit() {
    await this.$connect();
  }
}
