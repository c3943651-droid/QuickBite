import {
  Beef,
  Cake,
  Coffee,
  Cookie,
  Croissant,
  CupSoda,
  IceCream,
  Pizza,
  Salad,
  Sandwich,
  Utensils,
  type LucideIcon,
} from "lucide-react"

export interface IconOption {
  name: string
  label: string
  icon: LucideIcon
}

export const CATEGORY_EMOJIS: Array<{ value: string; label: string }> = [
  { value: "🍩", label: "Donas" },
  { value: "🍔", label: "Hamburguesas" },
  { value: "🍕", label: "Pizzas" },
  { value: "🥐", label: "Panadería" },
  { value: "🥤", label: "Bebidas" },
  { value: "🍦", label: "Postres" },
  { value: "🌮", label: "Tacos" },
  { value: "☕", label: "Café" },
  { value: "🍟", label: "Botanas" },
  { value: "🍗", label: "Pollo" },
]

export const CATEGORY_LUCIDE_ICONS: IconOption[] = [
  { name: "Utensils", label: "Cubiertos", icon: Utensils },
  { name: "Croissant", label: "Croissant", icon: Croissant },
  { name: "Sandwich", label: "Sándwich", icon: Sandwich },
  { name: "CupSoda", label: "Refresco", icon: CupSoda },
  { name: "IceCream", label: "Helado", icon: IceCream },
  { name: "Cookie", label: "Galleta", icon: Cookie },
  { name: "Pizza", label: "Pizza", icon: Pizza },
  { name: "Coffee", label: "Café", icon: Coffee },
  { name: "Cake", label: "Pastel", icon: Cake },
  { name: "Beef", label: "Carne", icon: Beef },
]

const LUCIDE_BY_NAME: Record<string, LucideIcon> = {
  Utensils,
  Croissant,
  Sandwich,
  CupSoda,
  IceCream,
  Cookie,
  Pizza,
  Coffee,
  Cake,
  Beef,
}

const NAME_KEYWORD_MAP: Array<{ keywords: string[]; icon: LucideIcon }> = [
  { keywords: ["bebida", "jugo", "refresco", "soda", "agua", "malteada", "batido"], icon: CupSoda },
  { keywords: ["cafe", "coffee", "espresso"], icon: Coffee },
  { keywords: ["hamburguesa", "burger"], icon: Sandwich },
  { keywords: ["pizza"], icon: Pizza },
  { keywords: ["postre", "dulce", "helado", "nieve"], icon: IceCream },
  { keywords: ["panader", "pan", "croissant", "bolleria"], icon: Croissant },
  { keywords: ["galleta", "cookie"], icon: Cookie },
  { keywords: ["pastel", "torta", "cake"], icon: Cake },
  { keywords: ["ensalada", "verdura", "saludable"], icon: Salad },
  { keywords: ["carne", "asado", "parrilla", "bife"], icon: Beef },
]

const EMOJI_KEYWORD_MAP: Array<{ keywords: string[]; emoji: string }> = [
  { keywords: ["dona"], emoji: "🍩" },
  { keywords: ["hamburguesa", "burger", "burguer"], emoji: "🍔" },
  { keywords: ["pizza"], emoji: "🍕" },
  { keywords: ["pan", "panader", "croissant", "bolleria", "pasteleria"], emoji: "🥐" },
  { keywords: ["helado", "postre", "nieve"], emoji: "🍦" },
  { keywords: ["taco", "tacos"], emoji: "🌮" },
  { keywords: ["cafe", "coffee", "espresso"], emoji: "☕" },
  { keywords: ["papas", "botana", "fritas", "snack"], emoji: "🍟" },
  { keywords: ["pollo", "chicken"], emoji: "🍗" },
  { keywords: ["bebida", "jugo", "refresco", "soda", "agua", "malteada", "batido"], emoji: "🥤" },
]

function normalized(name: string): string {
  return name
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
}

export function isEmoji(value: string): boolean {
  if (!value) return false
  const codePoint = value.codePointAt(0)!
  return (
    (codePoint >= 0x1f000 && codePoint <= 0x1faff) ||
    (codePoint >= 0x2600 && codePoint <= 0x27bf)
  )
}

export function lucideIconByName(name: string): LucideIcon | null {
  return name ? (LUCIDE_BY_NAME[name] ?? null) : null
}

export interface CategoryGlyph {
  emoji?: string
  icon?: LucideIcon
}

export function resolveCategoryIcon(icon: string | null, nombre: string): CategoryGlyph {
  const value = icon?.trim() ?? ""
  if (value && isEmoji(value)) return { emoji: value }
  if (value) {
    const byName = lucideIconByName(value)
    if (byName) return { icon: byName }
  }

  const key = normalized(nombre)
  const emojiMatch = EMOJI_KEYWORD_MAP.find((entry) =>
    entry.keywords.some((word) => key.includes(word)),
  )
  if (emojiMatch) return { emoji: emojiMatch.emoji }

  const iconMatch = NAME_KEYWORD_MAP.find((entry) =>
    entry.keywords.some((word) => key.includes(word)),
  )
  return { icon: iconMatch?.icon ?? Utensils }
}