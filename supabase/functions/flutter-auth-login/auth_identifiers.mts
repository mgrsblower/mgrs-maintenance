const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

export interface EmailIdentifier {
  readonly type: 'email'
  readonly value: string
}

export interface UsernameIdentifier {
  readonly type: 'username'
  readonly value: string
}

export interface PhoneIdentifier {
  readonly type: 'phone'
  readonly value: string
}

export interface UnknownIdentifier {
  readonly type: 'unknown'
  readonly value: string
}

export type AuthIdentifier =
  | EmailIdentifier
  | UsernameIdentifier
  | PhoneIdentifier
  | UnknownIdentifier

export type ProfileIdentifier = UsernameIdentifier | PhoneIdentifier

export function isEmailIdentifier(value: string): boolean {
  return EMAIL_REGEX.test(value.trim())
}

export function normalizeUsername(value: string): string | null {
  const normalized = value.trim().toLowerCase()
  return normalized || null
}

export function normalizePhoneNumber(value: string): string | null {
  const digits = value.replace(/[^\d+]/g, '').replace(/^\+/, '')

  if (!digits) {
    return null
  }

  if (digits.startsWith('62')) {
    return digits
  }

  if (digits.startsWith('0')) {
    return `62${digits.slice(1)}`
  }

  return null
}

export function detectIdentifierType(value: string): AuthIdentifier {
  const trimmed = value.trim()

  if (!trimmed) {
    return { type: 'unknown', value: '' }
  }

  if (isEmailIdentifier(trimmed)) {
    return { type: 'email', value: trimmed.toLowerCase() }
  }

  const phone = normalizePhoneNumber(trimmed)
  if (phone) {
    return { type: 'phone', value: phone }
  }

  const username = normalizeUsername(trimmed)
  if (username) {
    return { type: 'username', value: username }
  }

  return { type: 'unknown', value: trimmed }
}
