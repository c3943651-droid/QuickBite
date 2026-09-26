import * as React from "react"
import { cn } from "cn"
import { Input } from "@/components/ui/input"
import { formatAmountInput, parseAmount, sanitizeAmount } from "@/lib/currency"

const CURRENCY_SYMBOL = "$"

export interface CurrencyInputProps
  extends Omit<React.ComponentProps<"input">, "value" | "onChange" | "type" | "inputMode"> {
  value: number | string
  onValueChange: (value: number) => void
}

function CurrencyInput({
  value,
  onValueChange,
  className,
  onFocus,
  onBlur,
  ...props
}: CurrencyInputProps) {
  const [text, setText] = React.useState(() => formatAmountInput(Number(value)))
  const isEditingRef = React.useRef(false)

  React.useEffect(() => {
    if (!isEditingRef.current) setText(formatAmountInput(Number(value)))
  }, [value])

  return (
    <div className="relative">
      <span
        aria-hidden="true"
        className="pointer-events-none absolute inset-y-0 left-3 flex items-center text-sm text-muted-foreground"
      >
        {CURRENCY_SYMBOL}
      </span>
      <Input
        type="text"
        inputMode="decimal"
        autoComplete="off"
        className={cn(
          "pl-7 [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none",
          className,
        )}
        value={text}
        {...props}
        onFocus={(event) => {
          isEditingRef.current = true
          event.target.select()
          onFocus?.(event)
        }}
        onBlur={(event) => {
          isEditingRef.current = false
          setText(formatAmountInput(parseAmount(text)))
          onBlur?.(event)
        }}
        onChange={(event) => {
          const sanitized = sanitizeAmount(event.target.value)
          setText(sanitized)
          onValueChange(parseAmount(sanitized))
        }}
      />
    </div>
  )
}

export { CurrencyInput }