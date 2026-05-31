import { Injectable, Logger } from '@nestjs/common';
import { InjectQueue } from '@nestjs/bull';
import type { Queue } from 'bull';

export enum NotificationEvent {
  BOOKING_CREATED = 'booking_created',
  PAYMENT_CONFIRMED = 'payment_confirmed',
  BOOKING_CANCELLED = 'booking_cancelled',
  BOOKING_EXPIRED = 'booking_expired',
  PAYMENT_REMINDER = 'payment_reminder',
  SESSION_REMINDER = 'session_reminder',
}

export interface NotificationPayload {
  event: NotificationEvent;
  userId: string;
  email?: string;
  pushToken?: string;
  telegramChatId?: string;
  data: Record<string, any>;
}

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    @InjectQueue('notifications') private readonly notifyQueue: Queue,
  ) {}

  async send(payload: NotificationPayload): Promise<void> {
    await this.notifyQueue.add('send', payload, {
      attempts: 3,
      backoff: { type: 'exponential', delay: 5000 },
    });
  }

  async scheduleReminder(
    payload: NotificationPayload,
    delayMs: number,
  ): Promise<void> {
    await this.notifyQueue.add('send', payload, {
      delay: delayMs,
      attempts: 3,
      backoff: { type: 'exponential', delay: 5000 },
    });
  }
}
