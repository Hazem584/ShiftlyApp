// Disposable, in-memory PostgreSQL smoke test. Does not load application secrets.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const backend = path.resolve(__dirname, '../../shiftly-backend');
const { PGlite } = require(require.resolve('@electric-sql/pglite', { paths: [backend] }));

(async () => {
  const db = new PGlite();
  try {
    await db.exec(`
      CREATE ROLE anon;
      CREATE ROLE authenticated;
      CREATE TYPE "NotificationType" AS ENUM ('ANNOUNCEMENT');
      CREATE TABLE profiles(id uuid PRIMARY KEY);
      CREATE TABLE workspaces(id uuid PRIMARY KEY);
    `);
    await db.exec(fs.readFileSync(path.join(backend,
      'prisma/migrations/20261024090000_personal_tasks/migration.sql'), 'utf8'));
    const owner = '00000000-0000-4000-8000-000000000001';
    const workspace = '00000000-0000-4000-8000-000000000002';
    const task = '00000000-0000-4000-8000-000000000003';
    const installation = '00000000-0000-4000-8000-000000000004';
    await db.query('INSERT INTO profiles VALUES ($1)', [owner]);
    await db.query('INSERT INTO workspaces VALUES ($1)', [workspace]);
    await db.query(`INSERT INTO personal_tasks
      (id,owner_id,workspace_id,title,due_at,updated_at)
      VALUES ($1,$2,$3,'Report','2090-01-01T12:00:00+02:00',now())`, [task,owner,workspace]);
    const saved = (await db.query('SELECT * FROM personal_tasks')).rows[0];
    assert.equal(saved.due_at.toISOString(), '2090-01-01T10:00:00.000Z');
    assert.equal(saved.status, 'OPEN');
    assert.equal(saved.revision, 1);
    await assert.rejects(db.query('UPDATE personal_tasks SET title=$1', ['   ']));
    await assert.rejects(db.query('UPDATE personal_tasks SET revision=0'));
    await db.query('INSERT INTO task_reminder_registrations VALUES ($1,$2,1)', [task,installation]);
    await assert.rejects(db.query('INSERT INTO task_reminder_registrations VALUES ($1,$2,1)', [task,installation]));
    const security = (await db.query(`SELECT relname,relrowsecurity FROM pg_class
      WHERE relname IN ('personal_tasks','task_reminder_registrations')`)).rows;
    assert.equal(security.length, 2);
    assert.ok(security.every((table) => table.relrowsecurity));
    const grants = (await db.query(`SELECT has_table_privilege('authenticated',
      'personal_tasks','SELECT') AS allowed`)).rows[0];
    assert.equal(grants.allowed, false);
    await db.query('DELETE FROM workspaces WHERE id=$1', [workspace]);
    assert.equal((await db.query('SELECT * FROM personal_tasks')).rows.length, 0);
    assert.equal((await db.query('SELECT * FROM task_reminder_registrations')).rows.length, 0);
    console.log('Task migration passed: UTC deadlines, defaults, constraints, RLS, grants and cascading deletion.');
  } finally {
    await db.close();
  }
})().catch((error) => { console.error(error); process.exitCode = 1; });
