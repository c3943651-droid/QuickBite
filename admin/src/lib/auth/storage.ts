import type { AuthResponse, UserSummary } from "@/lib/api/types"

const ACCESS_TOKEN_KEY = "quickbite.access_token"
const REFRESH_TOKEN_KEY = "quickbite.refresh_token"
const USER_KEY = "quickbite.user"

export interface SessionData {
  accessToken: string | null
  refreshToken: string | null
  user: UserSummary | null
}

export function getAccessToken(): string | null {
  return sessionStorage.getItem(ACCESS_TOKEN_KEY)
}

export function getRefreshToken(): string | null {
  return sessionStorage.getItem(REFRESH_TOKEN_KEY)
}

export function getStoredUser(): UserSummary | null {
  const raw = sessionStorage.getItem(USER_KEY)
  if (!raw) {
    return null
  }
  try {
    return JSON.parse(raw) as UserSummary
  } catch {
    return null
  }
}

export function persistsSession(auth: AuthResponse): void {
  sessionStorage.setItem(ACCESS_TOKEN_KEY, auth.accessToken)
  sessionStorage.setItem(REFRESH_TOKEN_KEY, auth.refreshToken)
  sessionStorage.setItem(USER_KEY, JSON.stringify(auth.user))
}

export function clearSession(): void {
  sessionStorage.removeItem(ACCESS_TOKEN_KEY)
  sessionStorage.removeItem(REFRESH_TOKEN_KEY)
  sessionStorage.removeItem(USER_KEY)
}

export function readFullSession(): SessionData {
  return {
    accessToken: getAccessToken(),
    refreshToken: getRefreshToken(),
    user: getStoredUser(),
  }
}