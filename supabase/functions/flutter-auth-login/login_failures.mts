import type { LoginErrorCode, LoginResponse } from './auth_types.mts'

interface FailureDefinition {
  readonly code: LoginErrorCode
  readonly message: string
  readonly status: number
}

export const invalidRequest: FailureDefinition = {
  code: 'invalid_request',
  message: 'Permintaan login tidak valid.',
  status: 400,
}

export const missingCredentials: FailureDefinition = {
  code: 'missing_credentials',
  message: 'Identifier dan password wajib diisi.',
  status: 400,
}

export const unknownIdentifier: FailureDefinition = {
  code: 'unknown_identifier',
  message: 'Identifier login tidak dikenali.',
  status: 400,
}

export const accountNotFound: FailureDefinition = {
  code: 'account_not_found',
  message: 'Akun tidak ditemukan.',
  status: 404,
}

export const missingProfile: FailureDefinition = {
  code: 'missing_profile',
  message: 'Akun belum memiliki profil. Hubungi Admin.',
  status: 403,
}

export const inactiveAccount: FailureDefinition = {
  code: 'inactive_account',
  message: 'Akun nonaktif. Hubungi Admin.',
  status: 403,
}

export const missingAccountEmail: FailureDefinition = {
  code: 'missing_account_email',
  message: 'Email akun tidak ditemukan. Hubungi Admin.',
  status: 500,
}

export const invalidCredentials: FailureDefinition = {
  code: 'invalid_credentials',
  message:
    'Data login tidak sesuai. Periksa kembali email, username, nomor telepon, dan password Anda.',
  status: 401,
}

export const verificationFailed: FailureDefinition = {
  code: 'verification_failed',
  message: 'Gagal memverifikasi identifier login.',
  status: 500,
}

export function failure(definition: FailureDefinition): LoginResponse {
  return {
    status: definition.status,
    body: {
      success: false,
      error: {
        code: definition.code,
        message: definition.message,
      },
    },
  }
}
