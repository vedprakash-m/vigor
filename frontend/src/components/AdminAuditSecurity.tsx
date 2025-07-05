/**
 * Admin Audit Logging & Security Monitoring
 * Comprehensive audit trail and security monitoring for admin operations
 */
import {
    Badge,
    Box,
    Button,
    Container,
    Flex,
    Grid,
    Heading,
    Input,
    Text,
} from '@chakra-ui/react';
import React, { useCallback, useEffect, useState } from 'react';
import {
    FiActivity,
    FiAlertTriangle,
    FiClock,
    FiDownload,
    FiEye,
    FiRefreshCw,
    FiShield,
    FiUser,
} from 'react-icons/fi';

interface AuditLog {
    id: string;
    timestamp: Date;
    userId: string;
    userEmail: string;
    action: string;
    category: 'authentication' | 'user_management' | 'llm_config' | 'system' | 'security';
    resource: string;
    details: string;
    ipAddress: string;
    userAgent: string;
    severity: 'info' | 'warning' | 'error' | 'critical';
    outcome: 'success' | 'failure' | 'partial';
}

interface SecurityAlert {
    id: string;
    timestamp: Date;
    type: 'failed_login' | 'unusual_activity' | 'privilege_escalation' | 'data_access' | 'configuration_change';
    severity: 'low' | 'medium' | 'high' | 'critical';
    title: string;
    description: string;
    userId?: string;
    userEmail?: string;
    ipAddress: string;
    resolved: boolean;
    resolvedBy?: string;
    resolvedAt?: Date;
}

interface SecurityMetrics {
    totalAlerts: number;
    criticalAlerts: number;
    resolvedAlerts: number;
    failedLoginAttempts: number;
    suspiciousActivities: number;
    activeThreats: number;
}

const AdminAuditSecurity: React.FC = () => {
    const [auditLogs, setAuditLogs] = useState<AuditLog[]>([]);
    const [securityAlerts, setSecurityAlerts] = useState<SecurityAlert[]>([]);
    const [securityMetrics, setSecurityMetrics] = useState<SecurityMetrics | null>(null);
    const [selectedCategory, setSelectedCategory] = useState<string>('all');
    const [selectedSeverity, setSelectedSeverity] = useState<string>('all');
    const [searchQuery, setSearchQuery] = useState('');
    const [isLoading, setIsLoading] = useState(true);
    const [isExporting, setIsExporting] = useState(false);
    const [lastUpdated, setLastUpdated] = useState(new Date());

    const fetchAuditData = useCallback(async () => {
        try {
            setIsLoading(true);

            // Generate mock data for demonstration
            const mockAuditLogs: AuditLog[] = [
                {
                    id: '1',
                    timestamp: new Date(Date.now() - 10 * 60 * 1000),
                    userId: 'admin-001',
                    userEmail: 'admin@vigor.com',
                    action: 'Update LLM Configuration',
                    category: 'llm_config',
                    resource: 'gpt-4o-model',
                    details: 'Changed temperature from 0.7 to 0.8',
                    ipAddress: '192.168.1.100',
                    userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
                    severity: 'info',
                    outcome: 'success',
                },
                {
                    id: '2',
                    timestamp: new Date(Date.now() - 25 * 60 * 1000),
                    userId: 'admin-002',
                    userEmail: 'security@vigor.com',
                    action: 'Disable User Account',
                    category: 'user_management',
                    resource: 'user-12345',
                    details: 'Suspended account due to suspicious activity',
                    ipAddress: '10.0.0.50',
                    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
                    severity: 'warning',
                    outcome: 'success',
                },
                {
                    id: '3',
                    timestamp: new Date(Date.now() - 45 * 60 * 1000),
                    userId: 'system',
                    userEmail: 'system@vigor.com',
                    action: 'Failed Login Attempt',
                    category: 'authentication',
                    resource: 'login-endpoint',
                    details: 'Multiple failed login attempts detected',
                    ipAddress: '203.0.113.42',
                    userAgent: 'Unknown',
                    severity: 'error',
                    outcome: 'failure',
                },
            ];

            const mockSecurityAlerts: SecurityAlert[] = [
                {
                    id: 'alert-001',
                    timestamp: new Date(Date.now() - 30 * 60 * 1000),
                    type: 'failed_login',
                    severity: 'high',
                    title: 'Multiple Failed Login Attempts',
                    description: '15 failed login attempts from IP 203.0.113.42 in the last 10 minutes',
                    ipAddress: '203.0.113.42',
                    resolved: false,
                },
                {
                    id: 'alert-002',
                    timestamp: new Date(Date.now() - 60 * 60 * 1000),
                    type: 'unusual_activity',
                    severity: 'medium',
                    title: 'Unusual API Usage Pattern',
                    description: 'User making 10x more API calls than normal baseline',
                    userId: 'user-98765',
                    userEmail: 'suspicious@example.com',
                    ipAddress: '198.51.100.23',
                    resolved: true,
                    resolvedBy: 'admin@vigor.com',
                    resolvedAt: new Date(Date.now() - 30 * 60 * 1000),
                },
                {
                    id: 'alert-003',
                    timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000),
                    type: 'configuration_change',
                    severity: 'critical',
                    title: 'Critical System Configuration Modified',
                    description: 'LLM failover settings were modified outside normal hours',
                    userId: 'admin-003',
                    userEmail: 'nightshift@vigor.com',
                    ipAddress: '172.16.0.10',
                    resolved: false,
                },
            ];

            const mockSecurityMetrics: SecurityMetrics = {
                totalAlerts: 47,
                criticalAlerts: 3,
                resolvedAlerts: 42,
                failedLoginAttempts: 156,
                suspiciousActivities: 8,
                activeThreats: 2,
            };

            setAuditLogs(mockAuditLogs);
            setSecurityAlerts(mockSecurityAlerts);
            setSecurityMetrics(mockSecurityMetrics);
            setLastUpdated(new Date());
        } catch (error) {
            console.error('Failed to fetch audit data:', error);
        } finally {
            setIsLoading(false);
        }
    }, []);

    const exportAuditData = useCallback(async () => {
        try {
            setIsExporting(true);

            // Create CSV data from audit logs
            const csvData = auditLogs.map(log => ({
                Timestamp: log.timestamp.toISOString(),
                User: log.userEmail,
                Action: log.action,
                Category: log.category,
                Resource: log.resource,
                Details: log.details,
                'IP Address': log.ipAddress,
                Severity: log.severity,
                Outcome: log.outcome,
            }));

            const csvString = [
                Object.keys(csvData[0] || {}).join(','),
                ...csvData.map(row => Object.values(row).map(val => `"${val}"`).join(','))
            ].join('\n');

            const blob = new Blob([csvString], { type: 'text/csv' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.style.display = 'none';
            a.href = url;
            a.download = `audit-logs-${new Date().toISOString().split('T')[0]}.csv`;
            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(url);
        } catch (error) {
            console.error('Failed to export audit data:', error);
        } finally {
            setIsExporting(false);
        }
    }, [auditLogs]);

    const resolveAlert = useCallback(async (alertId: string) => {
        try {
            // In a real implementation, this would call an API
            setSecurityAlerts(prev => prev.map(alert =>
                alert.id === alertId
                    ? { ...alert, resolved: true, resolvedBy: 'current-admin@vigor.com', resolvedAt: new Date() }
                    : alert
            ));
        } catch (error) {
            console.error('Failed to resolve alert:', error);
        }
    }, []);

    useEffect(() => {
        fetchAuditData();
        const interval = setInterval(fetchAuditData, 30000); // Refresh every 30 seconds
        return () => clearInterval(interval);
    }, [fetchAuditData]);

    // Filter logs based on category, severity, and search query
    const filteredLogs = auditLogs.filter(log => {
        const matchesCategory = selectedCategory === 'all' || log.category === selectedCategory;
        const matchesSeverity = selectedSeverity === 'all' || log.severity === selectedSeverity;
        const matchesSearch = searchQuery === '' ||
            log.action.toLowerCase().includes(searchQuery.toLowerCase()) ||
            log.userEmail.toLowerCase().includes(searchQuery.toLowerCase()) ||
            log.details.toLowerCase().includes(searchQuery.toLowerCase());

        return matchesCategory && matchesSeverity && matchesSearch;
    });

    const getSeverityColor = (severity: string) => {
        switch (severity) {
            case 'critical': return 'red';
            case 'error': return 'red';
            case 'warning': return 'orange';
            case 'info': return 'blue';
            default: return 'gray';
        }
    };

    const getAlertSeverityColor = (severity: string) => {
        switch (severity) {
            case 'critical': return 'red';
            case 'high': return 'orange';
            case 'medium': return 'yellow';
            case 'low': return 'blue';
            default: return 'gray';
        }
    };

    if (isLoading && !auditLogs.length) {
        return (
            <Container maxW="7xl" py={8}>
                <Flex direction="column" align="stretch" gap={6}>
                    <Flex justify="center" py={20}>
                        <Box textAlign="center">
                            <FiShield size={48} />
                            <Text mt={4}>Loading audit and security data...</Text>
                        </Box>
                    </Flex>
                </Flex>
            </Container>
        );
    }

    return (
        <Container maxW="7xl" py={8}>
            <Flex direction="column" align="stretch" gap={6}>
                {/* Header */}
                <Flex justify="space-between" align="center" wrap="wrap" gap={4}>
                    <Box>
                        <Heading size="lg">Audit Logging & Security Monitoring</Heading>
                        <Text color="gray.600" fontSize="sm">
                            Last updated: {lastUpdated.toLocaleTimeString()}
                        </Text>
                    </Box>

                    <Flex gap={3}>
                        <Button
                            variant="outline"
                            size="sm"
                            onClick={exportAuditData}
                            loading={isExporting}
                            loadingText="Exporting..."
                        >
                            <FiDownload style={{ marginRight: '8px' }} />
                            Export Logs
                        </Button>
                        <Button
                            variant="outline"
                            size="sm"
                            onClick={fetchAuditData}
                            loading={isLoading}
                        >
                            <FiRefreshCw style={{ marginRight: '8px' }} />
                            Refresh
                        </Button>
                    </Flex>
                </Flex>

                {/* Security Metrics */}
                <Grid templateColumns={{ base: '1fr', md: 'repeat(3, 1fr)', lg: 'repeat(6, 1fr)' }} gap={4}>
                    <Box p={4} border="1px" borderColor="gray.200" borderRadius="md" textAlign="center">
                        <FiAlertTriangle color="orange" size={24} />
                        <Text fontSize="2xl" fontWeight="bold" mt={2}>
                            {securityMetrics?.totalAlerts}
                        </Text>
                        <Text fontSize="sm" color="gray.600">Total Alerts</Text>
                    </Box>
                    <Box p={4} border="1px" borderColor="gray.200" borderRadius="md" textAlign="center">
                        <FiShield color="red" size={24} />
                        <Text fontSize="2xl" fontWeight="bold" mt={2} color="red.500">
                            {securityMetrics?.criticalAlerts}
                        </Text>
                        <Text fontSize="sm" color="gray.600">Critical</Text>
                    </Box>
                    <Box p={4} border="1px" borderColor="gray.200" borderRadius="md" textAlign="center">
                        <FiActivity color="green" size={24} />
                        <Text fontSize="2xl" fontWeight="bold" mt={2} color="green.500">
                            {securityMetrics?.resolvedAlerts}
                        </Text>
                        <Text fontSize="sm" color="gray.600">Resolved</Text>
                    </Box>
                    <Box p={4} border="1px" borderColor="gray.200" borderRadius="md" textAlign="center">
                        <FiUser color="red" size={24} />
                        <Text fontSize="2xl" fontWeight="bold" mt={2}>
                            {securityMetrics?.failedLoginAttempts}
                        </Text>
                        <Text fontSize="sm" color="gray.600">Failed Logins</Text>
                    </Box>
                    <Box p={4} border="1px" borderColor="gray.200" borderRadius="md" textAlign="center">
                        <FiEye color="orange" size={24} />
                        <Text fontSize="2xl" fontWeight="bold" mt={2}>
                            {securityMetrics?.suspiciousActivities}
                        </Text>
                        <Text fontSize="sm" color="gray.600">Suspicious</Text>
                    </Box>
                    <Box p={4} border="1px" borderColor="gray.200" borderRadius="md" textAlign="center">
                        <FiAlertTriangle color="red" size={24} />
                        <Text fontSize="2xl" fontWeight="bold" mt={2} color="red.500">
                            {securityMetrics?.activeThreats}
                        </Text>
                        <Text fontSize="sm" color="gray.600">Active Threats</Text>
                    </Box>
                </Grid>

                {/* Security Alerts */}
                <Box p={6} border="1px" borderColor="gray.200" borderRadius="md">
                    <Heading size="md" mb={4}>Active Security Alerts</Heading>
                    <Flex direction="column" gap={3}>
                        {securityAlerts.filter(alert => !alert.resolved).map((alert) => (
                            <Box key={alert.id} p={4} border="1px" borderColor="gray.200" borderRadius="md">
                                <Flex justify="space-between" align="center" mb={2}>
                                    <Flex align="center" gap={3}>
                                        <Badge colorScheme={getAlertSeverityColor(alert.severity)}>
                                            {alert.severity.toUpperCase()}
                                        </Badge>
                                        <Text fontWeight="semibold">{alert.title}</Text>
                                    </Flex>
                                    <Button
                                        size="sm"
                                        colorScheme="green"
                                        onClick={() => resolveAlert(alert.id)}
                                    >
                                        Resolve
                                    </Button>
                                </Flex>
                                <Text fontSize="sm" color="gray.600" mb={2}>
                                    {alert.description}
                                </Text>
                                <Flex justify="space-between" fontSize="xs" color="gray.500">
                                    <Text>IP: {alert.ipAddress}</Text>
                                    <Text>{alert.timestamp.toLocaleString()}</Text>
                                </Flex>
                            </Box>
                        ))}
                    </Flex>
                </Box>

                {/* Filters and Search */}
                <Flex gap={4} wrap="wrap">
                    <Box flex="1" minW="200px">
                        <Input
                            placeholder="Search logs..."
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                        />
                    </Box>
                    <Box>
                        <select
                            value={selectedCategory}
                            onChange={(e) => setSelectedCategory(e.target.value)}
                            style={{ padding: '8px', borderRadius: '6px', border: '1px solid #E2E8F0' }}
                        >
                            <option value="all">All Categories</option>
                            <option value="authentication">Authentication</option>
                            <option value="user_management">User Management</option>
                            <option value="llm_config">LLM Configuration</option>
                            <option value="system">System</option>
                            <option value="security">Security</option>
                        </select>
                    </Box>
                    <Box>
                        <select
                            value={selectedSeverity}
                            onChange={(e) => setSelectedSeverity(e.target.value)}
                            style={{ padding: '8px', borderRadius: '6px', border: '1px solid #E2E8F0' }}
                        >
                            <option value="all">All Severities</option>
                            <option value="info">Info</option>
                            <option value="warning">Warning</option>
                            <option value="error">Error</option>
                            <option value="critical">Critical</option>
                        </select>
                    </Box>
                </Flex>

                {/* Audit Logs */}
                <Box p={6} border="1px" borderColor="gray.200" borderRadius="md">
                    <Heading size="md" mb={4}>Audit Logs ({filteredLogs.length})</Heading>
                    <Flex direction="column" gap={3}>
                        {filteredLogs.map((log) => (
                            <Box key={log.id} p={4} border="1px" borderColor="gray.200" borderRadius="md">
                                <Flex justify="space-between" align="center" mb={2}>
                                    <Flex align="center" gap={3}>
                                        <Badge colorScheme={getSeverityColor(log.severity)}>
                                            {log.severity.toUpperCase()}
                                        </Badge>
                                        <Text fontWeight="semibold">{log.action}</Text>
                                        <Badge variant="outline">{log.category}</Badge>
                                    </Flex>
                                    <Flex align="center" gap={2}>
                                        <FiClock size={16} />
                                        <Text fontSize="sm" color="gray.600">
                                            {log.timestamp.toLocaleString()}
                                        </Text>
                                    </Flex>
                                </Flex>
                                <Text fontSize="sm" color="gray.600" mb={2}>
                                    {log.details}
                                </Text>
                                <Flex justify="space-between" fontSize="xs" color="gray.500">
                                    <Text>User: {log.userEmail}</Text>
                                    <Text>IP: {log.ipAddress}</Text>
                                    <Text>Resource: {log.resource}</Text>
                                    <Badge size="sm" colorScheme={log.outcome === 'success' ? 'green' : 'red'}>
                                        {log.outcome}
                                    </Badge>
                                </Flex>
                            </Box>
                        ))}
                    </Flex>
                </Box>
            </Flex>
        </Container>
    );
};

export default AdminAuditSecurity;
