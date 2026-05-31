import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ScheduleModule } from '@nestjs/schedule';
import { BookingService } from './booking.service';
import { BookingController } from './booking.controller';
import { BookingScheduler } from './booking.scheduler';
import { Booking } from '../database/entities/booking.entity';
import { Course } from '../database/entities/course.entity';
import { SettingsModule } from '../settings/settings.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Booking, Course]),
    SettingsModule,
    NotificationsModule,
  ],
  controllers: [BookingController],
  providers: [BookingService, BookingScheduler],
  exports: [BookingService],
})
export class BookingModule {}
