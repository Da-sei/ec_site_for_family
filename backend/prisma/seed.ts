import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  throw new Error('DATABASE_URL is not set');
}
const adapter = new PrismaPg({ connectionString });
const prisma = new PrismaClient({ adapter } as ConstructorParameters<typeof PrismaClient>[0]);

async function main() {
  const categories = [
    { id: 1, name: '食品・飲み物' },
    { id: 2, name: '衣類・ファッション' },
    { id: 3, name: '家電・電子機器' },
    { id: 4, name: '本・雑誌' },
    { id: 5, name: 'おもちゃ・ゲーム' },
    { id: 6, name: '家具・インテリア' },
    { id: 7, name: 'スポーツ・アウトドア' },
    { id: 8, name: 'その他' },
  ];

  // 旧カテゴリ（アイテムが紐づいていないもの）を削除してから再作成
  await prisma.categories.deleteMany({
    where: { items: { none: {} } },
  });

  for (const category of categories) {
    await prisma.categories.upsert({
      where: { id: category.id },
      update: { name: category.name },
      create: { id: category.id, name: category.name },
    });
  }

  // autoincrement sequenceを最大IDに合わせてリセット
  await prisma.$executeRaw`SELECT setval(pg_get_serial_sequence('"Categories"', 'id'), 8)`;

  console.log('Seed completed: Categories created (8 categories)');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
