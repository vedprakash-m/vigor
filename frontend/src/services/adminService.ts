export const adminService = {
  async getProviderPricing() {
    const resp = await fetch('/api/admin/provider-pricing', { credentials: 'include' })
    if (!resp.ok) throw new Error('Failed pricing')
    return resp.json() as Promise<Record<string, number>>
  },

  async validateProvider(provider: string, apiKey: string) {
    const resp = await fetch('/api/admin/validate-provider', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ provider_name: provider, api_key: apiKey })
    })
    return resp.json()
  }
}
