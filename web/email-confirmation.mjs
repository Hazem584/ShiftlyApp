// Supabase verifies the link before redirecting here. A PKCE code is not
// exchanged: this page never starts the app or signs the user in automatically.
export function confirmationOutcome(url) {
  const query = url.searchParams;
  const fragment = new URLSearchParams(url.hash.slice(1));
  if (query.has('error') || query.has('error_code') || fragment.has('error') || fragment.has('error_code')) return 'invalid';
  if (query.get('code') || (fragment.get('type') === 'signup' && fragment.get('access_token'))) return 'confirmed';
  return 'missing';
}

if (typeof document !== 'undefined') {
  const outcome = confirmationOutcome(new URL(window.location.href));
  // Remove authorization codes/tokens before the user follows another link.
  window.history.replaceState(null, '', window.location.pathname);
  if (outcome === 'confirmed') {
    document.getElementById('status-icon').textContent = '✓';
    document.getElementById('status-title').textContent = 'Email verified successfully';
    document.getElementById('status-message').textContent = 'You’re all set! Return to Shiftly and sign in to your account.';
  } else if (outcome === 'invalid') {
    document.getElementById('status-title').textContent = 'This verification link is no longer valid';
    document.getElementById('status-message').textContent = 'The link may have expired or already been used. Return to Shiftly to request a new confirmation email, or sign in if you already verified your email.';
  }
}
