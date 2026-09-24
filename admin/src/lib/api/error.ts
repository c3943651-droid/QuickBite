import axios from "axios"

const EMPTY_MESSAGE = "Ocurrió un error inesperado. Inténtelo de nuevo."

interface ApiErrorBody {
  message?: string
  details?: Record<string, string[]>
  error?: string
  title?: string
}

export function getApiErrorMessage(error: unknown, fallback = EMPTY_MESSAGE): string {
  if (axios.isAxiosError(error)) {
    const body = error.response?.data as ApiErrorBody | undefined
    if (body) {
      if (body.message && body.message.trim().length > 0) return body.message
      if (body.details) {
        const messages = Object.values(body.details).flat().filter(Boolean)
        if (messages.length > 0) return messages.join(" • ")
      }
      if (body.title) return body.title
      if (body.error) return body.error
    }
    if (error.message) return error.message
    if (error.code === "ECONNABORTED") return "La solicitud tardó demasiado."
  }
  return fallback
}