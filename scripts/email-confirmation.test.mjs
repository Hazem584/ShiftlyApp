import assert from 'node:assert/strict';
import test from 'node:test';
import { confirmationOutcome } from '../web/email-confirmation.mjs';

const outcome = (suffix) => confirmationOutcome(new URL(`https://shiftly.example/email-confirmed.html${suffix}`));
test('PKCE confirmation and implicit signup callbacks show success', () => {
  assert.equal(outcome('?code=confirmation-code'), 'confirmed');
  assert.equal(outcome('#type=signup&access_token=example-token'), 'confirmed');
});
test('expired links take precedence over callback credentials', () => {
  assert.equal(outcome('?code=example&error=access_denied'), 'invalid');
  assert.equal(outcome('#error_code=otp_expired'), 'invalid');
});
test('ordinary visits and unrelated recovery callbacks do not claim success', () => {
  assert.equal(outcome(''), 'missing');
  assert.equal(outcome('#type=recovery&access_token=example-token'), 'missing');
});

test('landing page shows the English success message and removes callback credentials', async () => {
  const elements = new Map(['status-icon', 'status-title', 'status-message'].map((id) => [id, { textContent: '' }]));
  let replacement;
  globalThis.document = { getElementById: (id) => elements.get(id) };
  globalThis.window = {
    location: { href: 'https://shiftly.example/email-confirmed.html?code=example-code', pathname: '/email-confirmed.html' },
    history: { replaceState: (_state, _title, path) => { replacement = path; } },
  };
  try {
    await import('../web/email-confirmation.mjs?dom-test');
    assert.equal(elements.get('status-title').textContent, 'Email verified successfully');
    assert.match(elements.get('status-message').textContent, /Return to Shiftly and sign in/);
    assert.equal(replacement, '/email-confirmed.html');
  } finally {
    delete globalThis.document;
    delete globalThis.window;
  }
});
