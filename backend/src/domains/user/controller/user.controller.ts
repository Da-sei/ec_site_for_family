import { Controller, Get, NotFoundException } from '@nestjs/common';
import { UserService } from '../service/user.service';
import { CurrentUser } from '../../auth/decorators/current-user.decorator';
import type { JwtPayload } from '../../auth/decorators/current-user.decorator';

@Controller('users')
export class UserController {
  constructor(private readonly userService: UserService) {}

  // ユーザ情報の取得
  @Get('me')
  async getMe(@CurrentUser() user: JwtPayload): Promise<{ id: number; accountId: string; name: string }> {
    const profile = await this.userService.getProfile(user.sub);
    if (!profile) throw new NotFoundException('ユーザーが見つかりません');
    return { id: profile.id, accountId: profile.accountId, name: profile.name };
  }
}
