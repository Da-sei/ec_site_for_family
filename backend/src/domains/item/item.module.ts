import { Module } from '@nestjs/common';
import { PrismaModule } from '../../../prisma/prisma.module';
import { ItemController } from './controller/item.controller';
import { ItemService } from './service/item.service';
import { ItemRepository } from './infra/item.repository';

@Module({
  imports: [PrismaModule],
  controllers: [ItemController],
  providers: [
    ItemService,
    {
      provide: 'ITEM_REPOSITORY',
      useClass: ItemRepository,
    },
  ],
  exports: [ItemService],
})
export class ItemModule {}
