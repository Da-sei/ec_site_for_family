import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, UnauthorizedException } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { UserEntity } from '../user/domain/entity';

const mockNow = new Date('2026-01-01T00:00:00.000Z');

const makeUser = (): UserEntity =>
  new UserEntity({
    id: 1,
    accountId: 'acc-001',
    name: 'テストユーザー',
    passwordHash: 'hashed',
    createdAt: mockNow,
    updatedAt: mockNow,
  });

describe('AuthController', () => {
  let authController: AuthController;
  let authService: {
    register: jest.Mock;
    login: jest.Mock;
    validateUser: jest.Mock;
  };

  beforeEach(async () => {
    authService = {
      register: jest.fn(),
      login: jest.fn(),
      validateUser: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [{ provide: AuthService, useValue: authService }],
    }).compile();

    authController = module.get<AuthController>(AuthController);
  });

  describe('POST /auth/register', () => {
    it('正常登録で accountId と accessToken を返す', async () => {
      authService.register.mockResolvedValue({
        accountId: 'new-account-id',
        accessToken: 'token123',
      });

      const result = await authController.register({ name: 'テスト', password: 'password123' });

      expect(result).toEqual({ accountId: 'new-account-id', accessToken: 'token123' });
    });

    it('name が空のとき 400 を返す', async () => {
      await expect(
        authController.register({ name: '', password: 'password123' }),
      ).rejects.toThrow(BadRequestException);
    });

    it('password が 7 文字以下のとき 400 を返す', async () => {
      await expect(
        authController.register({ name: 'テスト', password: '1234567' }),
      ).rejects.toThrow(BadRequestException);
    });

    it('password が 8 文字のとき正常に登録される', async () => {
      authService.register.mockResolvedValue({
        accountId: 'new-account-id',
        accessToken: 'token123',
      });

      const result = await authController.register({ name: 'テスト', password: '12345678' });
      expect(result).toHaveProperty('accessToken');
    });
  });

  describe('POST /auth/login', () => {
    it('正しい認証情報で accessToken を返す', async () => {
      authService.validateUser.mockResolvedValue(makeUser());
      authService.login.mockReturnValue({ accessToken: 'login.token' });

      const result = await authController.login({
        accountId: 'acc-001',
        password: 'password123',
      });

      expect(result).toEqual({ accessToken: 'login.token' });
    });

    it('認証情報が間違っているとき 401 を返す', async () => {
      authService.validateUser.mockResolvedValue(null);

      await expect(
        authController.login({ accountId: 'acc-001', password: 'wrong' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('401 エラーメッセージは正しい', async () => {
      authService.validateUser.mockResolvedValue(null);

      await expect(
        authController.login({ accountId: 'acc-001', password: 'wrong' }),
      ).rejects.toThrow('アカウントIDまたはパスワードが正しくありません');
    });
  });
});
