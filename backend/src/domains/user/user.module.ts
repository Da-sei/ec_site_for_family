import { Module } from '@nestjs/common';
import { PrismaModule } from '../../../prisma/prisma.module';
import { UserController } from './controller/user.controller';
import { UserService } from './service/user.service';
import { UserCommandRepository } from './infra/user.command.repository';
import { UserQueryRepository } from './infra/user.query.repository';

@Module({
  imports: [PrismaModule],
  controllers: [UserController],
  providers: [
    UserService,
    {
      provide: 'USER_COMMAND_REPOSITORY',
      useClass: UserCommandRepository,
    },
    {
      provide: 'USER_QUERY_REPOSITORY',
      useClass: UserQueryRepository,
    },
  ],
})
export class UserModule {}
