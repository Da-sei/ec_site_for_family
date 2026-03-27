import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy } from 'passport-local';
import { AuthService } from '../auth.service';
import { UserEntity } from '../../user/domain/entity';

@Injectable()
export class LocalStrategy extends PassportStrategy(Strategy) {
  constructor(private authService: AuthService) {
    super({ usernameField: 'accountId' });
  }

  async validate(accountId: string, password: string): Promise<UserEntity> {
    const user = await this.authService.validateUser(accountId, password);
    if (!user) {
      throw new UnauthorizedException('アカウントIDまたはパスワードが正しくありません');
    }
    return user;
  }
}
