import { Module } from '@nestjs/common';
import { PrismaModule } from '../../../prisma/prisma.module';
import { GroupController } from './controller/group.controller';
import { GroupService } from './service/group.service';
import { GroupRepository } from './infra/group.repository';

@Module({
  imports: [PrismaModule],
  controllers: [GroupController],
  providers: [
    GroupService,
    {
      provide: 'GROUP_REPOSITORY',
      useClass: GroupRepository,
    },
  ],
  exports: [GroupService],
})
export class GroupModule {}
