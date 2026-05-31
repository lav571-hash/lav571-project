import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Attendance } from '../database/entities/attendance.entity';
import { Grade } from '../database/entities/grade.entity';
import { Booking, BookingStatus } from '../database/entities/booking.entity';
import { Course } from '../database/entities/course.entity';
import { User, UserRole } from '../database/entities/user.entity';
import { MarkAttendanceDto } from './dto/mark-attendance.dto';
import { CreateGradeDto } from './dto/create-grade.dto';

@Injectable()
export class TeachingService {
  constructor(
    @InjectRepository(Attendance) private readonly attendanceRepo: Repository<Attendance>,
    @InjectRepository(Grade) private readonly gradeRepo: Repository<Grade>,
    @InjectRepository(Booking) private readonly bookingRepo: Repository<Booking>,
    @InjectRepository(Course) private readonly courseRepo: Repository<Course>,
  ) {}

  async getMyStudents(teacher: User): Promise<any[]> {
    const courses = await this.courseRepo.find({
      where: { teacherId: teacher.id },
      relations: { bookings: { student: true } },
    });

    return courses.map((course) => ({
      course: {
        id: course.id,
        title: course.title,
        status: course.status,
      },
      students: (course.bookings ?? [])
        .filter((b) => b.status === BookingStatus.CONFIRMED)
        .map((b) => ({
          bookingId: b.id,
          student: {
            id: b.student.id,
            fullName: b.student.fullName,
            email: b.student.email,
          },
        })),
    }));
  }

  async getMyCourses(teacher: User): Promise<Course[]> {
    return this.courseRepo.find({
      where: { teacherId: teacher.id },
      relations: { sessions: true },
      order: { createdAt: 'DESC' },
    });
  }

  async markAttendance(teacher: User, dto: MarkAttendanceDto): Promise<Attendance> {
    const booking = await this.bookingRepo.findOne({
      where: { id: dto.bookingId },
      relations: { course: true },
    });
    if (!booking) throw new NotFoundException('Запись не найдена');
    if (booking.course.teacherId !== teacher.id && teacher.role !== UserRole.ADMIN)
      throw new ForbiddenException('Нет доступа к этому курсу');

    let attendance = await this.attendanceRepo.findOne({
      where: { bookingId: dto.bookingId, sessionId: dto.sessionId },
    });

    if (attendance) {
      attendance.present = dto.present;
      attendance.note = dto.note ?? null;
    } else {
      attendance = this.attendanceRepo.create({
        bookingId: dto.bookingId,
        sessionId: dto.sessionId,
        present: dto.present,
        note: dto.note ?? null,
      });
    }
    return this.attendanceRepo.save(attendance);
  }

  async getAttendanceByBooking(bookingId: string): Promise<Attendance[]> {
    return this.attendanceRepo.find({
      where: { bookingId },
      relations: { session: true },
      order: { session: { startsAt: 'ASC' } },
    });
  }

  async getAttendanceBySession(sessionId: string): Promise<Attendance[]> {
    return this.attendanceRepo.find({
      where: { sessionId },
      relations: { booking: { student: true } },
    });
  }

  async createGrade(teacher: User, dto: CreateGradeDto): Promise<Grade> {
    const booking = await this.bookingRepo.findOne({
      where: { id: dto.bookingId },
      relations: { course: true },
    });
    if (!booking) throw new NotFoundException('Запись не найдена');
    if (booking.course.teacherId !== teacher.id && teacher.role !== UserRole.ADMIN)
      throw new ForbiddenException('Нет доступа к этому курсу');

    let grade = await this.gradeRepo.findOne({ where: { bookingId: dto.bookingId } });
    if (grade) {
      grade.score = dto.score;
      grade.comment = dto.comment ?? null;
    } else {
      grade = this.gradeRepo.create({
        bookingId: dto.bookingId,
        score: dto.score,
        comment: dto.comment ?? null,
        gradedBy: teacher.id,
      });
    }
    return this.gradeRepo.save(grade);
  }

  async getGradesByBooking(bookingId: string): Promise<Grade | null> {
    return this.gradeRepo.findOne({ where: { bookingId } });
  }
}
