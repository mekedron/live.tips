/// Single-instance directory of jars for the admin view, plus the per-IP
/// jar-creation quota. Holds metadata and counters only — tip content and
/// donor identities never reach this object.

import { DurableObject } from "cloudflare:workers";
import type { Env, RegistryRow } from "./types";

const CREATES_PER_HOUR = 20;

export class RegistryDO extends DurableObject<Env> {
  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);
    void this.ctx.blockConcurrencyWhile(async () => {
      this.ctx.storage.sql.exec(`
        CREATE TABLE IF NOT EXISTS jars (
          jarId TEXT PRIMARY KEY,
          artistName TEXT NOT NULL,
          methods TEXT NOT NULL,
          createdAt INTEGER NOT NULL,
          lastSeenDay INTEGER NOT NULL,
          tipsDay INTEGER NOT NULL DEFAULT 0,
          tipsToday INTEGER NOT NULL DEFAULT 0,
          tipsTotal INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS creations (
          ipHash TEXT NOT NULL,
          hourBucket INTEGER NOT NULL,
          count INTEGER NOT NULL,
          PRIMARY KEY (ipHash, hourBucket)
        );
      `);
    });
  }

  async upsert(row: {
    jarId: string;
    artistName: string;
    methods: string;
    createdAt: number;
    lastSeenDay: number;
  }): Promise<void> {
    this.ctx.storage.sql.exec(
      `INSERT INTO jars (jarId, artistName, methods, createdAt, lastSeenDay)
       VALUES (?, ?, ?, ?, ?)
       ON CONFLICT(jarId) DO UPDATE SET
         artistName = excluded.artistName,
         methods = excluded.methods,
         lastSeenDay = excluded.lastSeenDay`,
      row.jarId, row.artistName, row.methods, row.createdAt, row.lastSeenDay,
    );
  }

  async remove(jarId: string): Promise<void> {
    this.ctx.storage.sql.exec(`DELETE FROM jars WHERE jarId = ?`, jarId);
  }

  /**
   * Existence gate for all `/t/*` and `/v1/jars/:id/*` routes. Checking here
   * keeps random-id probes from lazily instantiating a JarDO per guess —
   * unknown ids cost one registry lookup and nothing else.
   */
  async has(jarId: string): Promise<boolean> {
    return this.ctx.storage.sql
      .exec(`SELECT 1 FROM jars WHERE jarId = ?`, jarId)
      .toArray().length > 0;
  }

  async touch(jarId: string, day: number): Promise<void> {
    this.ctx.storage.sql.exec(`UPDATE jars SET lastSeenDay = ? WHERE jarId = ?`, day, jarId);
  }

  async bumpTips(jarId: string, day: number): Promise<void> {
    this.ctx.storage.sql.exec(
      `UPDATE jars SET
         tipsToday = CASE WHEN tipsDay = ? THEN tipsToday + 1 ELSE 1 END,
         tipsDay = ?,
         tipsTotal = tipsTotal + 1
       WHERE jarId = ?`,
      day, day, jarId,
    );
  }

  async list(): Promise<RegistryRow[]> {
    const cursor = this.ctx.storage.sql.exec(
      `SELECT jarId, artistName, methods, createdAt, lastSeenDay, tipsDay, tipsToday, tipsTotal
       FROM jars ORDER BY lastSeenDay DESC, createdAt DESC`,
    );
    const today = Math.floor(Date.now() / 86_400_000);
    return cursor.toArray().map((r) => ({
      jarId: r["jarId"] as string,
      artistName: r["artistName"] as string,
      methods: r["methods"] as string,
      createdAt: r["createdAt"] as number,
      lastSeenDay: r["lastSeenDay"] as number,
      tipsToday: (r["tipsDay"] as number) === today ? (r["tipsToday"] as number) : 0,
      tipsTotal: r["tipsTotal"] as number,
    }));
  }

  /**
   * Jar-creation quota: max 20/hour per IP hash. Old buckets are pruned
   * lazily; only salted-hashed IPs are stored, and only for ~2 hours.
   */
  async checkCreateAllowed(ipHash: string): Promise<boolean> {
    const bucket = Math.floor(Date.now() / 3_600_000);
    this.ctx.storage.sql.exec(`DELETE FROM creations WHERE hourBucket < ?`, bucket - 1);
    const rows = this.ctx.storage.sql
      .exec(`SELECT count FROM creations WHERE ipHash = ? AND hourBucket = ?`, ipHash, bucket)
      .toArray();
    const count = rows.length > 0 ? (rows[0]!["count"] as number) : 0;
    if (count >= CREATES_PER_HOUR) return false;
    this.ctx.storage.sql.exec(
      `INSERT INTO creations (ipHash, hourBucket, count) VALUES (?, ?, 1)
       ON CONFLICT(ipHash, hourBucket) DO UPDATE SET count = count + 1`,
      ipHash, bucket,
    );
    return true;
  }
}
