import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SeederService } from './seeder.service';
import { User } from './entities/user.entity';
import { Setting } from './entities/setting.entity';

@Module({
  imports: [TypeOrmModule.forFeature([User, Setting])],
  providers: [SeederService],
})
export class DatabaseModule {}
