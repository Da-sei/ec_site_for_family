import { Module } from '@nestjs/common';
import { PrismaModule } from '../../../prisma/prisma.module';
import { WishlistController } from './controller/wishlist.controller';
import { WishlistService } from './service/wishlist.service';
import { WishlistRepository } from './infra/wishlist.repository';
import { WishlistItemOwnerGuard } from '../../common/guards/wishlist-item-owner.guard';

@Module({
  imports: [PrismaModule],
  controllers: [WishlistController],
  providers: [
    WishlistService,
    WishlistItemOwnerGuard,
    {
      provide: 'WISHLIST_REPOSITORY',
      useClass: WishlistRepository,
    },
  ],
})
export class WishlistModule {}
