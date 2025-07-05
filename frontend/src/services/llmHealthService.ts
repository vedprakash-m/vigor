/**
 * LLM Health Monitoring Service
 * Handles communication with backend LLM health APIs
 */

interface LLMModel {
  id: string;
  name: string;
  provider: string;
  status: 'healthy' | 'degraded' | 'offline';
  responseTime: number;
  requestCount: number;
  errorRate: number;
  cost: number;
  lastHealthCheck: Date;
  configuration: {
    temperature: number;
    maxTokens: number;
    topP: number;
    enabled: boolean;
  };
}

interface SystemMetrics {
  totalRequests: number;
  averageResponseTime: number;
  overallErrorRate: number;
  dailyCost: number;
  activeUsers: number;
  systemLoad: number;
}

interface LLMHealthOverview {
  systemMetrics: SystemMetrics;
  models: LLMModel[];
  timeRange: string;
  lastUpdated: Date;
}

interface Alert {
  id: string;
  modelId: string;
  severity: 'info' | 'warning' | 'critical';
  type: string;
  message: string;
  timestamp: Date;
  acknowledged: boolean;
  acknowledgedBy?: string;
  acknowledgedAt?: Date;
}

interface HistoricalDataPoint {
  timestamp: Date;
  responseTime: number;
  requestCount: number;
  errorRate: number;
  cost: number;
}

interface HistoricalMetrics {
  modelId?: string;
  timeRange: string;
  dataPoints: HistoricalDataPoint[];
}

interface HealthCheckResponse {
  modelId: string;
  status: 'healthy' | 'degraded' | 'offline';
  responseTime: number;
  timestamp: Date;
  details: {
    apiReachable: boolean;
    authenticationValid: boolean;
    rateLimitStatus: string;
    lastError?: string;
  };
}

interface ModelSwitchRequest {
  fromModel: string;
  toModel: string;
  reason?: string;
}

class LLMHealthService {
  private baseURL = '/api/llm-health';

  private async fetchWithAuth<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    const token = localStorage.getItem('token');

    const response = await fetch(`${this.baseURL}${endpoint}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
        ...options.headers,
      },
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.detail || `HTTP ${response.status}: ${response.statusText}`);
    }

    return response.json();
  }

  /**
   * Get LLM health overview with system metrics and all models
   */
  async getHealthOverview(timeRange: string = '24h'): Promise<LLMHealthOverview> {
    const data = await this.fetchWithAuth<any>(`/overview?time_range=${timeRange}`);

    return {
      systemMetrics: {
        totalRequests: data.system_metrics.total_requests,
        averageResponseTime: data.system_metrics.average_response_time,
        overallErrorRate: data.system_metrics.overall_error_rate,
        dailyCost: data.system_metrics.daily_cost,
        activeUsers: data.system_metrics.active_users,
        systemLoad: data.system_metrics.system_load,
      },
      models: data.models.map(this.transformModel),
      timeRange: data.time_range,
      lastUpdated: new Date(data.last_updated),
    };
  }

  /**
   * Get all LLM models health status
   */
  async getModels(): Promise<LLMModel[]> {
    const data = await this.fetchWithAuth<any[]>('/models');
    return data.map(this.transformModel);
  }

  /**
   * Get specific LLM model health details
   */
  async getModelHealth(modelId: string): Promise<LLMModel> {
    const data = await this.fetchWithAuth<any>(`/models/${modelId}`);
    return this.transformModel(data);
  }

  /**
   * Perform health check on specific model
   */
  async performHealthCheck(modelId: string): Promise<HealthCheckResponse> {
    const data = await this.fetchWithAuth<any>(`/models/${modelId}/health-check`, {
      method: 'POST',
    });

    return {
      modelId: data.model_id,
      status: data.status,
      responseTime: data.response_time,
      timestamp: new Date(data.timestamp),
      details: {
        apiReachable: data.details.api_reachable,
        authenticationValid: data.details.authentication_valid,
        rateLimitStatus: data.details.rate_limit_status,
        lastError: data.details.last_error,
      },
    };
  }

  /**
   * Update model configuration
   */
  async updateModelConfiguration(
    modelId: string,
    config: Partial<LLMModel['configuration']>
  ): Promise<LLMModel['configuration']> {
    const requestData = {
      temperature: config.temperature,
      max_tokens: config.maxTokens,
      top_p: config.topP,
      enabled: config.enabled,
    };

    const data = await this.fetchWithAuth<any>(`/models/${modelId}/configuration`, {
      method: 'PUT',
      body: JSON.stringify(requestData),
    });

    return {
      temperature: data.temperature,
      maxTokens: data.max_tokens,
      topP: data.top_p,
      enabled: data.enabled,
    };
  }

  /**
   * Enable model
   */
  async enableModel(modelId: string): Promise<{ message: string }> {
    return this.fetchWithAuth<{ message: string }>(`/models/${modelId}/enable`, {
      method: 'POST',
    });
  }

  /**
   * Disable model
   */
  async disableModel(modelId: string): Promise<{ message: string }> {
    return this.fetchWithAuth<{ message: string }>(`/models/${modelId}/disable`, {
      method: 'POST',
    });
  }

  /**
   * Trigger failover from one model to another
   */
  async triggerFailover(request: ModelSwitchRequest): Promise<{ message: string; timestamp: Date; reason?: string }> {
    const requestData = {
      from_model: request.fromModel,
      to_model: request.toModel,
      reason: request.reason,
    };

    const data = await this.fetchWithAuth<any>('/failover', {
      method: 'POST',
      body: JSON.stringify(requestData),
    });

    return {
      message: data.message,
      timestamp: new Date(data.timestamp),
      reason: data.reason,
    };
  }

  /**
   * Get historical metrics
   */
  async getHistoricalMetrics(
    timeRange: string = '24h',
    modelId?: string
  ): Promise<HistoricalMetrics> {
    const params = new URLSearchParams({ time_range: timeRange });
    if (modelId) {
      params.append('model_id', modelId);
    }

    const data = await this.fetchWithAuth<any>(`/metrics/historical?${params}`);

    return {
      modelId: data.model_id,
      timeRange: data.time_range,
      dataPoints: data.data_points.map((point: any) => ({
        timestamp: new Date(point.timestamp),
        responseTime: point.response_time,
        requestCount: point.request_count,
        errorRate: point.error_rate,
        cost: point.cost,
      })),
    };
  }

  /**
   * Get active alerts
   */
  async getActiveAlerts(): Promise<Alert[]> {
    const data = await this.fetchWithAuth<any[]>('/alerts');

    return data.map((alert) => ({
      id: alert.id,
      modelId: alert.model_id,
      severity: alert.severity,
      type: alert.type,
      message: alert.message,
      timestamp: new Date(alert.timestamp),
      acknowledged: alert.acknowledged,
      acknowledgedBy: alert.acknowledged_by,
      acknowledgedAt: alert.acknowledged_at ? new Date(alert.acknowledged_at) : undefined,
    }));
  }

  /**
   * Acknowledge an alert
   */
  async acknowledgeAlert(alertId: string): Promise<{ message: string; acknowledgedBy: string; acknowledgedAt: Date }> {
    const data = await this.fetchWithAuth<any>(`/alerts/${alertId}/acknowledge`, {
      method: 'POST',
    });

    return {
      message: data.message,
      acknowledgedBy: data.acknowledged_by,
      acknowledgedAt: new Date(data.acknowledged_at),
    };
  }

  /**
   * Transform API model data to frontend format
   */
  private transformModel(data: any): LLMModel {
    return {
      id: data.id,
      name: data.name,
      provider: data.provider,
      status: data.status,
      responseTime: data.response_time,
      requestCount: data.request_count,
      errorRate: data.error_rate,
      cost: data.cost,
      lastHealthCheck: new Date(data.last_health_check),
      configuration: {
        temperature: data.configuration.temperature,
        maxTokens: data.configuration.max_tokens,
        topP: data.configuration.top_p,
        enabled: data.configuration.enabled,
      },
    };
  }
}

export const llmHealthService = new LLMHealthService();

export type {
    Alert, HealthCheckResponse, HistoricalDataPoint,
    HistoricalMetrics, LLMHealthOverview, LLMModel, ModelSwitchRequest, SystemMetrics
};
