import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';
import * as express from 'express';
import * as path from 'path';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors();
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: false,
      transform: true,
    }),
  );
  // /uploads 以下の静的ファイルを正しく配信
  // app.use('/prefix', express.static(dir)) はExpressがプレフィックスを剥ぎ取ってからファイルを探すため、
  // /uploads/items/abc.jpg → uploads/items/abc.jpg が正しく解決される
  app.use('/uploads', express.static(path.join(process.cwd(), 'uploads')));
  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
