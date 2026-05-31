import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CoursesService } from './courses.service';
import { CoursesController } from './courses.controller';
import { Course } from '../database/entities/course.entity';
import { Session } from '../database/entities/session.entity';
import { Material } from '../database/entities/material.entity';
import { Booking } from '../database/entities/booking.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Course, Session, Material, Booking])],
  controllers: [CoursesController],
  providers: [CoursesService],
  exports: [CoursesService],
})
export class CoursesModule {}
