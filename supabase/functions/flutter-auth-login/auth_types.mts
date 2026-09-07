import type { ProfileIdentifier } from './auth_identifiers.mts'

export interface AuthUserRecord {
  readonly id: string
  readonly email: string
}

export interface LoginProfile {
  readonly id: string
  readonly is_active: boolean
  readonly role: UserRole
}

export type UserRole =
  | 'Admin'
  | 'PIC Pemasangan'
  | 'Tim Pemasangan'
  | 'Tim Service'

export interface SafeSession {
  readonly access_token: string
  readonly expires_at: number
  readonly expires_in: number
  readonly refresh_token: string
  readonly token_type: string
}

export interface SignedInUser {
  readonly id: string
}

export interface EmailPasswordCredentials {
  readonly email: string
  readonly password: string
}

export interface Found<T> {
  readonly kind: 'found'
  readonly value: T
}

export interface Missing {
  readonly kind: 'missing'
}

export interface DependencyFailure {
  readonly kind: 'failure'
}

export type LookupResult<T> = Found<T> | Missing | DependencyFailure

export interface ProfileFound {
  readonly kind: 'found'
  readonly profile: LoginProfile
}

export interface UsernameLookupUnavailable {
  readonly kind: 'username_lookup_unavailable'
}

export type ProfileLookupResult =
  | ProfileFound
  | Missing
  | DependencyFailure
  | UsernameLookupUnavailable

export interface AuthenticatedSignIn {
  readonly kind: 'authenticated'
  readonly session: SafeSession
  readonly user: SignedInUser
}

export interface InvalidCredentials {
  readonly kind: 'invalid_credentials'
}

export type SignInResult =
  | AuthenticatedSignIn
  | InvalidCredentials
  | DependencyFailure

export interface AuthLoginDependencies {
  readonly findProfileByIdentifier: (
    identifier: ProfileIdentifier,
  ) => Promise<ProfileLookupResult>
  readonly findProfileByUserId: (
    userId: string,
  ) => Promise<LookupResult<LoginProfile>>
  readonly findUserByEmail: (
    email: string,
  ) => Promise<LookupResult<AuthUserRecord>>
  readonly findUserById: (
    userId: string,
  ) => Promise<LookupResult<AuthUserRecord>>
  readonly findUserByUsernameFallback: (
    username: string,
  ) => Promise<LookupResult<AuthUserRecord>>
  readonly signInWithPassword: (
    credentials: EmailPasswordCredentials,
  ) => Promise<SignInResult>
}

export type LoginErrorCode =
  | 'invalid_request'
  | 'missing_credentials'
  | 'unknown_identifier'
  | 'account_not_found'
  | 'missing_profile'
  | 'inactive_account'
  | 'missing_account_email'
  | 'invalid_credentials'
  | 'verification_failed'

export interface LoginErrorBody {
  readonly success: false
  readonly error: {
    readonly code: LoginErrorCode
    readonly message: string
  }
}

export interface LoginSuccessBody {
  readonly success: true
  readonly session: SafeSession
  readonly user: SignedInUser
  readonly profile: LoginProfile
}

export type LoginResponseBody = LoginErrorBody | LoginSuccessBody

export interface LoginResponse {
  readonly status: number
  readonly body: LoginResponseBody
}
