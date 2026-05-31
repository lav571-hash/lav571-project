import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TeachingService } from './teaching.service';
import { TeachingController } from './teaching.controller';
import { Attendance } from '../database/entities/attendance.entity';
import { Grade } from '../database/entities/grade.entity';
import { Booking } from '../database/entities/booking.entity';
import { Course } from '../database/entities/course.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Attendance, Grade, Booking, Course])],
  controllers: [TeachingController],
  providers: [TeachingService],
  exports: [TeachingService],
})
export class TeachingModule {}
