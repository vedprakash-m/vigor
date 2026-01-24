/**
 * Bulk User Operations Component
 * Admin tool for performing bulk operations on users
 */

import {
    Badge,
    Box,
    Button,
    Card,
    Checkbox,
    Heading,
    HStack,
    Input,
    Table,
    Text,
    Textarea,
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
}

const mockUsers: User[] = [
    {
        id: '1',
        email: 'john@example.com',
        name: 'John Doe',
        tier: 'premium',
        status: 'active',
        createdAt: '2024-01-15',
    },
    {
        id: '2',
        email: 'jane@example.com',
        name: 'Jane Smith',
        tier: 'free',
        status: 'active',
        createdAt: '2024-02-20',
    },
    {
        id: '3',
        email: 'bob@example.com',
        name: 'Bob Wilson',
        tier: 'enterprise',
        status: 'active',
        createdAt: '2024-01-05',
    },
    {
        id: '4',
        email: 'alice@example.com',
        name: 'Alice Brown',
        tier: 'premium',
        status: 'suspended',
        createdAt: '2023-12-10',
    },
]

type BulkAction = 'upgrade' | 'downgrade' | 'suspend' | 'activate' | 'notify' | 'delete'

const BulkUserOperations = () => {
    const [users] = useState<User[]>(mockUsers)
    const [selectedUsers, setSelectedUsers] = useState<Set<string>>(new Set())
    const [searchTerm, setSearchTerm] = useState('')
    const [selectedAction, setSelectedAction] = useState<BulkAction | null>(null)
    const [notificationMessage, setNotificationMessage] = useState('')

    const filteredUsers = users.filter(
        (user) =>
            user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
            user.name.toLowerCase().includes(searchTerm.toLowerCase())
    )

    const toggleUser = (userId: string) => {
        const newSelected = new Set(selectedUsers)
        if (newSelected.has(userId)) {
            newSelected.delete(userId)
        } else {
            newSelected.add(userId)
        }
        setSelectedUsers(newSelected)
    }

    const toggleAll = () => {
        if (selectedUsers.size === filteredUsers.length) {
            setSelectedUsers(new Set())
        } else {
            setSelectedUsers(new Set(filteredUsers.map((u) => u.id)))
        }
    }

    const executeAction = () => {
        if (!selectedAction || selectedUsers.size === 0) return

        const actionMessages: Record<BulkAction, string> = {
            upgrade: 'upgrade to premium',
            downgrade: 'downgrade to free tier',
            suspend: 'suspend',
            activate: 'activate',
            notify: 'send notification to',
            delete: 'delete',
        }

        const confirm = window.confirm(
            `Are you sure you want to ${actionMessages[selectedAction]} ${selectedUsers.size} user(s)?`
        )

        if (confirm) {
            // In production, this would call the API
            alert(
                `Successfully executed "${selectedAction}" on ${selectedUsers.size} users. (Demo)`
            )
            setSelectedUsers(new Set())
            setSelectedAction(null)
        }
    }

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

    return (
        <Box p={6}>
            <VStack align="start" mb={8} gap={2}>
                <Heading size="xl">Bulk User Operations</Heading>
                <Text color="gray.600">
                    Perform batch operations on multiple users
                </Text>
            </VStack>

            {/* Search and Actions */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg" mb={6}>
                <Card.Body p={4}>
                    <HStack gap={4} mb={4} flexWrap="wrap">
                        <Input
                            placeholder="Search users..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            maxW="300px"
                        />
                        <Text color="gray.600">
                            {selectedUsers.size} of {filteredUsers.length} selected
                        </Text>
                    </HStack>

                    <HStack gap={2} flexWrap="wrap">
                        {(
                            ['upgrade', 'downgrade', 'suspend', 'activate', 'notify', 'delete'] as BulkAction[]
                        ).map((action) => (
                            <Button
                                key={action}
                                size="sm"
                                variant={selectedAction === action ? 'solid' : 'outline'}
                                colorScheme={
                                    action === 'delete' || action === 'suspend'
                                        ? 'red'
                                        : action === 'upgrade'
                                        ? 'green'
                                        : 'blue'
                                }
                                onClick={() => setSelectedAction(action)}
                                disabled={selectedUsers.size === 0}
                            >
                                {action.charAt(0).toUpperCase() + action.slice(1)}
                            </Button>
                        ))}
                    </HStack>

                    {selectedAction === 'notify' && (
                        <Box mt={4}>
                            <Text fontWeight="medium" mb={2}>
                                Notification Message
                            </Text>
                            <Textarea
                                value={notificationMessage}
                                onChange={(e) => setNotificationMessage(e.target.value)}
                                placeholder="Enter the message to send to selected users..."
                                rows={3}
                            />
                        </Box>
                    )}

                    {selectedAction && selectedUsers.size > 0 && (
                        <HStack mt={4}>
                            <Button colorScheme="blue" onClick={executeAction}>
                                Execute {selectedAction}
                            </Button>
                            <Button
                                variant="ghost"
                                onClick={() => setSelectedAction(null)}
                            >
                                Cancel
                            </Button>
                        </HStack>
                    )}
                </Card.Body>
            </Card.Root>

            {/* Users Table */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg">
                <Card.Body p={0}>
                    <Box overflowX="auto">
                        <Table.Root>
                            <Table.Header>
                                <Table.Row>
                                    <Table.ColumnHeader w="50px">
                                        <Checkbox.Root
                                            checked={selectedUsers.size === filteredUsers.length}
                                            onCheckedChange={toggleAll}
                                        >
                                            <Checkbox.HiddenInput />
                                            <Checkbox.Control />
                                        </Checkbox.Root>
                                    </Table.ColumnHeader>
                                    <Table.ColumnHeader>Name</Table.ColumnHeader>
                                    <Table.ColumnHeader>Email</Table.ColumnHeader>
                                    <Table.ColumnHeader>Tier</Table.ColumnHeader>
                                    <Table.ColumnHeader>Status</Table.ColumnHeader>
                                    <Table.ColumnHeader>Created</Table.ColumnHeader>
                                </Table.Row>
                            </Table.Header>
                            <Table.Body>
                                {filteredUsers.map((user) => (
                                    <Table.Row
                                        key={user.id}
                                        bg={selectedUsers.has(user.id) ? 'blue.50' : undefined}
                                    >
                                        <Table.Cell>
                                            <Checkbox.Root
                                                checked={selectedUsers.has(user.id)}
                                                onCheckedChange={() => toggleUser(user.id)}
                                            >
                                                <Checkbox.HiddenInput />
                                                <Checkbox.Control />
                                            </Checkbox.Root>
                                        </Table.Cell>
                                        <Table.Cell fontWeight="medium">{user.name}</Table.Cell>
                                        <Table.Cell>{user.email}</Table.Cell>
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
                                            {new Date(user.createdAt).toLocaleDateString()}
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

export default BulkUserOperations
