/**
 * Bulk User Operations
 * Advanced bulk operations for user management including import/export, batch updates
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
import React, { useCallback, useState } from 'react';
import {
    FiAlertTriangle,
    FiCheckCircle,
    FiDownload,
    FiEdit,
    FiRefreshCw,
    FiUpload,
    FiUsers,
} from 'react-icons/fi';

interface BulkOperation {
    id: string;
    type: 'import' | 'export' | 'batch_update' | 'batch_delete' | 'email_campaign';
    status: 'pending' | 'running' | 'completed' | 'failed';
    progress: number;
    totalRecords: number;
    processedRecords: number;
    errorRecords: number;
    startedAt: Date;
    completedAt?: Date;
    filename?: string;
    details: string;
}

interface BulkUpdateConfig {
    operation: 'update_tier' | 'update_status' | 'update_subscription' | 'send_email';
    targetValue: string;
    filterCriteria: {
        tier?: string;
        status?: string;
        registrationDate?: string;
        lastLogin?: string;
    };
    affectedUsers: number;
}

const BulkUserOperations: React.FC = () => {
    const [operations, setOperations] = useState<BulkOperation[]>([]);
    const [selectedFile, setSelectedFile] = useState<File | null>(null);
    const [bulkUpdateConfig, setBulkUpdateConfig] = useState<BulkUpdateConfig>({
        operation: 'update_tier',
        targetValue: '',
        filterCriteria: {},
        affectedUsers: 0,
    });
    const [isProcessing, setIsProcessing] = useState(false);
    const [exportOptions, setExportOptions] = useState({
        format: 'csv',
        includePersonalData: false,
        dateRange: '30d',
    });

    const handleFileUpload = useCallback(async (event: React.ChangeEvent<HTMLInputElement>) => {
        const file = event.target.files?.[0];
        if (!file) return;

        setSelectedFile(file);

        // In a real implementation, this would validate the file format
        console.log('File selected:', file.name, file.size, file.type);
    }, []);

    const processImport = useCallback(async () => {
        if (!selectedFile) return;

        try {
            setIsProcessing(true);

            // Create a new bulk operation
            const newOperation: BulkOperation = {
                id: `import-${Date.now()}`,
                type: 'import',
                status: 'running',
                progress: 0,
                totalRecords: 0,
                processedRecords: 0,
                errorRecords: 0,
                startedAt: new Date(),
                filename: selectedFile.name,
                details: `Importing users from ${selectedFile.name}`,
            };

            setOperations(prev => [newOperation, ...prev]);

            // Simulate file processing
            for (let i = 0; i <= 100; i += 10) {
                await new Promise(resolve => setTimeout(resolve, 200));
                setOperations(prev => prev.map(op =>
                    op.id === newOperation.id
                        ? { ...op, progress: i, processedRecords: Math.floor(i * 2.5), totalRecords: 250 }
                        : op
                ));
            }

            // Complete the operation
            setOperations(prev => prev.map(op =>
                op.id === newOperation.id
                    ? {
                        ...op,
                        status: 'completed' as const,
                        progress: 100,
                        completedAt: new Date(),
                        processedRecords: 245,
                        errorRecords: 5,
                        totalRecords: 250,
                    }
                    : op
            ));

            setSelectedFile(null);
        } catch (error) {
            console.error('Import failed:', error);
        } finally {
            setIsProcessing(false);
        }
    }, [selectedFile]);

    const exportUsers = useCallback(async () => {
        try {
            setIsProcessing(true);

            const newOperation: BulkOperation = {
                id: `export-${Date.now()}`,
                type: 'export',
                status: 'running',
                progress: 0,
                totalRecords: 0,
                processedRecords: 0,
                errorRecords: 0,
                startedAt: new Date(),
                details: `Exporting user data (${exportOptions.format.toUpperCase()}, ${exportOptions.dateRange})`,
            };

            setOperations(prev => [newOperation, ...prev]);

            // Simulate export processing
            for (let i = 0; i <= 100; i += 20) {
                await new Promise(resolve => setTimeout(resolve, 300));
                setOperations(prev => prev.map(op =>
                    op.id === newOperation.id
                        ? { ...op, progress: i, processedRecords: Math.floor(i * 12.47), totalRecords: 1247 }
                        : op
                ));
            }

            // Generate and download file
            const csvData = Array.from({ length: 1247 }, (_, i) => ({
                ID: `user-${i + 1}`,
                Email: `user${i + 1}@example.com`,
                FirstName: `User${i + 1}`,
                LastName: `Test`,
                Tier: ['basic', 'premium', 'elite'][i % 3],
                Status: ['active', 'inactive'][i % 2],
                RegistrationDate: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
                LastLogin: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000).toISOString(),
            }));

            const csvString = [
                Object.keys(csvData[0]).join(','),
                ...csvData.slice(0, 10).map(row => Object.values(row).join(',')) // Sample data for demo
            ].join('\n');

            const blob = new Blob([csvString], { type: 'text/csv' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.style.display = 'none';
            a.href = url;
            a.download = `users-export-${new Date().toISOString().split('T')[0]}.csv`;
            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(url);

            // Complete the operation
            setOperations(prev => prev.map(op =>
                op.id === newOperation.id
                    ? {
                        ...op,
                        status: 'completed' as const,
                        progress: 100,
                        completedAt: new Date(),
                        processedRecords: 1247,
                        errorRecords: 0,
                        totalRecords: 1247,
                    }
                    : op
            ));
        } catch (error) {
            console.error('Export failed:', error);
        } finally {
            setIsProcessing(false);
        }
    }, [exportOptions]);

    const executeBulkUpdate = useCallback(async () => {
        try {
            setIsProcessing(true);

            const newOperation: BulkOperation = {
                id: `batch-update-${Date.now()}`,
                type: 'batch_update',
                status: 'running',
                progress: 0,
                totalRecords: bulkUpdateConfig.affectedUsers,
                processedRecords: 0,
                errorRecords: 0,
                startedAt: new Date(),
                details: `Bulk ${bulkUpdateConfig.operation}: ${bulkUpdateConfig.targetValue}`,
            };

            setOperations(prev => [newOperation, ...prev]);

            // Simulate batch processing
            for (let i = 0; i <= 100; i += 15) {
                await new Promise(resolve => setTimeout(resolve, 400));
                setOperations(prev => prev.map(op =>
                    op.id === newOperation.id
                        ? {
                            ...op,
                            progress: i,
                            processedRecords: Math.floor(i * bulkUpdateConfig.affectedUsers / 100),
                        }
                        : op
                ));
            }

            // Complete the operation
            setOperations(prev => prev.map(op =>
                op.id === newOperation.id
                    ? {
                        ...op,
                        status: 'completed' as const,
                        progress: 100,
                        completedAt: new Date(),
                        processedRecords: bulkUpdateConfig.affectedUsers - 3,
                        errorRecords: 3,
                    }
                    : op
            ));
        } catch (error) {
            console.error('Bulk update failed:', error);
        } finally {
            setIsProcessing(false);
        }
    }, [bulkUpdateConfig]);

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'completed': return 'green';
            case 'running': return 'blue';
            case 'failed': return 'red';
            case 'pending': return 'orange';
            default: return 'gray';
        }
    };

    const getStatusIcon = (status: string) => {
        switch (status) {
            case 'completed': return FiCheckCircle;
            case 'running': return FiRefreshCw;
            case 'failed': return FiAlertTriangle;
            default: return FiUsers;
        }
    };

    return (
        <Container maxW="7xl" py={8}>
            <Flex direction="column" align="stretch" gap={6}>
                {/* Header */}
                <Box>
                    <Heading size="lg">Bulk User Operations</Heading>
                    <Text color="gray.600" fontSize="sm">
                        Import, export, and perform batch operations on user data
                    </Text>
                </Box>

                {/* Operations Grid */}
                <Grid templateColumns={{ base: '1fr', lg: 'repeat(3, 1fr)' }} gap={6}>
                    {/* Import Users */}
                    <Box p={6} border="1px" borderColor="gray.200" borderRadius="md">
                        <Heading size="md" mb={4}>
                            <FiUpload style={{ display: 'inline', marginRight: '8px' }} />
                            Import Users
                        </Heading>
                        <Flex direction="column" gap={4}>
                            <Box>
                                <Text fontSize="sm" color="gray.600" mb={2}>
                                    Upload CSV or Excel file with user data
                                </Text>
                                <Input
                                    type="file"
                                    accept=".csv,.xlsx,.xls"
                                    onChange={handleFileUpload}
                                    size="sm"
                                />
                            </Box>
                            {selectedFile && (
                                <Box p={3} bg="blue.50" borderRadius="md">
                                    <Text fontSize="sm" fontWeight="semibold">
                                        {selectedFile.name}
                                    </Text>
                                    <Text fontSize="xs" color="gray.600">
                                        {(selectedFile.size / 1024).toFixed(1)} KB
                                    </Text>
                                </Box>
                            )}
                            <Button
                                colorScheme="blue"
                                size="sm"
                                onClick={processImport}
                                disabled={!selectedFile || isProcessing}
                                loading={isProcessing}
                            >
                                Start Import
                            </Button>
                        </Flex>
                    </Box>

                    {/* Export Users */}
                    <Box p={6} border="1px" borderColor="gray.200" borderRadius="md">
                        <Heading size="md" mb={4}>
                            <FiDownload style={{ display: 'inline', marginRight: '8px' }} />
                            Export Users
                        </Heading>
                        <Flex direction="column" gap={4}>
                            <Box>
                                <Text fontSize="sm" color="gray.600" mb={2}>Format</Text>
                                <select
                                    value={exportOptions.format}
                                    onChange={(e) => setExportOptions(prev => ({ ...prev, format: e.target.value }))}
                                    style={{ width: '100%', padding: '6px', borderRadius: '6px', border: '1px solid #E2E8F0' }}
                                >
                                    <option value="csv">CSV</option>
                                    <option value="xlsx">Excel</option>
                                    <option value="json">JSON</option>
                                </select>
                            </Box>
                            <Box>
                                <Text fontSize="sm" color="gray.600" mb={2}>Date Range</Text>
                                <select
                                    value={exportOptions.dateRange}
                                    onChange={(e) => setExportOptions(prev => ({ ...prev, dateRange: e.target.value }))}
                                    style={{ width: '100%', padding: '6px', borderRadius: '6px', border: '1px solid #E2E8F0' }}
                                >
                                    <option value="7d">Last 7 days</option>
                                    <option value="30d">Last 30 days</option>
                                    <option value="90d">Last 90 days</option>
                                    <option value="all">All time</option>
                                </select>
                            </Box>
                            <Button
                                colorScheme="green"
                                size="sm"
                                onClick={exportUsers}
                                disabled={isProcessing}
                                loading={isProcessing}
                            >
                                Export Users
                            </Button>
                        </Flex>
                    </Box>

                    {/* Batch Operations */}
                    <Box p={6} border="1px" borderColor="gray.200" borderRadius="md">
                        <Heading size="md" mb={4}>
                            <FiEdit style={{ display: 'inline', marginRight: '8px' }} />
                            Batch Update
                        </Heading>
                        <Flex direction="column" gap={4}>
                            <Box>
                                <Text fontSize="sm" color="gray.600" mb={2}>Operation</Text>
                                <select
                                    value={bulkUpdateConfig.operation}
                                    onChange={(e) => setBulkUpdateConfig(prev => ({
                                        ...prev,
                                        operation: e.target.value as BulkUpdateConfig['operation'],
                                        affectedUsers: Math.floor(Math.random() * 500) + 50
                                    }))}
                                    style={{ width: '100%', padding: '6px', borderRadius: '6px', border: '1px solid #E2E8F0' }}
                                >
                                    <option value="update_tier">Update Tier</option>
                                    <option value="update_status">Update Status</option>
                                    <option value="update_subscription">Update Subscription</option>
                                    <option value="send_email">Send Email Campaign</option>
                                </select>
                            </Box>
                            <Box>
                                <Text fontSize="sm" color="gray.600" mb={2}>Target Value</Text>
                                <Input
                                    placeholder="Enter new value..."
                                    value={bulkUpdateConfig.targetValue}
                                    onChange={(e) => setBulkUpdateConfig(prev => ({ ...prev, targetValue: e.target.value }))}
                                    size="sm"
                                />
                            </Box>
                            {bulkUpdateConfig.affectedUsers > 0 && (
                                <Box p={3} bg="orange.50" borderRadius="md">
                                    <Text fontSize="sm">
                                        <strong>{bulkUpdateConfig.affectedUsers}</strong> users will be affected
                                    </Text>
                                </Box>
                            )}
                            <Button
                                colorScheme="orange"
                                size="sm"
                                onClick={executeBulkUpdate}
                                disabled={!bulkUpdateConfig.targetValue || isProcessing}
                                loading={isProcessing}
                            >
                                Execute Batch Update
                            </Button>
                        </Flex>
                    </Box>
                </Grid>

                {/* Operations History */}
                <Box p={6} border="1px" borderColor="gray.200" borderRadius="md">
                    <Heading size="md" mb={4}>Operations History</Heading>
                    <Flex direction="column" gap={3}>
                        {operations.length === 0 ? (
                            <Box textAlign="center" py={8} color="gray.500">
                                <FiUsers size={48} />
                                <Text mt={4}>No operations performed yet</Text>
                                <Text fontSize="sm">Start an import, export, or batch operation to see it here</Text>
                            </Box>
                        ) : (
                            operations.map((operation) => {
                                const StatusIcon = getStatusIcon(operation.status);
                                return (
                                    <Box key={operation.id} p={4} border="1px" borderColor="gray.200" borderRadius="md">
                                        <Flex justify="space-between" align="center" mb={2}>
                                            <Flex align="center" gap={3}>
                                                <StatusIcon size={20} />
                                                <Box>
                                                    <Text fontWeight="semibold">{operation.details}</Text>
                                                    <Text fontSize="sm" color="gray.600">
                                                        {operation.filename && `File: ${operation.filename}`}
                                                    </Text>
                                                </Box>
                                            </Flex>
                                            <Badge colorScheme={getStatusColor(operation.status)}>
                                                {operation.status.toUpperCase()}
                                            </Badge>
                                        </Flex>

                                        {operation.status === 'running' && (
                                            <Box mb={2}>
                                                <Flex justify="space-between" mb={1}>
                                                    <Text fontSize="sm">Progress</Text>
                                                    <Text fontSize="sm">{operation.progress}%</Text>
                                                </Flex>
                                                <Box w="full" bg="gray.200" borderRadius="md" h="6px">
                                                    <Box
                                                        h="full"
                                                        bg="blue.500"
                                                        borderRadius="md"
                                                        width={`${operation.progress}%`}
                                                        transition="width 0.3s ease"
                                                    />
                                                </Box>
                                            </Box>
                                        )}

                                        <Grid templateColumns="repeat(auto-fit, minmax(150px, 1fr))" gap={4} fontSize="sm">
                                            <Box>
                                                <Text color="gray.600">Total Records</Text>
                                                <Text fontWeight="semibold">{operation.totalRecords.toLocaleString()}</Text>
                                            </Box>
                                            <Box>
                                                <Text color="gray.600">Processed</Text>
                                                <Text fontWeight="semibold" color="green.600">
                                                    {operation.processedRecords.toLocaleString()}
                                                </Text>
                                            </Box>
                                            <Box>
                                                <Text color="gray.600">Errors</Text>
                                                <Text fontWeight="semibold" color="red.600">
                                                    {operation.errorRecords.toLocaleString()}
                                                </Text>
                                            </Box>
                                            <Box>
                                                <Text color="gray.600">Duration</Text>
                                                <Text fontWeight="semibold">
                                                    {operation.completedAt
                                                        ? `${Math.round((operation.completedAt.getTime() - operation.startedAt.getTime()) / 1000)}s`
                                                        : `${Math.round((new Date().getTime() - operation.startedAt.getTime()) / 1000)}s`
                                                    }
                                                </Text>
                                            </Box>
                                        </Grid>
                                    </Box>
                                );
                            })
                        )}
                    </Flex>
                </Box>
            </Flex>
        </Container>
    );
};

export default BulkUserOperations;
