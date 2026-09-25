import { useState } from "react"
import { useForm } from "react-hook-form"
import { z } from "zod"
import { zodResolver } from "@hookform/resolvers/zod"
import { Navigate, useNavigate } from "react-router-dom"
import { toast } from "sonner"
import { Eye, EyeOff } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Brand } from "@/components/common/brand"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form"
import { Input } from "@/components/ui/input"
import { useAuth } from "@/lib/session/auth-context"
import { forgotPassword } from "@/lib/api/auth"

const loginSchema = z.object({
  email: z.string().email("Ingresa un email válido"),
  password: z.string().min(6, "La contraseña debe tener al menos 6 caracteres"),
})

type LoginValues = z.infer<typeof loginSchema>

const forgotSchema = z.object({
  email: z.string().email("Ingresa un email válido"),
})

type ForgotValues = z.infer<typeof forgotSchema>

export default function LoginPage() {
  const { login, isAuthenticated } = useAuth()
  const navigate = useNavigate()
  const [showPassword, setShowPassword] = useState(false)
  const [forgotOpen, setForgotOpen] = useState(false)

  const form = useForm<LoginValues>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: "", password: "" },
  })

  const forgotForm = useForm<ForgotValues>({
    resolver: zodResolver(forgotSchema),
    defaultValues: { email: "" },
  })

  if (isAuthenticated) {
    return <Navigate to="/dashboard" replace />
  }

  async function onSubmit(values: LoginValues) {
    try {
      await login(values)
      toast.success("Sesión iniciada correctamente")
      navigate("/dashboard", { replace: true })
    } catch {
      toast.error("Credenciales inválidas o cuenta bloqueada", {
        description: "Verifica tus datos e inténtalo de nuevo.",
      })
    }
  }

  async function onForgot(values: ForgotValues) {
    try {
      await forgotPassword({ email: values.email })
    } catch {
      // Respuesta genérica para no revelar si el correo existe.
    }
    toast.success(
      "Si el correo existe, recibirás las instrucciones para recuperar tu contraseña.",
    )
    setForgotOpen(false)
    forgotForm.reset()
  }

  return (
    <div className="grid min-h-screen lg:grid-cols-2">
      <div className="hidden flex-col justify-between bg-zinc-900 p-12 lg:flex">
        <Brand />

        <div className="max-w-md space-y-4">
          <h2 className="text-4xl leading-tight font-semibold tracking-tight text-white">
            Tu restaurante,
            <br />
            gestionado con precisión.
          </h2>
          <p className="text-lg text-zinc-400">
            Panel de administración para pedidos, productos, repartidores y reportes en un
            solo lugar.
          </p>
        </div>

        <p className="text-xs text-zinc-500">
          © {new Date().getFullYear()} QuickBite · Administración del restaurante
        </p>
      </div>

      <div className="flex min-h-screen items-center justify-center bg-white p-6">
        <div className="w-full max-w-sm space-y-8">
          <div className="lg:hidden">
            <Brand compact tone="light" />
          </div>

          <div className="space-y-2 text-center lg:text-left">
            <h1 className="text-2xl font-semibold tracking-tight text-zinc-900">
              Iniciar sesión
            </h1>
            <p className="text-sm text-zinc-500">
              Accede a tu panel de gestión
            </p>
          </div>

          <Form {...form}>
            <form
              onSubmit={form.handleSubmit(onSubmit)}
              className="login-form space-y-4"
            >
              <FormField
                control={form.control}
                name="email"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel className="font-medium text-zinc-700">Email</FormLabel>
                    <FormControl>
                      <Input
                        type="email"
                        placeholder="admin@quickbite.com"
                        autoComplete="email"
                        className="border-zinc-200 bg-zinc-50 focus-visible:border-zinc-900 focus-visible:ring-zinc-900/20"
                        {...field}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="password"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel className="font-medium text-zinc-700">Contraseña</FormLabel>
                    <FormControl>
                      <div className="relative">
                        <Input
                          type={showPassword ? "text" : "password"}
                          placeholder="••••••••"
                          autoComplete="current-password"
                          className="border-zinc-200 bg-zinc-50 pr-10 focus-visible:border-zinc-900 focus-visible:ring-zinc-900/20"
                          {...field}
                        />
                        <button
                          type="button"
                          aria-label={showPassword ? "Ocultar contraseña" : "Mostrar contraseña"}
                          className="text-muted-foreground hover:text-foreground absolute top-1/2 right-3 -translate-y-1/2"
                          onClick={() => setShowPassword((value) => !value)}
                        >
                          {showPassword ? (
                            <EyeOff className="size-4" />
                          ) : (
                            <Eye className="size-4" />
                          )}
                        </button>
                      </div>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <Button
                type="submit"
                className="w-full bg-zinc-900 font-medium text-white transition-all duration-200 shadow-sm hover:bg-zinc-800"
                disabled={form.formState.isSubmitting}
              >
                {form.formState.isSubmitting ? "Iniciando sesión…" : "Iniciar sesión"}
              </Button>
            </form>
          </Form>

          <div className="text-center">
            <Dialog open={forgotOpen} onOpenChange={setForgotOpen}>
              <DialogTrigger asChild>
                <Button
                  type="button"
                  variant="link"
                  className="h-auto p-0 text-xs text-zinc-500"
                >
                  ¿Olvidaste tu contraseña?
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Recuperar contraseña</DialogTitle>
                  <DialogDescription>
                    Escribe tu correo para recibir las instrucciones de recuperación.
                  </DialogDescription>
                </DialogHeader>
                <Form {...forgotForm}>
                  <form
                    id="forgot-password-form"
                    onSubmit={forgotForm.handleSubmit(onForgot)}
                    className="space-y-4"
                  >
                    <FormField
                      control={forgotForm.control}
                      name="email"
                      render={({ field }) => (
                        <FormItem>
                          <FormLabel>Email</FormLabel>
                          <FormControl>
                            <Input
                              type="email"
                              placeholder="admin@quickbite.com"
                              autoComplete="email"
                              {...field}
                            />
                          </FormControl>
                          <FormMessage />
                        </FormItem>
                      )}
                    />
                  </form>
                </Form>
                <DialogFooter>
                  <Button
                    type="submit"
                    form="forgot-password-form"
                    disabled={forgotForm.formState.isSubmitting}
                  >
                    {forgotForm.formState.isSubmitting ? "Enviando…" : "Enviar instrucciones"}
                  </Button>
                </DialogFooter>
              </DialogContent>
            </Dialog>
          </div>

          <p className="text-center text-xs text-zinc-400">
            Panel exclusivo para administradores de QuickBite.
          </p>
        </div>
      </div>
    </div>
  )
}