import { createClient } from 'npm:@supabase/supabase-js@2'

import {
  authenticateFlutterLogin,
  type AuthLoginDependencies,
  type AuthUserRecord,
  type LoginProfile,
  type LoginResponseBody,
  type LookupResult,
  type ProfileIdentifier,
  type ProfileLookupResult,
  type SignInResult,
} from './login_contract.mts'
import {
  readConfiguration,
  supabaseClientOptions,
  type ServerConfiguration,
} from './server_configuration.mts'
import {
  authUserFrom,
  profileLookup,
  sessionFrom,
  signedInUserFrom,
  userMatchesUsernameFallback,
} from './supabase_records.mts'

interface AuthUserList {
  readonly kind: 'available'
  readonly users: readonly unknown[]
}

interface AuthUserListFailure {
  readonly kind: 'failure'
}

type AuthUserListResult = AuthUserList | AuthUserListFailure

const corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers':
    'authorization, x-client-info, apikey, content-type',
  'access-control-allow-methods': 'POST, OPTIONS',
} as const

function createLoginDependencies(
  configuration: ServerConfiguration,
): AuthLoginDependencies {
  const admin = createClient(
    configuration.url,
    configuration.secretKey,
    supabaseClientOptions,
  )
  const anon = createClient(
    configuration.url,
    configuration.publicKey,
    supabaseClientOptions,
  )

  async function listAuthUsers(): Promise<AuthUserListResult> {
    const { data, error } = await admin.auth.admin.listUsers()
    if (error) {
      return { kind: 'failure' }
    }

    const users: unknown = data
    if (
      typeof users !== 'object' ||
      users === null ||
      !('users' in users) ||
      !Array.isArray(users.users)
    ) {
      return { kind: 'failure' }
    }

    return { kind: 'available', users: users.users }
  }

  async function findUserByEmail(email: string): Promise<LookupResult<AuthUserRecord>> {
    const users = await listAuthUsers()
    if (users.kind === 'failure') {
      return users
    }

    for (const candidate of users.users) {
      const user = authUserFrom(candidate)
      if (user && user.email.toLowerCase() === email) {
        return { kind: 'found', value: user }
      }
    }

    return { kind: 'missing' }
  }

  async function findUserByUsernameFallback(
    username: string,
  ): Promise<LookupResult<AuthUserRecord>> {
    const users = await listAuthUsers()
    if (users.kind === 'failure') {
      return users
    }

    for (const candidate of users.users) {
      const user = userMatchesUsernameFallback(candidate, username)
      if (user) {
        return { kind: 'found', value: user }
      }
    }

    return { kind: 'missing' }
  }

  return {
    findProfileByIdentifier: async (
      identifier: ProfileIdentifier,
    ): Promise<ProfileLookupResult> => {
      const column = identifier.type === 'username' ? 'username' : 'phone_number'
      const { data, error } = await admin
        .from('profiles')
        .select('id, is_active, role')
        .eq(column, identifier.value)
        .maybeSingle()
      return profileLookup(data, error, identifier.type === 'username')
    },
    findProfileByUserId: async (userId: string): Promise<LookupResult<LoginProfile>> => {
      const { data, error } = await admin
        .from('profiles')
        .select('id, is_active, role')
        .eq('id', userId)
        .maybeSingle()
      const result = profileLookup(data, error, false)
      if (result.kind === 'found') {
        return { kind: 'found', value: result.profile }
      }

      return result.kind === 'missing' ? result : { kind: 'failure' }
    },
    findUserByEmail,
    findUserById: async (userId: string): Promise<LookupResult<AuthUserRecord>> => {
      const { data, error } = await admin.auth.admin.getUserById(userId)
      if (error) {
        return { kind: 'failure' }
      }

      const user =
        typeof data === 'object' && data !== null && 'user' in data
          ? authUserFrom(data.user)
          : null
      return user ? { kind: 'found', value: user } : { kind: 'missing' }
    },
    findUserByUsernameFallback,
    signInWithPassword: async (credentials): Promise<SignInResult> => {
      const { data, error } = await anon.auth.signInWithPassword({
        email: credentials.email,
        password: credentials.password,
      })
      if (error) {
        return { kind: 'invalid_credentials' }
      }

      const session =
        typeof data === 'object' && data !== null && 'session' in data
          ? sessionFrom(data.session)
          : null
      const user =
        typeof data === 'object' && data !== null && 'user' in data
          ? signedInUserFrom(data.user)
          : null
      return session && user
        ? { kind: 'authenticated', session, user }
        : { kind: 'invalid_credentials' }
    },
  }
}

function jsonResponse(body: LoginResponseBody, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'content-type': 'application/json; charset=utf-8',
    },
  })
}

function unavailableResponse(): Response {
  return jsonResponse(
    {
      success: false,
      error: {
        code: 'verification_failed',
        message: 'Layanan login tidak tersedia.',
      },
    },
    500,
  )
}

async function handleRequest(request: Request): Promise<Response> {
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders })
  }

  if (request.method !== 'POST') {
    return jsonResponse(
      {
        success: false,
        error: {
          code: 'invalid_request',
          message: 'Metode permintaan tidak didukung.',
        },
      },
      405,
    )
  }

  let body: unknown
  try {
    body = await request.json()
  } catch {
    body = null
  }

  const configuration = readConfiguration()
  if (!configuration) {
    return unavailableResponse()
  }

  const response = await authenticateFlutterLogin(
    body,
    createLoginDependencies(configuration),
  )
  return jsonResponse(response.body, response.status)
}

Deno.serve(handleRequest)
