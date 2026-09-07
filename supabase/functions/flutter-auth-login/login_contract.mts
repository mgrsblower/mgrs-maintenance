import {
  detectIdentifierType,
  type AuthIdentifier,
  type ProfileIdentifier,
} from './auth_identifiers.mts'
import type {
  AuthLoginDependencies,
  AuthUserRecord,
  LoginProfile,
  LoginResponse,
} from './auth_types.mts'
import {
  accountNotFound,
  failure,
  inactiveAccount,
  invalidCredentials,
  invalidRequest,
  missingAccountEmail,
  missingCredentials,
  missingProfile,
  unknownIdentifier,
  verificationFailed,
} from './login_failures.mts'

export type {
  AuthLoginDependencies,
  AuthUserRecord,
  LoginProfile,
  LoginResponse,
  LoginResponseBody,
  SafeSession,
  SignedInUser,
} from './auth_types.mts'

interface LoginRequest {
  readonly identifier: string
  readonly password: string
}

interface ResolvedLogin {
  readonly profile: LoginProfile
  readonly user: AuthUserRecord
}

function isRecord(value: unknown): value is Readonly<Record<string, unknown>> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

function parseLoginRequest(input: unknown): LoginRequest | LoginResponse {
  if (!isRecord(input)) {
    return failure(invalidRequest)
  }

  const identifier = input.identifier
  const password = input.password
  if (typeof identifier !== 'string' || typeof password !== 'string') {
    return failure(invalidRequest)
  }

  if (!identifier.trim() || !password) {
    return failure(missingCredentials)
  }

  return { identifier, password }
}

function isLoginResponse(value: LoginRequest | LoginResponse): value is LoginResponse {
  return 'status' in value
}

function assertNever(value: never): never {
  throw new Error(`Unhandled identifier type: ${String(value)}`)
}

async function resolveProfileForUser(
  user: AuthUserRecord,
  dependencies: AuthLoginDependencies,
): Promise<ResolvedLogin | LoginResponse> {
  const profileResult = await dependencies.findProfileByUserId(user.id)
  switch (profileResult.kind) {
    case 'found':
      return { profile: profileResult.value, user }
    case 'missing':
      return failure(missingProfile)
    case 'failure':
      return failure(verificationFailed)
    default:
      return assertNever(profileResult)
  }
}

async function resolveUserById(
  profile: LoginProfile,
  dependencies: AuthLoginDependencies,
): Promise<ResolvedLogin | LoginResponse> {
  const userResult = await dependencies.findUserById(profile.id)
  switch (userResult.kind) {
    case 'found':
      return { profile, user: userResult.value }
    case 'missing':
      return failure(missingAccountEmail)
    case 'failure':
      return failure(verificationFailed)
    default:
      return assertNever(userResult)
  }
}

async function resolveProfileIdentifier(
  identifier: ProfileIdentifier,
  dependencies: AuthLoginDependencies,
): Promise<ResolvedLogin | LoginResponse> {
  const profileResult = await dependencies.findProfileByIdentifier(identifier)
  switch (profileResult.kind) {
    case 'found':
      return resolveUserById(profileResult.profile, dependencies)
    case 'missing':
      return failure(accountNotFound)
    case 'failure':
      return failure(verificationFailed)
    case 'username_lookup_unavailable':
      if (identifier.type !== 'username') {
        return failure(verificationFailed)
      }

      return resolveUsernameFallback(identifier.value, dependencies)
    default:
      return assertNever(profileResult)
  }
}

async function resolveUsernameFallback(
  username: string,
  dependencies: AuthLoginDependencies,
): Promise<ResolvedLogin | LoginResponse> {
  const userResult = await dependencies.findUserByUsernameFallback(username)
  switch (userResult.kind) {
    case 'found':
      return resolveProfileForUser(userResult.value, dependencies)
    case 'missing':
      return failure(accountNotFound)
    case 'failure':
      return failure(verificationFailed)
    default:
      return assertNever(userResult)
  }
}

async function resolveLogin(
  identifier: AuthIdentifier,
  dependencies: AuthLoginDependencies,
): Promise<ResolvedLogin | LoginResponse> {
  switch (identifier.type) {
    case 'email': {
      const userResult = await dependencies.findUserByEmail(identifier.value)
      switch (userResult.kind) {
        case 'found':
          return resolveProfileForUser(userResult.value, dependencies)
        case 'missing':
          return failure(accountNotFound)
        case 'failure':
          return failure(verificationFailed)
        default:
          return assertNever(userResult)
      }
    }
    case 'username':
      return resolveProfileIdentifier(identifier, dependencies)
    case 'phone':
      return resolveProfileIdentifier(identifier, dependencies)
    case 'unknown':
      return failure(unknownIdentifier)
    default:
      return assertNever(identifier)
  }
}

function isLoginFailure(value: ResolvedLogin | LoginResponse): value is LoginResponse {
  return 'status' in value
}

export async function authenticateFlutterLogin(
  input: unknown,
  dependencies: AuthLoginDependencies,
): Promise<LoginResponse> {
  const request = parseLoginRequest(input)
  if (isLoginResponse(request)) {
    return request
  }

  try {
    const resolved = await resolveLogin(detectIdentifierType(request.identifier), dependencies)
    if (isLoginFailure(resolved)) {
      return resolved
    }

    if (!resolved.profile.is_active) {
      return failure(inactiveAccount)
    }

    const signInResult = await dependencies.signInWithPassword({
      email: resolved.user.email,
      password: request.password,
    })
    switch (signInResult.kind) {
      case 'authenticated':
        return {
          status: 200,
          body: {
            success: true,
            session: signInResult.session,
            user: signInResult.user,
            profile: resolved.profile,
          },
        }
      case 'invalid_credentials':
        return failure(invalidCredentials)
      case 'failure':
        return failure(verificationFailed)
      default:
        return assertNever(signInResult)
    }
  } catch {
    return failure(verificationFailed)
  }
}
