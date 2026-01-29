/**
 * User Management Component
 * Admin interface for managing users with Ghost-specific data
 * Per UX Spec Part V §5.6 - User Management with Trust Visualization
 */

import {
    Badge,
    Box,
    Button,
    Card,
    Heading,
    HStack,
    Input,
    Progress,
    Spinner,
    Table,
    Text,
    VStack
} from '@chakra-ui/react'
import { useEffect, useState } from 'react'
import { AdminAPI, AdminUser } from '../services/adminApi'

// Trust phases as string array for iteration
const TRUST_PHASES = ['Observer', 'Scheduler', 'Auto-Scheduler', 'Transformer', 'Full Ghost'] as const

// Trust phase colors aligned with spec
const getTrustPhaseColor = (phase: string): string => {
    switch (phase) {
        case 'Observer':
            return 'gray'
        case 'Scheduler':
            return 'blue'
        case 'Auto-Scheduler':
            return 'cyan'
        case 'Transformer':
            return 'purple'
        case 'Full Ghost':
            return 'green'
        default:
            return 'gray'
    }
}

const getTierColor = (tier: AdminUser['tier']) => {
    switch (tier) {
        case 'free':
            return 'gray'
        case 'premium':
            return 'blue'
        default:
            return 'gray'
    }
}

const getStatusColor = (status: AdminUser['status']) => {
    switch (status) {
        case 'active':
            return 'green'
        case 'inactive':
            return 'yellow'
        case 'suspended':
            return 'red'
        default:
            return 'gray'
    }
}

// Helper to format phenome freshness
const formatPhenomeFreshness = (hours: number): { label: string; color: string } => {
    if (hours < 1) return { label: 'Just now', color: 'green' }
    if (hours < 6) return { label: `${hours}h ago`, color: 'green' }
    if (hours < 24) return { label: `${hours}h ago`, color: 'yellow' }
    if (hours < 72) return { label: `${Math.floor(hours / 24)}d ago`, color: 'orange' }
    return { label: `${Math.floor(hours / 24)}d ago`, color: 'red' }
}

const UserManagement = () => {
    const [users, setUsers] = useState<AdminUser[]>([])
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)
    const [searchTerm, setSearchTerm] = useState('')
    const [filterTier, setFilterTier] = useState<string>('all')
    const [filterStatus, setFilterStatus] = useState<string>('all')
    const [filterTrustPhase, setFilterTrustPhase] = useState<string>('all')

    // Fetch users from API
    useEffect(() => {
        const fetchUsers = async () => {
            try {
                setLoading(true)
                const data = await AdminAPI.getUsers()
                setUsers(data)
                setError(null)
            } catch (err) {
                setError('Failed to load users')
                console.error('Error fetching users:', err)
            } finally {
                setLoading(false)
            }
        }
        fetchUsers()
    }, [])

    // Filtered users with Trust Phase filter
    const filteredUsers = users.filter((user) => {
        const matchesSearch =
            user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
            user.name.toLowerCase().includes(searchTerm.toLowerCase())
        const matchesTier = filterTier === 'all' || user.tier === filterTier
        const matchesStatus = filterStatus === 'all' || user.status === filterStatus
        const matchesTrustPhase = filterTrustPhase === 'all' || user.trustPhase === filterTrustPhase
        return matchesSearch && matchesTier && matchesStatus && matchesTrustPhase
    })

    const handleUserAction = (userId: string, action: string) => {
        // In production, this would call the API
        alert(`Action "${action}" on user ${userId}. (Demo - API integration pending)`)
    }

    // Stats - Ghost-specific
    const totalUsers = users.length
    const activeUsers = users.filter((u) => u.status === 'active').length
    const premiumUsers = users.filter((u) => u.tier === 'premium').length
    const watchConnected = users.filter((u) => u.watchStatus === 'CONNECTED').length
    const fullGhostUsers = users.filter((u) => u.trustPhase === 'Full Ghost').length

    if (loading) {
        return (
            <Box p={6} display="flex" justifyContent="center" alignItems="center" minH="400px">
                <VStack gap={4}>
                    <Spinner size="xl" color="orange.500" />
                    <Text color="gray.600">Loading users...</Text>
                </VStack>
            </Box>
        )
    }

    if (error) {
        return (
            <Box p={6}>
                <Card.Root bg="red.50" borderColor="red.200" borderWidth="1px">
                    <Card.Body p={6}>
                        <Text color="red.600" fontWeight="medium">{error}</Text>
                        <Button mt={4} colorScheme="red" variant="outline" onClick={() => window.location.reload()}>
                            Retry
                        </Button>
                    </Card.Body>
                </Card.Root>
            </Box>
        )
    }

    return (
        <Box p={6}>
            <VStack align="start" mb={8} gap={2}>
                <Heading size="xl">User Management</Heading>
                <Text color="gray.600">
                    Manage user accounts, Trust phases, and Ghost subscriptions
                </Text>
            </VStack>

            {/* Stats - Ghost-specific */}
            <HStack gap={4} mb={6} flexWrap="wrap">
                <Card.Root bg="white" shadow="sm" borderRadius="lg">
                    <Card.Body p={4}>
                        <Text fontSize="sm" color="gray.500">
                            Total Users
                        </Text>
                        <Text fontSize="2xl" fontWeight="bold">
                            {totalUsers}
                        </Text>
                    </Card.Body>
                </Card.Root>
                <Card.Root bg="white" shadow="sm" borderRadius="lg">
                    <Card.Body p={4}>
                        <Text fontSize="sm" color="gray.500">
                            Active Users
                        </Text>
                        <Text fontSize="2xl" fontWeight="bold" color="green.500">
                            {activeUsers}
                        </Text>
                    </Card.Body>
                </Card.Root>
                <Card.Root bg="white" shadow="sm" borderRadius="lg">
                    <Card.Body p={4}>
                        <Text fontSize="sm" color="gray.500">
                            Premium
                        </Text>
                        <Text fontSize="2xl" fontWeight="bold" color="blue.500">
                            {premiumUsers}
                        </Text>
                    </Card.Body>
                </Card.Root>
                <Card.Root bg="white" shadow="sm" borderRadius="lg">
                    <Card.Body p={4}>
                        <Text fontSize="sm" color="gray.500">
                            Watch Connected
                        </Text>
                        <Text fontSize="2xl" fontWeight="bold" color="purple.500">
                            {watchConnected}
                        </Text>
                    </Card.Body>
                </Card.Root>
                <Card.Root bg="white" shadow="sm" borderRadius="lg">
                    <Card.Body p={4}>
                        <Text fontSize="sm" color="gray.500">
                            Full Ghost
                        </Text>
                        <Text fontSize="2xl" fontWeight="bold" color="green.600">
                            {fullGhostUsers}
                        </Text>
                    </Card.Body>
                </Card.Root>
            </HStack>

            {/* Filters */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg" mb={6}>
                <Card.Body p={4}>
                    <VStack gap={4} align="stretch">
                        <HStack gap={4} flexWrap="wrap">
                            <Input
                                placeholder="Search by name or email..."
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                                maxW="300px"
                            />
                            <HStack gap={2}>
                                <Text fontSize="sm" color="gray.600">
                                    Tier:
                                </Text>
                                {['all', 'free', 'premium'].map((tier) => (
                                    <Button
                                        key={tier}
                                        size="sm"
                                        variant={filterTier === tier ? 'solid' : 'outline'}
                                        colorScheme={tier === 'all' ? 'gray' : getTierColor(tier as AdminUser['tier'])}
                                        onClick={() => setFilterTier(tier)}
                                    >
                                        {tier.charAt(0).toUpperCase() + tier.slice(1)}
                                    </Button>
                                ))}
                            </HStack>
                            <HStack gap={2}>
                                <Text fontSize="sm" color="gray.600">
                                    Status:
                                </Text>
                                {['all', 'active', 'inactive', 'suspended'].map((status) => (
                                    <Button
                                        key={status}
                                        size="sm"
                                        variant={filterStatus === status ? 'solid' : 'outline'}
                                        colorScheme={status === 'all' ? 'gray' : getStatusColor(status as AdminUser['status'])}
                                        onClick={() => setFilterStatus(status)}
                                    >
                                        {status.charAt(0).toUpperCase() + status.slice(1)}
                                    </Button>
                                ))}
                            </HStack>
                        </HStack>
                        <HStack gap={2} flexWrap="wrap">
                            <Text fontSize="sm" color="gray.600">
                                Trust Phase:
                            </Text>
                            <Button
                                size="sm"
                                variant={filterTrustPhase === 'all' ? 'solid' : 'outline'}
                                colorScheme="gray"
                                onClick={() => setFilterTrustPhase('all')}
                            >
                                All
                            </Button>
                            {TRUST_PHASES.map((phase) => (
                                <Button
                                    key={phase}
                                    size="sm"
                                    variant={filterTrustPhase === phase ? 'solid' : 'outline'}
                                    colorScheme={getTrustPhaseColor(phase)}
                                    onClick={() => setFilterTrustPhase(phase)}
                                >
                                    {phase}
                                </Button>
                            ))}
                        </HStack>
                    </VStack>
                </Card.Body>
            </Card.Root>

            {/* Users Table - Ghost-specific columns */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg">
                <Card.Body p={0}>
                    <Box overflowX="auto">
                        <Table.Root size="sm">
                            <Table.Header>
                                <Table.Row>
                                    <Table.ColumnHeader>User</Table.ColumnHeader>
                                    <Table.ColumnHeader>Trust Phase</Table.ColumnHeader>
                                    <Table.ColumnHeader>Trust Score</Table.ColumnHeader>
                                    <Table.ColumnHeader>Watch</Table.ColumnHeader>
                                    <Table.ColumnHeader>Phenome</Table.ColumnHeader>
                                    <Table.ColumnHeader>Tier</Table.ColumnHeader>
                                    <Table.ColumnHeader>Status</Table.ColumnHeader>
                                    <Table.ColumnHeader>Actions</Table.ColumnHeader>
                                </Table.Row>
                            </Table.Header>
                            <Table.Body>
                                {filteredUsers.map((user) => {
                                    const hoursAgo = user.phenomeFreshness?.lastSync
                                        ? Math.floor((Date.now() - new Date(user.phenomeFreshness.lastSync).getTime()) / 3600000)
                                        : Infinity
                                    const phenomeFreshnessDisplay = formatPhenomeFreshness(hoursAgo)
                                    return (
                                        <Table.Row key={user.id}>
                                            <Table.Cell>
                                                <VStack align="start" gap={0}>
                                                    <Text fontWeight="medium">{user.name}</Text>
                                                    <Text fontSize="xs" color="gray.500">
                                                        {user.email}
                                                    </Text>
                                                </VStack>
                                            </Table.Cell>
                                            <Table.Cell>
                                                <Badge colorPalette={getTrustPhaseColor(user.trustPhase)}>
                                                    {user.trustPhase}
                                                </Badge>
                                            </Table.Cell>
                                            <Table.Cell>
                                                <VStack align="start" gap={1}>
                                                    <Text fontSize="sm" fontWeight="medium">
                                                        {user.trustScore}%
                                                    </Text>
                                                    <Progress.Root
                                                        value={user.trustScore}
                                                        size="xs"
                                                        w="60px"
                                                        colorPalette={user.trustScore >= 80 ? 'green' : user.trustScore >= 50 ? 'yellow' : 'red'}
                                                    >
                                                        <Progress.Track>
                                                            <Progress.Range />
                                                        </Progress.Track>
                                                    </Progress.Root>
                                                </VStack>
                                            </Table.Cell>
                                            <Table.Cell>
                                                <Badge colorPalette={user.watchStatus === 'CONNECTED' ? 'green' : 'gray'}>
                                                    {user.watchStatus === 'CONNECTED' ? '⌚ Connected' : 'Not Connected'}
                                                </Badge>
                                            </Table.Cell>
                                            <Table.Cell>
                                                <Badge colorPalette={phenomeFreshnessDisplay.color}>
                                                    {phenomeFreshnessDisplay.label}
                                                </Badge>
                                            </Table.Cell>
                                            <Table.Cell>
                                                <Badge colorPalette={getTierColor(user.tier)}>
                                                    {user.tier}
                                                </Badge>
                                            </Table.Cell>
                                            <Table.Cell>
                                                <Badge colorPalette={getStatusColor(user.status)}>
                                                    {user.status}
                                                </Badge>
                                            </Table.Cell>
                                            <Table.Cell>
                                                <HStack gap={1}>
                                                    <Button
                                                        size="xs"
                                                        variant="ghost"
                                                        onClick={() => handleUserAction(user.id, 'view')}
                                                    >
                                                        View
                                                    </Button>
                                                    <Button
                                                        size="xs"
                                                        variant="ghost"
                                                        onClick={() => handleUserAction(user.id, 'phenome')}
                                                    >
                                                        Phenome
                                                    </Button>
                                                    {user.status === 'suspended' ? (
                                                        <Button
                                                            size="xs"
                                                            colorScheme="green"
                                                            variant="ghost"
                                                            onClick={() => handleUserAction(user.id, 'activate')}
                                                        >
                                                            Activate
                                                        </Button>
                                                    ) : (
                                                        <Button
                                                            size="xs"
                                                            colorScheme="red"
                                                            variant="ghost"
                                                            onClick={() => handleUserAction(user.id, 'suspend')}
                                                        >
                                                            Suspend
                                                        </Button>
                                                    )}
                                                </HStack>
                                            </Table.Cell>
                                        </Table.Row>
                                    )
                                })}
                            </Table.Body>
                        </Table.Root>
                    </Box>
                </Card.Body>
            </Card.Root>

            <Text mt={4} fontSize="sm" color="gray.500">
                Showing {filteredUsers.length} of {users.length} users
            </Text>
        </Box>
    )
}

export default UserManagement
