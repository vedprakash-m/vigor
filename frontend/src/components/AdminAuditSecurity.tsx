/**
 * Admin Audit & Security Component
 * Displays Decision Receipts and Safety Breaker events
 * Per UX Spec Part V §5.9 - Decision Receipts & Safety Breaker Log
 */

import {
    Badge,
    Box,
    Button,
    Card,
    Heading,
    HStack,
    Input,
    Spinner,
    Table,
    Text,
    VStack,
} from '@chakra-ui/react'
import { useEffect, useState } from 'react'
import { DecisionOutcome, DecisionType } from '../config/adminConfig'
import { AdminAPI, DecisionReceipt, SafetyBreakerEvent } from '../services/adminApi'

const AdminAuditSecurity = () => {
    const [receipts, setReceipts] = useState<DecisionReceipt[]>([])
    const [safetyBreakers, setSafetyBreakers] = useState<SafetyBreakerEvent[]>([])
    const [loading, setLoading] = useState(true)
    const [searchTerm, setSearchTerm] = useState('')
    const [filterOutcome, setFilterOutcome] = useState<string>('all')
    const [activeTab, setActiveTab] = useState<'receipts' | 'safety'>('receipts')

    useEffect(() => {
        const fetchData = async () => {
            try {
                setLoading(true)
                const [receiptData, safetyData] = await Promise.all([
                    AdminAPI.getDecisionReceipts(),
                    AdminAPI.getSafetyBreakerEvents()
                ])
                setReceipts(receiptData)
                setSafetyBreakers(safetyData)
            } catch (err) {
                console.error('Failed to fetch audit data:', err)
            } finally {
                setLoading(false)
            }
        }
        fetchData()
    }, [])

    const filteredReceipts = receipts.filter((receipt) => {
        const matchesSearch =
            receipt.userId.toLowerCase().includes(searchTerm.toLowerCase()) ||
            receipt.decisionType.toLowerCase().includes(searchTerm.toLowerCase())
        const matchesOutcome = filterOutcome === 'all' || receipt.outcome === filterOutcome
        return matchesSearch && matchesOutcome
    })

    const filteredBreakers = safetyBreakers.filter((breaker) => {
        return breaker.userId.toLowerCase().includes(searchTerm.toLowerCase()) ||
            breaker.reason.toLowerCase().includes(searchTerm.toLowerCase())
    })

    const getOutcomeColor = (outcome: DecisionOutcome) => {
        switch (outcome) {
            case DecisionOutcome.ACCEPTED: return 'green'
            case DecisionOutcome.REJECTED: return 'red'
            case DecisionOutcome.MODIFIED: return 'blue'
            case DecisionOutcome.PENDING: return 'yellow'
        }
    }

    const getDecisionTypeLabel = (type: DecisionType) => {
        switch (type) {
            case DecisionType.WORKOUT_MUTATION: return 'Workout Mutation'
            case DecisionType.SCHEDULE_CHANGE: return 'Schedule Change'
            case DecisionType.REST_DAY: return 'Rest Day'
            case DecisionType.INTENSITY_ADJUSTMENT: return 'Intensity Adj.'
        }
    }

    const exportDecisionReceipts = () => {
        const csv = [
            ['ID', 'Timestamp', 'User', 'Type', 'Confidence', 'Outcome', 'Alternatives', 'Context'],
            ...filteredReceipts.map((r) => [
                r.id,
                r.timestamp,
                r.userId,
                r.decisionType,
                `${(r.confidence * 100).toFixed(1)}%`,
                r.outcome,
                r.alternativesConsidered.toString(),
                r.contextSnapshot.substring(0, 100)
            ]),
        ]
            .map((row) => row.map(c => `"${c}"`).join(','))
            .join('\n')

        const blob = new Blob([csv], { type: 'text/csv' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `decision-receipts-${new Date().toISOString().split('T')[0]}.csv`
        a.click()
    }

    if (loading) {
        return (
            <Box p={6} display="flex" justifyContent="center" alignItems="center" minH="400px">
                <VStack gap={4}>
                    <Spinner size="xl" color="orange.500" />
                    <Text color="gray.600">Loading audit data...</Text>
                </VStack>
            </Box>
        )
    }

    // Stats
    const totalDecisions = receipts.length
    const acceptedDecisions = receipts.filter(r => r.outcome === DecisionOutcome.ACCEPTED).length
    const rejectedDecisions = receipts.filter(r => r.outcome === DecisionOutcome.REJECTED).length
    const avgConfidence = receipts.length > 0
        ? (receipts.reduce((sum, r) => sum + r.confidence, 0) / receipts.length * 100).toFixed(1)
        : 0
    const totalBreakers = safetyBreakers.length
    const autoResolvedBreakers = safetyBreakers.filter(b => b.autoResolved).length

    return (
        <Box p={6}>
            <VStack align="start" mb={8} gap={2}>
                <Heading size="xl">Decision Receipts & Safety Log</Heading>
                <Text color="gray.600">
                    Full audit trail of Ghost decisions with context and alternatives
                </Text>
            </VStack>

            {/* Stats Overview */}
            <HStack gap={4} mb={6} flexWrap="wrap">
                <Card.Root bg="blue.50" borderColor="blue.200" border="1px">
                    <Card.Body p={4}>
                        <Text fontSize="sm" color="blue.700">Total Decisions</Text>
                        <Text fontSize="2xl" fontWeight="bold" color="blue.600">
                            {totalDecisions}
                        </Text>
                    </Card.Body>
                </Card.Root>
                <Card.Root bg="green.50" borderColor="green.200" border="1px">
                    <Card.Body p={4}>
                        <Text fontSize="sm" color="green.700">Accepted</Text>
                        <Text fontSize="2xl" fontWeight="bold" color="green.600">
                            {acceptedDecisions}
                        </Text>
                    </Card.Body>
                </Card.Root>
                <Card.Root bg="red.50" borderColor="red.200" border="1px">
                    <Card.Body p={4}>
                        <Text fontSize="sm" color="red.700">Rejected</Text>
                        <Text fontSize="2xl" fontWeight="bold" color="red.600">
                            {rejectedDecisions}
                        </Text>
                    </Card.Body>
                </Card.Root>
                <Card.Root bg="purple.50" borderColor="purple.200" border="1px">
                    <Card.Body p={4}>
                        <Text fontSize="sm" color="purple.700">Avg Confidence</Text>
                        <Text fontSize="2xl" fontWeight="bold" color="purple.600">
                            {avgConfidence}%
                        </Text>
                    </Card.Body>
                </Card.Root>
                <Card.Root bg="orange.50" borderColor="orange.200" border="1px">
                    <Card.Body p={4}>
                        <Text fontSize="sm" color="orange.700">Safety Breakers</Text>
                        <Text fontSize="2xl" fontWeight="bold" color="orange.600">
                            {totalBreakers}
                        </Text>
                        <Text fontSize="xs" color="orange.500">
                            {autoResolvedBreakers} auto-resolved
                        </Text>
                    </Card.Body>
                </Card.Root>
            </HStack>

            {/* Tab Switcher */}
            <HStack gap={2} mb={6}>
                <Button
                    size="md"
                    variant={activeTab === 'receipts' ? 'solid' : 'outline'}
                    colorScheme="blue"
                    onClick={() => setActiveTab('receipts')}
                >
                    Decision Receipts ({receipts.length})
                </Button>
                <Button
                    size="md"
                    variant={activeTab === 'safety' ? 'solid' : 'outline'}
                    colorScheme="orange"
                    onClick={() => setActiveTab('safety')}
                >
                    Safety Breaker Log ({safetyBreakers.length})
                </Button>
            </HStack>

            {/* Filters */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg" mb={6}>
                <Card.Body p={4}>
                    <HStack gap={4} flexWrap="wrap">
                        <Input
                            placeholder="Search by user or type..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            maxW="300px"
                        />
                        {activeTab === 'receipts' && (
                            <HStack gap={2}>
                                {['all', DecisionOutcome.ACCEPTED, DecisionOutcome.REJECTED, DecisionOutcome.MODIFIED].map((outcome) => (
                                    <Button
                                        key={outcome}
                                        size="sm"
                                        variant={filterOutcome === outcome ? 'solid' : 'outline'}
                                        colorScheme={outcome === 'all' ? 'gray' : getOutcomeColor(outcome as DecisionOutcome)}
                                        onClick={() => setFilterOutcome(outcome)}
                                    >
                                        {outcome === 'all' ? 'All' : outcome}
                                    </Button>
                                ))}
                            </HStack>
                        )}
                        <Button size="sm" colorScheme="blue" onClick={exportDecisionReceipts}>
                            Export CSV
                        </Button>
                    </HStack>
                </Card.Body>
            </Card.Root>

            {/* Decision Receipts Table */}
            {activeTab === 'receipts' && (
                <Card.Root bg="white" shadow="sm" borderRadius="lg">
                    <Card.Body p={0}>
                        <Box overflowX="auto">
                            <Table.Root size="sm">
                                <Table.Header>
                                    <Table.Row>
                                        <Table.ColumnHeader>Timestamp</Table.ColumnHeader>
                                        <Table.ColumnHeader>User</Table.ColumnHeader>
                                        <Table.ColumnHeader>Decision Type</Table.ColumnHeader>
                                        <Table.ColumnHeader>Confidence</Table.ColumnHeader>
                                        <Table.ColumnHeader>Alternatives</Table.ColumnHeader>
                                        <Table.ColumnHeader>Outcome</Table.ColumnHeader>
                                        <Table.ColumnHeader>Context</Table.ColumnHeader>
                                    </Table.Row>
                                </Table.Header>
                                <Table.Body>
                                    {filteredReceipts.map((receipt) => (
                                        <Table.Row key={receipt.id}>
                                            <Table.Cell fontSize="xs">
                                                {new Date(receipt.timestamp).toLocaleString()}
                                            </Table.Cell>
                                            <Table.Cell fontSize="sm">{receipt.userId}</Table.Cell>
                                            <Table.Cell>
                                                <Badge colorPalette="blue">
                                                    {getDecisionTypeLabel(receipt.decisionType)}
                                                </Badge>
                                            </Table.Cell>
                                            <Table.Cell>
                                                <Text
                                                    fontWeight="medium"
                                                    color={receipt.confidence >= 0.8 ? 'green.600' : receipt.confidence >= 0.6 ? 'yellow.600' : 'orange.600'}
                                                >
                                                    {(receipt.confidence * 100).toFixed(0)}%
                                                </Text>
                                            </Table.Cell>
                                            <Table.Cell>
                                                {receipt.alternativesConsidered}
                                            </Table.Cell>
                                            <Table.Cell>
                                                <Badge colorPalette={getOutcomeColor(receipt.outcome)}>
                                                    {receipt.outcome}
                                                </Badge>
                                            </Table.Cell>
                                            <Table.Cell fontSize="xs" color="gray.600" maxW="200px">
                                                <Text lineClamp={2}>{receipt.contextSnapshot}</Text>
                                            </Table.Cell>
                                        </Table.Row>
                                    ))}
                                </Table.Body>
                            </Table.Root>
                        </Box>
                    </Card.Body>
                </Card.Root>
            )}

            {/* Safety Breaker Log Table */}
            {activeTab === 'safety' && (
                <Card.Root bg="white" shadow="sm" borderRadius="lg">
                    <Card.Body p={0}>
                        <Box overflowX="auto">
                            <Table.Root size="sm">
                                <Table.Header>
                                    <Table.Row>
                                        <Table.ColumnHeader>Timestamp</Table.ColumnHeader>
                                        <Table.ColumnHeader>User</Table.ColumnHeader>
                                        <Table.ColumnHeader>Breaker Type</Table.ColumnHeader>
                                        <Table.ColumnHeader>Reason</Table.ColumnHeader>
                                        <Table.ColumnHeader>Status</Table.ColumnHeader>
                                    </Table.Row>
                                </Table.Header>
                                <Table.Body>
                                    {filteredBreakers.map((breaker) => (
                                        <Table.Row key={breaker.id}>
                                            <Table.Cell fontSize="xs">
                                                {new Date(breaker.timestamp).toLocaleString()}
                                            </Table.Cell>
                                            <Table.Cell fontSize="sm">{breaker.userId}</Table.Cell>
                                            <Table.Cell>
                                                <Badge colorPalette="orange">
                                                    {breaker.breakerType}
                                                </Badge>
                                            </Table.Cell>
                                            <Table.Cell fontSize="sm" maxW="300px">
                                                <Text lineClamp={2}>{breaker.reason}</Text>
                                            </Table.Cell>
                                            <Table.Cell>
                                                <Badge colorPalette={breaker.autoResolved ? 'green' : 'yellow'}>
                                                    {breaker.autoResolved ? 'Auto-Resolved' : 'Manual Review'}
                                                </Badge>
                                            </Table.Cell>
                                        </Table.Row>
                                    ))}
                                </Table.Body>
                            </Table.Root>
                        </Box>
                    </Card.Body>
                </Card.Root>
            )}

            {/* Info Note */}
            <Card.Root bg="gray.50" borderRadius="lg" mt={6}>
                <Card.Body p={4}>
                    <Text fontSize="sm" color="gray.600">
                        <strong>Decision Receipts</strong> provide full transparency into Ghost's decision-making
                        process. Each receipt includes the context used, alternatives considered, and confidence
                        level. <strong>Safety Breakers</strong> are triggered when Ghost detects potentially
                        harmful patterns like overtraining or injury risk.
                    </Text>
                </Card.Body>
            </Card.Root>
        </Box>
    )
}

export default AdminAuditSecurity
