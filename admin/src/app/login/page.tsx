import { useState } from "react"
import { useForm } from "react-hook-form"
import { z } from "zod"
import { zodResolver } from "@hookform/resolvers/zod"
import { Navigate, useNavigate } from "react-router-dom"
import { toast } from "sonner"
import { Eye, EyeOff } from "lucide-react"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
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
    <div className="flex min-h-screen items-center justify-center p-4">
      <Card className="w-full max-w-sm">
        <CardHeader className="space-y-1">
          <CardTitle className="text-2xl">QuickBite Admin</CardTitle>
          <CardDescription>Inicia sesión para gestionar el restaurante</CardDescription>
        </CardHeader>
        <CardContent>
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
              <FormField
                control={form.control}
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
              <FormField
                control={form.control}
                name="password"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Contraseña</FormLabel>
                    <FormControl>
                      <div className="relative">
                        <Input
                          type={showPassword ? "text" : "password"}
                          placeholder="••••••••"
                          autoComplete="current-password"
                          className="pr-10"
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
                className="w-full"
                disabled={form.formState.isSubmitting}
              >
                {form.formState.isSubmitting ? "Iniciando sesión…" : "Iniciar sesión"}
              </Button>
            </form>
          </Form>

          <Dialog open={forgotOpen} onOpenChange={setForgotOpen}>
            <DialogTrigger asChild>
              <Button
                type="button"
                variant="link"
                className="mt-3 h-auto p-0 text-xs text-muted-foreground"
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
        </CardContent>
        <CardFooter className="text-muted-foreground text-xs">
          Panel exclusivo para administradores de QuickBite.
        </CardFooter>
      </Card>
    </div>
  )
}