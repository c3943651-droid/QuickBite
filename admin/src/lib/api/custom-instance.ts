import axios from 'axios'
import type { AxiosError, AxiosRequestConfig, AxiosResponse } from 'axios'
import { toast } from 'sonner'
import { clearSession, getAccessToken } from '@/lib/auth/storage'

export const axiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
})

let sessionExpiredHandled = false

axiosInstance.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    if (error.response?.status === 401 && !sessionExpiredHandled) {
      const isLoginPage = window.location.pathname === '/login'
      if (!isLoginPage) {
        sessionExpiredHandled = true
        clearSession()
        toast.error('La sesión ha expirado', {
          description: 'Inicia sesión nuevamente para continuar.',
        })
        window.location.assign('/login')
      }
    }
    return Promise.reject(error)
  },
)

export const customInstance = <T>(config: AxiosRequestConfig): Promise<T> => {
  const token = getAccessToken()
  const url = config.url?.replace(/^\/api\/v1/, '') ?? config.url
  return axiosInstance({
    ...config,
    url,
    headers: {
      Authorization: token ? `Bearer ${token}` : '',
      ...config.headers,
    },
  }).then((response: AxiosResponse<T>) => response.data)
}

export default customInstance