import type {
  ForgotPasswordRequest,
  LoginRequest,
  LogoutRequest,
  RefreshRequest,
} from "./generated/quickBiteAPI.schemas"
import { customInstance } from "./custom-instance"

export interface UserSummary {
  id: string
  nombre: string
  email: string
  rol: string
}

export interface AuthResponse {
  accessToken: string
  refreshToken: string
  expiresIn: number
  user: UserSummary
}

export interface RefreshResponse {
  accessToken: string
  refreshToken: string
  expiresIn: number
}

export const login = (data: LoginRequest) =>
  customInstance<AuthResponse>({
    url: `/api/v1/auth/login`,
    method: "POST",
    headers: { "Content-Type": "application/json" },
    data,
  })

export const logout = (data: LogoutRequest) =>
  customInstance<void>({
    url: `/api/v1/auth/logout`,
    method: "POST",
    headers: { "Content-Type": "application/json" },
    data,
  })

export const refresh = (data: RefreshRequest) =>
  customInstance<RefreshResponse>({
    url: `/api/v1/auth/refresh`,
    method: "POST",
    headers: { "Content-Type": "application/json" },
    data,
  })

export const forgotPassword = (data: ForgotPasswordRequest) =>
  customInstance<void>({
    url: `/api/v1/auth/forgot-password`,
    method: "POST",
    headers: { "Content-Type": "application/json" },
    data,
  })