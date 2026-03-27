import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { AuthService } from './auth.service';
import { PrismaService } from '../../../prisma/prisma.service';
import { UserEntity } from '../user/domain/entity';
import * as bcrypt from 'bcryptjs';

const mockNow = new Date('2026-01-01T00:00:00.000Z');

const makeUser = (overrides: Partial<{
  id: number;
  accountId: string;
  name: string;
  passwordHash: string;
  createdAt: Date;
  updatedAt: Date;
}> = {}): UserEntity =>
  new UserEntity({
    id: 1,
    accountId: 'test-account-id',
    name: 'テストユーザー',
    passwordHash: bcrypt.hashSync('password123', 10),
    createdAt: mockNow,
    updatedAt: mockNow,
    ...overrides,
  });

describe('AuthService', () => {
  let authService: AuthService;
  let prismaService: { users: { findUnique: jest.Mock; create: jest.Mock } };
  let jwtService: { sign: jest.Mock };

  beforeEach(async () => {
    prismaService = {
      users: {
        findUnique: jest.fn(),
        create: jest.fn(),
      },
    };

    jwtService = {
      sign: jest.fn().mockReturnValue('mock.jwt.token'),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: prismaService },
        { provide: JwtService, useValue: jwtService },
      ],
    }).compile();

    authService = module.get<AuthService>(AuthService);
  });

  describe('validateUser', () => {
    it('正しい認証情報のとき UserEntity を返す', async () => {
      const hash = bcrypt.hashSync('password123', 10);
      prismaService.users.findUnique.mockResolvedValue({
        id: 1,
        accountId: 'acc-001',
        name: 'テスト',
        passwordHash: hash,
        createdAt: mockNow,
        updatedAt: mockNow,
      });

      const result = await authService.validateUser('acc-001', 'password123');

      expect(result).toBeInstanceOf(UserEntity);
      expect(result?.accountId).toBe('acc-001');
    });

    it('パスワードが間違っているとき null を返す', async () => {
      const hash = bcrypt.hashSync('correctpassword', 10);
      prismaService.users.findUnique.mockResolvedValue({
        id: 1,
        accountId: 'acc-001',
        name: 'テスト',
        passwordHash: hash,
        createdAt: mockNow,
        updatedAt: mockNow,
      });

      const result = await authService.validateUser('acc-001', 'wrongpassword');

      expect(result).toBeNull();
    });

    it('ユーザーが存在しないとき null を返す', async () => {
      prismaService.users.findUnique.mockResolvedValue(null);

      const result = await authService.validateUser('no-such-user', 'password123');

      expect(result).toBeNull();
    });
  });

  describe('register', () => {
    it('新規ユーザーを登録し accountId と accessToken を返す', async () => {
      prismaService.users.create.mockResolvedValue({
        id: 1,
        accountId: 'generated-uuid',
        name: 'テスト太郎',
        passwordHash: 'hashedpw',
        createdAt: mockNow,
        updatedAt: mockNow,
      });

      const result = await authService.register('テスト太郎', 'password123');

      expect(result).toHaveProperty('accountId');
      expect(result).toHaveProperty('accessToken', 'mock.jwt.token');
      expect(typeof result.accountId).toBe('string');
    });

    it('パスワードは bcrypt でハッシュ化される', async () => {
      const rawPassword = 'password123';
      let capturedPasswordHash = '';

      prismaService.users.create.mockImplementation(
        ({ data }: { data: { passwordHash: string } }) => {
          capturedPasswordHash = data.passwordHash;
          return Promise.resolve({
            id: 1,
            accountId: 'some-uuid',
            name: 'テスト',
            passwordHash: data.passwordHash,
            createdAt: mockNow,
            updatedAt: mockNow,
          });
        },
      );

      await authService.register('テスト', rawPassword);

      expect(capturedPasswordHash).not.toBe(rawPassword);
      expect(bcrypt.compareSync(rawPassword, capturedPasswordHash)).toBe(true);
    });
  });

  describe('login', () => {
    it('ユーザーエンティティから accessToken を返す', () => {
      const user = makeUser();
      const result = authService.login(user);

      expect(result).toHaveProperty('accessToken', 'mock.jwt.token');
      expect(jwtService.sign).toHaveBeenCalledWith({
        sub: user.id,
        accountId: user.accountId,
      });
    });
  });
});
