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