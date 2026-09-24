import { useEffect, useState } from "react"

export function useDocumentVisible(): boolean {
  const [visible, setVisible] = useState(() => document.visibilityState === "visible")

  useEffect(() => {
    function handleVisibilityChange() {
      setVisible(document.visibilityState === "visible")
    }

    document.addEventListener("visibilitychange", handleVisibilityChange)
    return () => document.removeEventListener("visibilitychange", handleVisibilityChange)
  }, [])

  return visible
}