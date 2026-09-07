import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { initdb, pg_ctl } from '@embedded-postgres/windows-x64';
import pg from 'pg';
import { assertMaintenance } from './assert-maintenance.mjs';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const dataDir = path.join(root, '.local', 'postgres-baseline');
const logFile = path.join(root, '.local', 'postgres-baseline.log');
const port = 55437;
const database = `maintenance_baseline_${Date.now()}`;
const connection = { host: '127.0.0.1', port, user: 'postgres' };
const baselinePath = path.join(root, 'supabase/migrations/20260906000100_maintenance_baseline.sql');
const seedPath = path.join(root, 'supabase/seed.sql');
assert.ok(fs.existsSync(baselinePath), 'Baseline migration must exist before running verification');
assert.ok(fs.existsSync(seedPath), 'Synthetic seed must exist before running verification');

function binary(executable, args) {
  const result = spawnSync(executable, args, { windowsHide: true, encoding: 'utf8', stdio: 'ignore', timeout: 30000 });
  if (result.error || result.status !== 0) {
    throw new Error(`${path.basename(executable)} failed: ${result.error?.message ?? result.stderr ?? result.stdout}`);
  }
  return result.stdout?.trim() ?? '';
}

fs.mkdirSync(path.dirname(dataDir), { recursive: true });
if (!fs.existsSync(path.join(dataDir, 'PG_VERSION'))) {
  binary(initdb, ['-D', dataDir, '-U', 'postgres', '--encoding=UTF8', '--locale=C', '--auth=trust']);
}
let started = false;
let admin;
let client;
try {
  binary(pg_ctl, ['-D', dataDir, '-l', logFile, '-o', `-h 127.0.0.1 -p ${port}`, '-w', 'start']);
  started = true;
  admin = new pg.Client({ ...connection, database: 'postgres' });
  await admin.connect();
  await admin.query(`CREATE DATABASE "${database}"`);
  client = new pg.Client({ ...connection, database });
  await client.connect();
  // Minimal Supabase authentication shim, used only by this disposable local database.
  await client.query(`
    DO $$ BEGIN CREATE ROLE anon NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
    DO $$ BEGIN CREATE ROLE authenticated NOLOGIN; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
    DO $$ BEGIN CREATE ROLE service_role NOLOGIN BYPASSRLS; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
    CREATE SCHEMA auth;
    CREATE TABLE auth.users (
      id uuid PRIMARY KEY, email text, instance_id uuid, aud text, role text,
      encrypted_password text, email_confirmed_at timestamptz,
      raw_app_meta_data jsonb, raw_user_meta_data jsonb,
      created_at timestamptz, updated_at timestamptz
    );
    CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS $$
      SELECT COALESCE(NULLIF(current_setting('request.jwt.claim.sub', true), ''),
        NULLIF(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')::uuid
    $$;
    GRANT USAGE ON SCHEMA auth TO anon, authenticated, service_role;
    GRANT EXECUTE ON FUNCTION auth.uid() TO anon, authenticated, service_role;
  `);
  await client.query(fs.readFileSync(baselinePath, 'utf8'));
  await client.query(fs.readFileSync(seedPath, 'utf8'));
  const tables = ['profiles', 'master_komponen', 'riwayat_checking_komponen', 'riwayat_service', 'audit_log'];
  const result = await client.query(`SELECT relname, relrowsecurity FROM pg_class WHERE relnamespace='public'::regnamespace AND relname=ANY($1::text[])`, [tables]);
  assert.equal(result.rows.length, tables.length);
  assert.ok(result.rows.every(row => row.relrowsecurity), 'All baseline tables require RLS');
  const cost = await client.query(`SELECT is_nullable, column_default FROM information_schema.columns WHERE table_schema='public' AND table_name='riwayat_service' AND column_name='biaya_service'`);
  assert.equal(cost.rows[0].is_nullable, 'NO');
  assert.equal(cost.rows[0].column_default, '0');
  const kinds = await client.query('SELECT DISTINCT jenis_komponen FROM public.master_komponen ORDER BY jenis_komponen');
  assert.deepEqual(kinds.rows.map(row => row.jenis_komponen), ['Batang', 'Kepala', 'Tabung']);
  const roleHelper = await client.query(`SELECT private.current_user_has_role(ARRAY['Admin']) AS allowed`);
  assert.equal(roleHelper.rows[0].allowed, false, 'No identity must fail role helper');
  if (process.argv.includes('--maintenance')) {
    await client.query(fs.readFileSync(path.join(root, 'supabase/migrations/20260907000100_maintenance_api.sql'), 'utf8'));
    await client.query(fs.readFileSync(path.join(root, 'supabase/migrations/20260907000200_maintenance_history.sql'), 'utf8'));
    await assertMaintenance(client);
  }
  const version = await client.query('SHOW server_version');
  console.log(JSON.stringify({ status: 'PASS', scope: 'local baseline smoke, not Supabase Auth/API or pgTAP', serverVersion: version.rows[0].server_version, tables: tables.length, assertions: 7 }, null, 2));
} finally {
  if (client) await client.end();
  if (admin) {
    if (/^maintenance_baseline_\d+$/.test(database)) await admin.query(`DROP DATABASE IF EXISTS "${database}"`);
    await admin.end();
  }
  if (started) binary(pg_ctl, ['-D', dataDir, '-m', 'fast', '-w', 'stop']);
}
