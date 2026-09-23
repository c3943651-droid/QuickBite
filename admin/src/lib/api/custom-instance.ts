import axios from 'axios'
import type { AxiosRequestConfig, AxiosResponse } from 'axios'

export const axiosInstance = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
})

export const customInstance = <T>(config: AxiosRequestConfig): Promise<T> => {
  const token = sessionStorage.getItem('auth-token')
  return axiosInstance({
    ...config,
    headers: {
      Authorization: token ? `Bearer ${token}` : '',
      ...config.headers,
    },
  }).then((response: AxiosResponse<T>) => response.data)
}

export default customInstance