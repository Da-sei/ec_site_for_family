import { Module } from '@nestjs/common';

import { PrismaModule } from '../prisma/prisma.module';
import { UserModule } from './domains/user/user.module';
import { AuthModule } from './domains/auth/auth.module';
import { GroupModule } from './domains/group/group.module';
import { ItemModule } from './domains/item/item.module';
import { RequestModule } from './domains/request/request.module';
import { FavoriteModule } from './domains/favorite/favorite.module';
import { WishlistModule } from './domains/wishlist/wishlist.module';

@Module({
  imports: [
    PrismaModule,
    UserModule,
    AuthModule,
    GroupModule,
    ItemModule,
    RequestModule,
    FavoriteModule,
    WishlistModule,
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}
