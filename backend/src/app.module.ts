import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BullModule } from '@nestjs/bull';
import { ScheduleModule } from '@nestjs/schedule';

import { DatabaseModule } from './database/database.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { CoursesModule } from './courses/courses.module';
import { BookingModule } from './booking/booking.module';
import { TeachingModule } from './teaching/teaching.module';
import { NotificationsModule } from './notifications/notifications.module';
import { SettingsModule } from './settings/settings.module';

import { User } from './database/entities/user.entity';
import { Course } from './database/entities/course.entity';
import { Session } from './database/entities/session.entity';
import { Booking } from './database/entities/booking.entity';
import { Attendance } from './database/entities/attendance.entity';
import { Grade } from './database/entities/grade.entity';
import { Material } from './database/entities/material.entity';
import { Setting } from './database/entities/setting.entity';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),

    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        url: config.get<string>('DATABASE_URL'),
        entities: [User, Course, Session, Booking, Attendance, Grade, Material, Setting],
        synchronize: config.get<string>('NODE_ENV') !== 'production',
        logging: config.get<string>('NODE_ENV') === 'development',
      }),
    }),

    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        redis: config.get<string>('REDIS_URL')
          ? { url: config.get<string>('REDIS_URL') }
          : {
              host: config.get<string>('REDIS_HOST', 'localhost'),
              port: config.get<number>('REDIS_PORT', 6379),
            },
      }),
    }),

    ScheduleModule.forRoot(),

    DatabaseModule,
    AuthModule,
    UsersModule,
    CoursesModule,
    BookingModule,
    TeachingModule,
    NotificationsModule,
    SettingsModule,
  ],
})
export class AppModule {}
