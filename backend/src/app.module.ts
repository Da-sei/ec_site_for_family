import { Module } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';

// uploads ディレクトリを起動時に確保（静的配信は main.ts で設定）
fs.mkdirSync(path.join(process.cwd(), 'uploads'), { recursive: true });

import { PrismaModule } from '../prisma/prisma.module';
import { UserModule } from './domains/user/user.module';
import { AuthModule } from './domains/auth/auth.module';
import { GroupModule } from './domains/group/group.module';
import { ItemModule } from './domains/item/item.module';
import { RequestModule } from './domains/request/request.module';
import { FavoriteModule } from './domains/favorite/favorite.module';

@Module({
  imports: [
    PrismaModule,
    UserModule,
    AuthModule,
    GroupModule,
    ItemModule,
    RequestModule,
    FavoriteModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
