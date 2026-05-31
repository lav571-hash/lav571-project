import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { BookingService } from './booking.service';

@Injectable()
export class BookingScheduler {
  private readonly logger = new Logger(BookingScheduler.name);

  constructor(private readonly bookingService: BookingService) {}

  @Cron(CronExpression.EVERY_5_MINUTES)
  async expireBookings() {
    const expired = await this.bookingService.expireOverdueBookings();
    if (expired > 0) {
      this.logger.log(`[Scheduler] Автоснятие брони: ${expired} записей`);
    }
  }
}
