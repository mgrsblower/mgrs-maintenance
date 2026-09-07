import type {
  AuthUserRecord,
  LoginProfile,
  ProfileLookupResult,
  SafeSession,
  SignedInUser,
  UserRole,
} from './auth_types.mts'
import { isRecord, stringValue } from './server_configuration.mts'

export function authUserFrom(value: unknown): AuthUserRecord | null {
  if (!isRecord(value)) {
    return null
  }

  const id = stringValue(value.id)
  const email = stringValue(value.email)
  if (!id || !email) {
    return null
  }

  return { email, id }
}

export function profileFrom(value: unknown): LoginProfile | null {
  if (!isRecord(value)) {
    return null
  }

  const id = stringValue(value.id)
  const is_active = value.is_active
  const role = userRoleFrom(value.role)
  if (!id || typeof is_active !== 'boolean' || !role) {
    return null
  }

  return { id, is_active, role }
}

function userRoleFrom(value: unknown): UserRole | null {
  switch (value) {
    case 'Admin':
      return value
    case 'PIC Pemasangan':
      return value
    case 'Tim Pemasangan':
      return value
    case 'Tim Service':
      return value
    default:
      return null
  }
}

export function sessionFrom(value: unknown): SafeSession | null {
  if (!isRecord(value)) {
    return null
  }

  const accessToken = stringValue(value.access_token)
  const refreshToken = stringValue(value.refresh_token)
  const tokenType = stringValue(value.token_type)
  const expiresAt = value.expires_at
  const expiresIn = value.expires_in
  if (
    !accessToken ||
    !refreshToken ||
    !tokenType ||
    typeof expiresAt !== 'number' ||
    typeof expiresIn !== 'number'
  ) {
    return null
  }

  return {
    access_token: accessToken,
    expires_at: expiresAt,
    expires_in: expiresIn,
    refresh_token: refreshToken,
    token_type: tokenType,
  }
}

export function signedInUserFrom(value: unknown): SignedInUser | null {
  if (!isRecord(value)) {
    return null
  }

  const id = stringValue(value.id)
  return id ? { id } : null
}

function isUsernameSchemaFailure(value: unknown): boolean {
  if (!isRecord(value)) {
    return false
  }

  const message = stringValue(value.message)
  return message !== null && /column .* does not exist|schema cache/i.test(message)
}

export function profileLookup(
  data: unknown,
  error: unknown,
  allowUsernameFallback: boolean,
): ProfileLookupResult {
  if (error) {
    return allowUsernameFallback && isUsernameSchemaFailure(error)
      ? { kind: 'username_lookup_unavailable' }
      : { kind: 'failure' }
  }

  if (data === null || data === undefined) {
    return { kind: 'missing' }
  }

  const profile = profileFrom(data)
  return profile ? { kind: 'found', profile } : { kind: 'failure' }
}

export function userMatchesUsernameFallback(
  value: unknown,
  username: string,
): AuthUserRecord | null {
  const user = authUserFrom(value)
  if (!user || !isRecord(value)) {
    return null
  }

  const metadata = value.user_metadata
  const metadataUsername = isRecord(metadata)
    ? stringValue(metadata.username)?.toLowerCase()
    : null
  const emailPrefix = user.email.toLowerCase().split('@')[0]
  return metadataUsername === username || emailPrefix === username ? user : null
}
