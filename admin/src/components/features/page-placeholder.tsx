interface PagePlaceholderProps {
  title: string
  description?: string
}

export function PagePlaceholder({ title, description }: PagePlaceholderProps) {
  return (
    <div className="space-y-1">
      <h1 className="text-3xl font-semibold">{title}</h1>
      {description ? <p className="text-muted-foreground">{description}</p> : null}
    </div>
  )
}