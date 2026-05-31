import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Setting } from '../database/entities/setting.entity';

export const SETTING_KEYS = {
  BOOKING_HOLD_HOURS: 'booking_hold_hours',
} as const;

@Injectable()
export class SettingsService {
  constructor(
    @InjectRepository(Setting) private readonly repo: Repository<Setting>,
  ) {}

  async get(key: string): Promise<string | null> {
    const setting = await this.repo.findOne({ where: { key } });
    return setting?.value ?? null;
  }

  async getNumber(key: string, fallback: number): Promise<number> {
    const val = await this.get(key);
    if (val === null) return fallback;
    const num = parseFloat(val);
    return isNaN(num) ? fallback : num;
  }

  async set(key: string, value: string, description?: string): Promise<Setting> {
    let setting = await this.repo.findOne({ where: { key } });
    if (setting) {
      setting.value = value;
      if (description) setting.description = description;
    } else {
      setting = this.repo.create({ key, value, description });
    }
    return this.repo.save(setting);
  }

  async findAll(): Promise<Setting[]> {
    return this.repo.find({ order: { key: 'ASC' } });
  }

  async getBookingHoldHours(): Promise<number> {
    return this.getNumber(SETTING_KEYS.BOOKING_HOLD_HOURS, 24);
  }
}
