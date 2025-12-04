const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '';

// Azure Cost Management types
interface CostData {
  total_cost: number;
  currency: string;
  period: string;
  breakdown?: Array<{
    service: string;
    cost: number;
    percentage: number;
  }>;
}

interface BudgetStatus {
  budget_name: string;
  current_spend: number;
  budget_limit: number;
  percentage_used: number;
  status: 'active' | 'warning' | 'exceeded' | 'suspended';
  alerts_enabled: boolean;
}

interface CostAlert {
  alert_id: string;
  alert_level: 'info' | 'warning' | 'critical';
  message: string;
  threshold_percentage: number;
  triggered_at: string;
}

interface UsageTrends {
  daily_trend: Array<{ date: string; cost: number }>;
  weekly_average: number;
  monthly_projection: number;
  growth_rate: number;
}

interface AzureCostAnalytics {
  current_costs: CostData;
  budget_status: BudgetStatus;
  cost_breakdown: Array<{
    service_name: string;
    cost: number;
    percentage: number;
    trend: 'up' | 'down' | 'stable';
  }>;
  alerts: Array<CostAlert>;
  usage_trends: UsageTrends;
  last_updated: string;
}

interface BudgetSyncResult {
  status: string;
  global_usage: number;
  azure_costs?: CostData;
  last_sync: string;
  error?: string;
}

interface RealTimeAnalytics {
  global_usage: number;
  global_limit: number;
  usage_percentage: number;
  cached_budgets: number;
  last_updated: string;
  azure_costs?: CostData;
  data_source: string;
  azure_error?: string;
}

export const adminService = {
  async getProviderPricing() {
    const resp = await fetch(`${API_BASE_URL}/admin/provider-pricing`, { credentials: 'include' })
    if (!resp.ok) throw new Error('Failed pricing')
    return resp.json() as Promise<Record<string, number>>
  },

  async validateProvider(provider: string, apiKey: string) {
    const resp = await fetch(`${API_BASE_URL}/admin/validate-provider`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ provider_name: provider, api_key: apiKey })
    })
    return resp.json()
  },

  // Azure Cost Management methods
  async getAzureCostAnalytics(): Promise<AzureCostAnalytics> {
    const resp = await fetch(`${API_BASE_URL}/admin/azure-cost-analytics`, { credentials: 'include' })
    if (!resp.ok) throw new Error('Failed to fetch Azure cost analytics')
    return resp.json()
  },

  async syncAzureBudget(): Promise<BudgetSyncResult> {
    const resp = await fetch(`${API_BASE_URL}/admin/azure-budget-sync`, {
      method: 'POST',
      credentials: 'include'
    })
    if (!resp.ok) throw new Error('Failed to sync Azure budget')
    return resp.json()
  },

  async getRealTimeAnalytics(): Promise<RealTimeAnalytics> {
    const resp = await fetch(`${API_BASE_URL}/admin/real-time-cost-analytics`, { credentials: 'include' })
    if (!resp.ok) throw new Error('Failed to fetch real-time analytics')
    return resp.json()
  },

  async createBudgetAlert(budgetName: string, thresholdPercentage: number, emailContacts: string[]) {
    const resp = await fetch(`${API_BASE_URL}/admin/azure-budget-alert`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({
        budget_name: budgetName,
        threshold_percentage: thresholdPercentage,
        email_contacts: emailContacts
      })
    })
    if (!resp.ok) throw new Error('Failed to create budget alert')
    return resp.json()
  },

  async deleteBudgetAlert(alertId: string) {
    const resp = await fetch(`${API_BASE_URL}/admin/azure-budget-alert/${alertId}`, {
      method: 'DELETE',
      credentials: 'include'
    })
    if (!resp.ok) throw new Error('Failed to delete budget alert')
    return resp.json()
  },

  async getCostOptimizationRecommendations() {
    const resp = await fetch(`${API_BASE_URL}/admin/cost-optimization-recommendations`, { credentials: 'include' })
    if (!resp.ok) throw new Error('Failed to fetch cost optimization recommendations')
    return resp.json()
  }
}
