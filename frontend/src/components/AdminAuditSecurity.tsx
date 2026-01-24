/**
 * Admin Audit & Security Component
 * Displays security logs and audit trails for administrators
 */

import {
    Badge,
    Box,
    Button,
    Card,
    Heading,
    HStack,
    Input,
    Table,
    Text,
    VStack,
} from '@chakra-ui/react'
import { useState } from 'react'

interface AuditLog {
    id: string
    timestamp: string
    action: string
    userId: string
    userEmail: string
    resource: string
    ipAddress: string
    status: 'success' | 'failure' | 'warning'
    details?: string
}

// Mock audit data
const mockAuditLogs: AuditLog[] = [
    {
        id: '1',
        timestamp: new Date(Date.now() - 1000 * 60 * 5).toISOString(),
        action: 'LOGIN',
        userId: 'user-123',
        userEmail: 'user@example.com',
        resource: 'auth/login',
        ipAddress: '192.168.1.1',
        status: 'success',
    },
    {
        id: '2',
        timestamp: new Date(Date.now() - 1000 * 60 * 15).toISOString(),
        action: 'WORKOUT_GENERATE',
        userId: 'user-456',
        userEmail: 'fitness@example.com',
        resource: 'ai/generate',
        ipAddress: '10.0.0.1',
        status: 'success',
        details: 'Generated 45-min bodyweight workout',
    },
    {
        id: '3',
        timestamp: new Date(Date.now() - 1000 * 60 * 30).toISOString(),
        action: 'API_RATE_LIMIT',
        userId: 'user-789',
        userEmail: 'heavy@example.com',
        resource: 'ai/generate',
        ipAddress: '172.16.0.1',
        status: 'warning',
        details: 'Rate limit exceeded: 10 requests/minute',
    },
    {
        id: '4',
        timestamp: new Date(Date.now() - 1000 * 60 * 60).toISOString(),
        action: 'LOGIN_FAILED',
        userId: 'unknown',
        userEmail: 'attacker@example.com',
        resource: 'auth/login',
        ipAddress: '203.0.113.1',
        status: 'failure',
        details: 'Invalid credentials',
    },
]

const AdminAuditSecurity = () => {
    const [logs] = useState<AuditLog[]>(mockAuditLogs)
    const [searchTerm, setSearchTerm] = useState('')
    const [filterStatus, setFilterStatus] = useState<string>('all')

    const filteredLogs = logs.filter((log) => {
        const matchesSearch =
            log.action.toLowerCase().includes(searchTerm.toLowerCase()) ||
            log.userEmail.toLowerCase().includes(searchTerm.toLowerCase()) ||
            log.resource.toLowerCase().includes(searchTerm.toLowerCase())
        const matchesStatus = filterStatus === 'all' || log.status === filterStatus
        return matchesSearch && matchesStatus
    })

    const getStatusColor = (status: AuditLog['status']) => {
        switch (status) {
            case 'success':
                return 'green'
            case 'failure':
                return 'red'
            case 'warning':
                return 'yellow'
        }
    }

    const exportLogs = () => {
        const csv = [
            ['Timestamp', 'Action', 'User', 'Resource', 'IP', 'Status', 'Details'],
            ...filteredLogs.map((log) => [
                log.timestamp,
                log.action,
                log.userEmail,
                log.resource,
                log.ipAddress,
                log.status,
                log.details || '',
            ]),
        ]
            .map((row) => row.join(','))
            .join('\n')

        const blob = new Blob([csv], { type: 'text/csv' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `audit-logs-${new Date().toISOString().split('T')[0]}.csv`
        a.click()
    }

    return (
        <Box p={6}>
            <VStack align="start" mb={8} gap={2}>
                <Heading size="xl">Audit & Security</Heading>
                <Text color="gray.600">
                    Monitor security events and audit trails
                </Text>
            </VStack>

            {/* Security Overview */}
            <HStack gap={4} mb={6} flexWrap="wrap">
                <Card.Root bg="green.50" borderColor="green.200" border="1px">
                    <Card.Body p={4}>
                        <Text fontSize="sm" color="green.700">
                            Successful Logins (24h)
                        </Text>
                        <Text fontSize="2xl" fontWeight="bold" color="green.600">
                            142
                        </Text>
                    </Card.Body>
                </Card.Root>
                <Card.Root bg="red.50" borderColor="red.200" border="1px">
                    <Card.Body p={4}>
                        <Text fontSize="sm" color="red.700">
                            Failed Logins (24h)
                        </Text>
                        <Text fontSize="2xl" fontWeight="bold" color="red.600">
                            3
                        </Text>
                    </Card.Body>
                </Card.Root>
                <Card.Root bg="yellow.50" borderColor="yellow.200" border="1px">
                    <Card.Body p={4}>
                        <Text fontSize="sm" color="yellow.700">
                            Rate Limit Events
                        </Text>
                        <Text fontSize="2xl" fontWeight="bold" color="yellow.600">
                            7
                        </Text>
                    </Card.Body>
                </Card.Root>
                <Card.Root bg="blue.50" borderColor="blue.200" border="1px">
                    <Card.Body p={4}>
                        <Text fontSize="sm" color="blue.700">
                            API Requests (24h)
                        </Text>
                        <Text fontSize="2xl" fontWeight="bold" color="blue.600">
                            2,847
                        </Text>
                    </Card.Body>
                </Card.Root>
            </HStack>

            {/* Filters */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg" mb={6}>
                <Card.Body p={4}>
                    <HStack gap={4} flexWrap="wrap">
                        <Input
                            placeholder="Search logs..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            maxW="300px"
                        />
                        <HStack gap={2}>
                            {['all', 'success', 'failure', 'warning'].map((status) => (
                                <Button
                                    key={status}
                                    size="sm"
                                    variant={filterStatus === status ? 'solid' : 'outline'}
                                    colorScheme={
                                        status === 'all'
                                            ? 'gray'
                                            : status === 'success'
                                            ? 'green'
                                            : status === 'failure'
                                            ? 'red'
                                            : 'yellow'
                                    }
                                    onClick={() => setFilterStatus(status)}
                                >
                                    {status.charAt(0).toUpperCase() + status.slice(1)}
                                </Button>
                            ))}
                        </HStack>
                        <Button size="sm" colorScheme="blue" onClick={exportLogs}>
                            Export CSV
                        </Button>
                    </HStack>
                </Card.Body>
            </Card.Root>

            {/* Audit Logs Table */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg">
                <Card.Body p={0}>
                    <Box overflowX="auto">
                        <Table.Root>
                            <Table.Header>
                                <Table.Row>
                                    <Table.ColumnHeader>Timestamp</Table.ColumnHeader>
                                    <Table.ColumnHeader>Action</Table.ColumnHeader>
                                    <Table.ColumnHeader>User</Table.ColumnHeader>
                                    <Table.ColumnHeader>Resource</Table.ColumnHeader>
                                    <Table.ColumnHeader>IP Address</Table.ColumnHeader>
                                    <Table.ColumnHeader>Status</Table.ColumnHeader>
                                    <Table.ColumnHeader>Details</Table.ColumnHeader>
                                </Table.Row>
                            </Table.Header>
                            <Table.Body>
                                {filteredLogs.map((log) => (
                                    <Table.Row key={log.id}>
                                        <Table.Cell fontSize="sm">
                                            {new Date(log.timestamp).toLocaleString()}
                                        </Table.Cell>
                                        <Table.Cell fontWeight="medium">{log.action}</Table.Cell>
                                        <Table.Cell fontSize="sm">{log.userEmail}</Table.Cell>
                                        <Table.Cell fontSize="sm" fontFamily="mono">
                                            {log.resource}
                                        </Table.Cell>
                                        <Table.Cell fontSize="sm" fontFamily="mono">
                                            {log.ipAddress}
                                        </Table.Cell>
                                        <Table.Cell>
                                            <Badge colorPalette={getStatusColor(log.status)}>
                                                {log.status}
                                            </Badge>
                                        </Table.Cell>
                                        <Table.Cell fontSize="sm" color="gray.600">
                                            {log.details || '-'}
                                        </Table.Cell>
                                    </Table.Row>
                                ))}
                            </Table.Body>
                        </Table.Root>
                    </Box>
                </Card.Body>
            </Card.Root>
        </Box>
    )
}

export default AdminAuditSecurity
