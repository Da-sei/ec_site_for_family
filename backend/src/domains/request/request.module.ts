import { Module } from '@nestjs/common';
import { PrismaModule } from '../../../prisma/prisma.module';
import { RequestController } from './controller/request.controller';
import { RequestService } from './service/request.service';
import { RequestRepository } from './infra/request.repository';

@Module({
  imports: [PrismaModule],
  controllers: [RequestController],
  providers: [
    RequestService,
    {
      provide: 'REQUEST_REPOSITORY',
      useClass: RequestRepository,
    },
  ],
  exports: [RequestService],
})
export class RequestModule {}
