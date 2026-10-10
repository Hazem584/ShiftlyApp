const fs = require('node:fs');

const names = ['SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY', 'SHIFTLY_API_BASE_URL'];
const config = {};
for (const name of names) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`Missing Vercel environment variable: ${name}`);
  config[name] = value;
}

for (const name of ['SUPABASE_URL', 'SHIFTLY_API_BASE_URL']) {
  const url = new URL(config[name]);
  if (url.protocol !== 'https:' || url.username || url.password || url.search || url.hash) {
    throw new Error(`${name} must be a public HTTPS URL without credentials, query or fragment`);
  }
  if (name === 'SHIFTLY_API_BASE_URL' && url.pathname.replace(/\/$/, '') !== '/api/v1') {
    throw new Error('SHIFTLY_API_BASE_URL must end with /api/v1');
  }
}
// These are public client settings; server/service-role keys never belong here.
if (config.SUPABASE_PUBLISHABLE_KEY.startsWith('sb_secret_')) {
  throw new Error('Use the Supabase publishable key, not a server secret');
}
const jwtParts = config.SUPABASE_PUBLISHABLE_KEY.split('.');
if (jwtParts.length === 3) {
  const payload = JSON.parse(Buffer.from(jwtParts[1], 'base64url').toString('utf8'));
  if (payload.role !== 'anon') throw new Error('Only the legacy anon client key is allowed');
}
if (!process.argv[2]) throw new Error('Supply the output JSON path');
fs.writeFileSync(process.argv[2], JSON.stringify(config), { mode: 0o600 });
console.log('Validated public web configuration.');
