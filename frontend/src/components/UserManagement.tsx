/**
 * User Management Component
 * Admin interface for managing users
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

interface User {
    id: string
    email: string
    name: string
    tier: 'free' | 'premium' | 'enterprise'
    status: 'active' | 'inactive' | 'suspended'
    createdAt: string
    lastLogin: string
    workoutCount: number
}

const mockUsers: User[] = [
    {
        id: '1',
        email: 'john.doe@example.com',
        name: 'John Doe',
        tier: 'premium',
        status: 'active',
        createdAt: '2024-01-15',
        lastLogin: '2024-06-20',
        workoutCount: 45,
    },
    {
        id: '2',
        email: 'jane.smith@example.com',
        name: 'Jane Smith',
        tier: 'free',
        status: 'active',
        createdAt: '2024-02-20',
        lastLogin: '2024-06-19',
        workoutCount: 12,
    },
    {
        id: '3',
        email: 'bob.wilson@example.com',
        name: 'Bob Wilson',
        tier: 'enterprise',
        status: 'active',
        createdAt: '2024-01-05',
        lastLogin: '2024-06-20',
        workoutCount: 89,
    },
    {
        id: '4',
        email: 'alice.brown@example.com',
        name: 'Alice Brown',
        tier: 'premium',
        status: 'suspended',
        createdAt: '2023-12-10',
        lastLogin: '2024-05-15',
        workoutCount: 23,
    },
    {
        id: '5',
        email: 'charlie.davis@example.com',
        name: 'Charlie Davis',
        tier: 'free',
        status: 'inactive',
        createdAt: '2024-03-01',
        lastLogin: '2024-04-10',
        workoutCount: 3,
    },
]

const UserManagement = () => {
    const [users] = useState<User[]>(mockUsers)
    const [searchTerm, setSearchTerm] = useState('')
    const [filterTier, setFilterTier] = useState<string>('all')
    const [filterStatus, setFilterStatus] = useState<string>('all')

    const filteredUsers = users.filter((user) => {
        const matchesSearch =
            user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
            user.name.toLowerCase().includes(searchTerm.toLowerCase())
        const matchesTier = filterTier === 'all' || user.tier === filterTier
        const matchesStatus = filterStatus === 'all' || user.status === filterStatus
        return matchesSearch && matchesTier && matchesStatus
    })

    const getTierColor = (tier: User['tier']) => {
        switch (tier) {
            case 'free':
                return 'gray'
            case 'premium':
                return 'blue'
            case 'enterprise':
                return 'purple'
        }
    }

    const getStatusColor = (status: User['status']) => {
        switch (status) {
            case 'active':
                return 'green'
            case 'inactive':
                return 'yellow'
            case 'suspended':
                return 'red'
        }
    }

    const handleUserAction = (userId: string, action: string) => {
        // In production, this would call the API
        alert(`Action "${action}" on user ${userId}. (Demo)`)
    }

    // Stats
    const totalUsers = users.length
    const activeUsers = users.filter((u) => u.status === 'active').length
    const premiumUsers = users.filter((u) => u.tier !== 'free').length

    return (
        <Box p={6}>
            <VStack align="start" mb={8} gap={2}>
                <Heading size="xl">User Management</Heading>
                <Text color="gray.600">
                    Manage user accounts and subscriptions
                </Text>
            </VStack>

            {/* Stats */}
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
                            Premium/Enterprise
                        </Text>
                        <Text fontSize="2xl" fontWeight="bold" color="blue.500">
                            {premiumUsers}
                        </Text>
                    </Card.Body>
                </Card.Root>
            </HStack>

            {/* Filters */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg" mb={6}>
                <Card.Body p={4}>
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
                            {['all', 'free', 'premium', 'enterprise'].map((tier) => (
                                <Button
                                    key={tier}
                                    size="sm"
                                    variant={filterTier === tier ? 'solid' : 'outline'}
                                    colorScheme={tier === 'all' ? 'gray' : getTierColor(tier as User['tier'])}
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
                                    colorScheme={status === 'all' ? 'gray' : getStatusColor(status as User['status'])}
                                    onClick={() => setFilterStatus(status)}
                                >
                                    {status.charAt(0).toUpperCase() + status.slice(1)}
                                </Button>
                            ))}
                        </HStack>
                    </HStack>
                </Card.Body>
            </Card.Root>

            {/* Users Table */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg">
                <Card.Body p={0}>
                    <Box overflowX="auto">
                        <Table.Root>
                            <Table.Header>
                                <Table.Row>
                                    <Table.ColumnHeader>User</Table.ColumnHeader>
                                    <Table.ColumnHeader>Tier</Table.ColumnHeader>
                                    <Table.ColumnHeader>Status</Table.ColumnHeader>
                                    <Table.ColumnHeader>Workouts</Table.ColumnHeader>
                                    <Table.ColumnHeader>Last Login</Table.ColumnHeader>
                                    <Table.ColumnHeader>Actions</Table.ColumnHeader>
                                </Table.Row>
                            </Table.Header>
                            <Table.Body>
                                {filteredUsers.map((user) => (
                                    <Table.Row key={user.id}>
                                        <Table.Cell>
                                            <VStack align="start" gap={0}>
                                                <Text fontWeight="medium">{user.name}</Text>
                                                <Text fontSize="sm" color="gray.500">
                                                    {user.email}
                                                </Text>
                                            </VStack>
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
                                        <Table.Cell>{user.workoutCount}</Table.Cell>
                                        <Table.Cell>
                                            {new Date(user.lastLogin).toLocaleDateString()}
                                        </Table.Cell>
                                        <Table.Cell>
                                            <HStack gap={2}>
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
                                                    onClick={() => handleUserAction(user.id, 'edit')}
                                                >
                                                    Edit
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
                                ))}
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
