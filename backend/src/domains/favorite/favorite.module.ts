import { Module } from '@nestjs/common';
import { PrismaModule } from '../../../prisma/prisma.module';
import { FavoriteController } from './controller/favorite.controller';
import { FavoriteService } from './service/favorite.service';
import { FavoriteRepository } from './infra/favorite.repository';

@Module({
  imports: [PrismaModule],
  controllers: [FavoriteController],
  providers: [
    FavoriteService,
    {
      provide: 'FAVORITE_REPOSITORY',
      useClass: FavoriteRepository,
    },
  ],
})
export class FavoriteModule {}
