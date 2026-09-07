import { expect, test } from 'bun:test'

const endpoint =
  process.env.AUTH_FUNCTION_URL ??
  'https://ztindtxlbkgykyasgpnd.supabase.co/functions/v1/flutter-auth-login'

test('allows browser preflight before login', async () => {
  // Given a browser preparing to call the login function.
  const requestHeaders =
    'authorization,apikey,content-type,x-client-info'

  // When the browser sends its CORS preflight request.
  const response = await fetch(endpoint, {
    method: 'OPTIONS',
    headers: {
      origin: 'http://127.0.0.1:8765',
      'access-control-request-method': 'POST',
      'access-control-request-headers': requestHeaders,
    },
  })

  // Then the function permits the POST and its required headers.
  expect(response.status).toBe(204)
  expect(response.headers.get('access-control-allow-origin')).toBe('*')
  expect(response.headers.get('access-control-allow-methods')).toContain('POST')
  expect(response.headers.get('access-control-allow-headers')).toContain(
    'authorization',
  )
}, 15_000)
