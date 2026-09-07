export interface ServerConfiguration {
  readonly publicKey: string
  readonly secretKey: string
  readonly url: string
}

export const supabaseClientOptions = {
  auth: {
    autoRefreshToken: false,
    detectSessionInUrl: false,
    persistSession: false,
  },
}

export function isRecord(value: unknown): value is Readonly<Record<string, unknown>> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

export function stringValue(value: unknown): string | null {
  return typeof value === 'string' && value ? value : null
}

function environmentKeyMap(value: string | undefined): Readonly<Record<string, string>> {
  if (!value) {
    return {}
  }

  try {
    const parsed: unknown = JSON.parse(value)
    if (!isRecord(parsed)) {
      return {}
    }

    const keys: Record<string, string> = {}
    for (const [name, key] of Object.entries(parsed)) {
      if (typeof key === 'string' && key) {
        keys[name] = key
      }
    }

    return keys
  } catch {
    return {}
  }
}

function firstEnvironmentKey(
  mapVariable: string,
  legacyVariable: string,
): string | null {
  const mappedKeys = environmentKeyMap(Deno.env.get(mapVariable))
  for (const key of Object.values(mappedKeys)) {
    return key
  }

  return stringValue(Deno.env.get(legacyVariable))
}

export function readConfiguration(): ServerConfiguration | null {
  const url = stringValue(Deno.env.get('SUPABASE_URL'))
  const secretKey = firstEnvironmentKey(
    'SUPABASE_SECRET_KEYS',
    'SUPABASE_SERVICE_ROLE_KEY',
  )
  const publicKey = firstEnvironmentKey(
    'SUPABASE_PUBLISHABLE_KEYS',
    'SUPABASE_ANON_KEY',
  )

  if (!url || !secretKey || !publicKey) {
    return null
  }

  return { publicKey, secretKey, url }
}
