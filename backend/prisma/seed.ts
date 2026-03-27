import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  throw new Error('DATABASE_URL is not set');
}
const adapter = new PrismaPg({ connectionString });
const prisma = new PrismaClient({ adapter } as ConstructorParameters<typeof PrismaClient>[0]);

async function main() {
  const categories = ['家電', '家具', '衣類', '書籍', 'その他'];

  for (const name of categories) {
    await prisma.categories.upsert({
      where: { name },
      update: {},
      create: { name },
    });
  }

  console.log('Seed completed: Categories created');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
