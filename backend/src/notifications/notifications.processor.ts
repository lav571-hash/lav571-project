import { Process, Processor } from '@nestjs/bull';
import { Logger } from '@nestjs/common';
import type { Job } from 'bull';
import { NotificationPayload, NotificationEvent } from './notifications.service';

@Processor('notifications')
export class NotificationsProcessor {
  private readonly logger = new Logger(NotificationsProcessor.name);

  @Process('send')
  async handleSend(job: Job<NotificationPayload>) {
    const { event, userId, email, pushToken, telegramChatId, data } = job.data;
    this.logger.log(`Processing notification [${event}] for user ${userId}`);

    const message = this.buildMessage(event, data);

    if (email) {
      await this.sendEmail(email, message);
    }
    if (pushToken) {
      await this.sendPush(pushToken, message);
    }
    if (telegramChatId) {
      await this.sendTelegram(telegramChatId, message);
    }
  }

  private buildMessage(event: NotificationEvent, data: Record<string, any>) {
    const templates: Record<NotificationEvent, (d: any) => { subject: string; body: string }> = {
      [NotificationEvent.BOOKING_CREATED]: (d) => ({
        subject: 'Запись подтверждена',
        body: `Вы записались на курс «${d.courseTitle}». Ожидайте подтверждения оплаты.`,
      }),
      [NotificationEvent.PAYMENT_CONFIRMED]: (d) => ({
        subject: 'Оплата подтверждена',
        body: `Ваша оплата по курсу «${d.courseTitle}» подтверждена. Место закреплено за вами.`,
      }),
      [NotificationEvent.BOOKING_CANCELLED]: (d) => ({
        subject: 'Запись отменена',
        body: `Ваша запись на курс «${d.courseTitle}» отменена.`,
      }),
      [NotificationEvent.BOOKING_EXPIRED]: (d) => ({
        subject: 'Бронь истекла',
        body: `Ваша бронь на курс «${d.courseTitle}» снята, так как оплата не поступила вовремя.`,
      }),
      [NotificationEvent.PAYMENT_REMINDER]: (d) => ({
        subject: 'Напоминание об оплате',
        body: `Не забудьте оплатить запись на курс «${d.courseTitle}». Бронь действует до ${d.expiresAt}.`,
      }),
      [NotificationEvent.SESSION_REMINDER]: (d) => ({
        subject: 'Напоминание о занятии',
        body: `Напоминаем: занятие по курсу «${d.courseTitle}» начнётся ${d.startsAt}.`,
      }),
    };

    return templates[event]?.(data) ?? { subject: 'Уведомление', body: JSON.stringify(data) };
  }

  private async sendEmail(email: string, msg: { subject: string; body: string }) {
    this.logger.log(`[EMAIL] → ${email}: ${msg.subject}`);
    // TODO: реальная отправка через nodemailer / транзакционный провайдер
  }

  private async sendPush(token: string, msg: { subject: string; body: string }) {
    this.logger.log(`[PUSH] → ${token}: ${msg.subject}`);
    // TODO: реальная отправка через Firebase Cloud Messaging
  }

  private async sendTelegram(chatId: string, msg: { subject: string; body: string }) {
    this.logger.log(`[TELEGRAM] → ${chatId}: ${msg.body}`);
    // TODO: реальная отправка через Telegram Bot API
  }
}
