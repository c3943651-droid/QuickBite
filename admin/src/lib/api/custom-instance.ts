import axios from 'axios'
import type { AxiosRequestConfig, AxiosResponse } from 'axios'
import { getAccessToken } from '@/lib/auth/storage'

export const axiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
})

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