import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, In, LessThan, Repository } from 'typeorm';
import { Booking, BookingStatus } from '../database/entities/booking.entity';
import { Course } from '../database/entities/course.entity';
import { User, UserRole } from '../database/entities/user.entity';
import { CreateBookingDto } from './dto/create-booking.dto';
import { CancelBookingDto } from './dto/cancel-booking.dto';
import { SettingsService } from '../settings/settings.service';
import { NotificationsService, NotificationEvent } from '../notifications/notifications.service';

@Injectable()
export class BookingService {
  private readonly logger = new Logger(BookingService.name);

  constructor(
    @InjectRepository(Booking) private readonly bookingRepo: Repository<Booking>,
    @InjectRepository(Course) private readonly courseRepo: Repository<Course>,
    private readonly dataSource: DataSource,
    private readonly settingsService: SettingsService,
    private readonly notificationsService: NotificationsService,
  ) {}

  async create(student: User, dto: CreateBookingDto): Promise<Booking> {
    return this.dataSource.transaction(async (manager) => {
      const course = await manager.findOne(Course, {
        where: { id: dto.courseId },
        lock: { mode: 'pessimistic_write' },
      });
      if (!course) throw new NotFoundException('Курс не найден');

      const taken = await manager.count(Booking, {
        where: [
          { courseId: dto.courseId, status: BookingStatus.CONFIRMED },
          { courseId: dto.courseId, status: BookingStatus.PENDING_PAYMENT },
        ],
      });
      if (taken >= course.capacity)
        throw new BadRequestException('На курс нет свободных мест');

      const alreadyBooked = await manager.findOne(Booking, {
        where: {
          studentId: student.id,
          courseId: dto.courseId,
          status: In([BookingStatus.CONFIRMED, BookingStatus.PENDING_PAYMENT]),
        },
      });
      if (alreadyBooked) throw new BadRequestException('Вы уже записаны на этот курс');

      const holdHours = await this.settingsService.getBookingHoldHours();
      const expiresAt = new Date(Date.now() + holdHours * 60 * 60 * 1000);

      const booking = manager.create(Booking, {
        studentId: student.id,
        courseId: dto.courseId,
        status: BookingStatus.PENDING_PAYMENT,
        expiresAt,
      });
      await manager.save(booking);

      await this.notificationsService.send({
        event: NotificationEvent.BOOKING_CREATED,
        userId: student.id,
        email: student.email,
        pushToken: student.pushToken,
        telegramChatId: student.telegramChatId,
        data: { courseTitle: course.title, expiresAt: expiresAt.toISOString() },
      });

      return booking;
    });
  }

  async confirmPayment(bookingId: string, admin: User): Promise<Booking> {
    const booking = await this.findOne(bookingId);
    if (booking.status !== BookingStatus.PENDING_PAYMENT)
      throw new BadRequestException('Подтвердить оплату можно только для брони в статусе «ожидает оплаты»');

    booking.status = BookingStatus.CONFIRMED;
    booking.paymentConfirmedAt = new Date();
    booking.confirmedBy = admin.id;
    const saved = await this.bookingRepo.save(booking);

    const student = booking.student;
    await this.notificationsService.send({
      event: NotificationEvent.PAYMENT_CONFIRMED,
      userId: booking.studentId,
      email: student?.email,
      pushToken: student?.pushToken,
      telegramChatId: student?.telegramChatId,
      data: { courseTitle: booking.course?.title },
    });

    return saved;
  }

  async cancelByStudent(bookingId: string, student: User, dto: CancelBookingDto): Promise<Booking> {
    const booking = await this.findOne(bookingId);
    if (booking.studentId !== student.id)
      throw new ForbiddenException('Это не ваша запись');
    if (booking.status !== BookingStatus.PENDING_PAYMENT)
      throw new BadRequestException('Самостоятельная отмена возможна только до подтверждения оплаты');

    booking.status = BookingStatus.CANCELLED;
    booking.cancelReason = dto.reason ?? null;
    const saved = await this.bookingRepo.save(booking);

    await this.notificationsService.send({
      event: NotificationEvent.BOOKING_CANCELLED,
      userId: student.id,
      email: student.email,
      pushToken: student.pushToken,
      telegramChatId: student.telegramChatId,
      data: { courseTitle: booking.course?.title },
    });

    return saved;
  }

  async cancelByAdmin(bookingId: string, admin: User, dto: CancelBookingDto): Promise<Booking> {
    const booking = await this.findOne(bookingId);
    booking.status = BookingStatus.CANCELLED;
    booking.cancelReason = dto.reason ?? null;
    const saved = await this.bookingRepo.save(booking);

    const student = booking.student;
    if (student) {
      await this.notificationsService.send({
        event: NotificationEvent.BOOKING_CANCELLED,
        userId: booking.studentId,
        email: student.email,
        pushToken: student.pushToken,
        telegramChatId: student.telegramChatId,
        data: { courseTitle: booking.course?.title },
      });
    }

    return saved;
  }

  async findOne(id: string): Promise<Booking> {
    const booking = await this.bookingRepo.findOne({
      where: { id },
      relations: { student: true, course: true },
    });
    if (!booking) throw new NotFoundException('Запись не найдена');
    return booking;
  }

  async findByStudent(studentId: string): Promise<Booking[]> {
    return this.bookingRepo.find({
      where: { studentId },
      relations: { course: { sessions: true } },
      order: { createdAt: 'DESC' },
    });
  }

  async findByCourse(courseId: string): Promise<Booking[]> {
    return this.bookingRepo.find({
      where: { courseId },
      relations: { student: true },
      order: { createdAt: 'DESC' },
    });
  }

  async findAll(): Promise<Booking[]> {
    return this.bookingRepo.find({
      relations: { student: true, course: true },
      order: { createdAt: 'DESC' },
    });
  }

  /** Фоновая задача: истечение просроченных броней */
  async expireOverdueBookings(): Promise<number> {
    const now = new Date();
    const result = await this.bookingRepo
      .createQueryBuilder()
      .update(Booking)
      .set({ status: BookingStatus.EXPIRED })
      .where('status = :status', { status: BookingStatus.PENDING_PAYMENT })
      .andWhere('expires_at < :now', { now })
      .execute();

    const count = result.affected ?? 0;
    if (count > 0) {
      this.logger.log(`Истекло броней: ${count}`);
    }
    return count;
  }
}
