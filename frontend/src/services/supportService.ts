export const supportService = {
  async searchUser(email: string) {
    const resp = await fetch(`/api/admin/users?email=${encodeURIComponent(email)}`, { credentials: 'include' })
    if (!resp.ok) throw new Error('Failed search')
    return resp.json()
  },
  async getUserLogs(userId: string) {
    const resp = await fetch(`/api/admin/users/${userId}/workout-logs`, { credentials: 'include' })
    if (!resp.ok) throw new Error('Failed logs')
    return resp.json()
  },
  async exportLogsCsv(userId: string) {
    window.open(`/api/admin/users/${userId}/workout-logs.csv`, '_blank')
  }
}
