import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from "react"
import type { UserSummary } from "@/lib/api/types"
import { login as loginApi, logout as logoutApi } from "@/lib/api/auth"
import {
  clearSession,
  getAccessToken,
  getRefreshToken,
  getStoredUser,
  patchStoredUser,
  persistsSession,
} from "@/lib/auth/storage"

interface LoginCredentials {
  email: string
  password: string
}

interface AuthContextValue {
  user: UserSummary | null
  accessToken: string | null
  isAuthenticated: boolean
  login: (credentials: LoginCredentials) => Promise<void>
  logout: () => Promise<void>
  patchUser: (patch: Partial<UserSummary>) => void
}

const AuthContext = createContext<AuthContextValue | null>(null)

interface AuthProviderProps {
  children: ReactNode
}

export function AuthProvider({ children }: AuthProviderProps) {
  const [user, setUser] = useState<UserSummary | null>(() => getStoredUser())
  const [accessToken, setAccessToken] = useState<string | null>(() => getAccessToken())

  const login = useCallback(async ({ email, password }: LoginCredentials) => {
    const response = await loginApi({ email, password })
    persistsSession(response)
    setAccessToken(response.accessToken)
    setUser(response.user)
  }, [])

  const logout = useCallback(async () => {
    const refreshToken = getRefreshToken()
    try {
      if (refreshToken) {
        await logoutApi({ refreshToken })
      }
    } finally {
      clearSession()
      setAccessToken(null)
      setUser(null)
    }
  }, [])

  const patchUser = useCallback((patch: Partial<UserSummary>) => {
    setUser((current) => {
      if (!current) return current
      const next = { ...current, ...patch }
      patchStoredUser(next)
      return next
    })
  }, [])

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      accessToken,
      isAuthenticated: Boolean(accessToken && user),
      login,
      logout,
      patchUser,
    }),
    [user, accessToken, login, logout, patchUser],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error("useAuth debe usarse dentro de <AuthProvider>")
  }
  return context
}