import { Injectable } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { v4 as uuidv4 } from 'uuid';
import * as path from 'path';

@Injectable()
export class StorageService {
  private readonly supabase: SupabaseClient;
  private readonly bucket = 'item-images';

  constructor() {
    const url = process.env.SUPABASE_URL!;
    const key = process.env.SUPABASE_SERVICE_KEY!;
    this.supabase = createClient(url, key);
  }

  async upload(buffer: Buffer, originalName: string, mimetype: string): Promise<string> {
    const ext = path.extname(originalName);
    const filename = `items/${uuidv4()}${ext}`;
    const { error } = await this.supabase.storage
      .from(this.bucket)
      .upload(filename, buffer, { contentType: mimetype, upsert: false });
    if (error) throw error;
    const { data } = this.supabase.storage.from(this.bucket).getPublicUrl(filename);
    return data.publicUrl;
  }

  async delete(publicUrl: string): Promise<void> {
    const bucketPrefix = `/storage/v1/object/public/${this.bucket}/`;
    const idx = publicUrl.indexOf(bucketPrefix);
    if (idx === -1) return;
    const filePath = publicUrl.slice(idx + bucketPrefix.length);
    await this.supabase.storage.from(this.bucket).remove([filePath]);
  }
}
