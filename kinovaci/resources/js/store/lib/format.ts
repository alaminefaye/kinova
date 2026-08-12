/** Montants en Franc CFA, ex. `12 500 FCFA`. */
export function formatMoney(value: number): string {
  const n = Math.round(Number(value) || 0)
  return `${new Intl.NumberFormat('fr-FR').format(n)} FCFA`
}

export function resolveMediaUrl(url?: string | null): string {
  if (!url) return ''
  if (/^https?:\/\//i.test(url)) return url
  if (url.startsWith('//')) return `https:${url}`
  if (url.startsWith('/')) return url
  return `/${url}`
}

export function statusLabel(status: string): string {
  switch (status) {
    case 'pending':
      return 'En attente'
    case 'processing':
      return 'En préparation'
    case 'shipped':
      return 'Expédiée'
    case 'delivered':
      return 'Livrée'
    case 'cancelled':
      return 'Annulée'
    default:
      return status
  }
}
