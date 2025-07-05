/**
 * User Management Interface
 * Comprehensive admin interface for managing users, roles, and permissions
 */
import {
    Badge,
    Box,
    Button,
    Container,
    Flex,
    Grid,
    Heading,
    HStack,
    Input,
    Text,
    VStack,
} from '@chakra-ui/react';
import React, { useCallback, useEffect, useState } from 'react';
import {
    FiActivity,
    FiCalendar,
    FiDownload,
    FiEdit,
    FiMail,
    FiShield,
    FiTrash2,
    FiUserPlus,
    FiUsers
} from 'react-icons/fi';

interface User {
    id: string;
    email: string;
    firstName: string;
    lastName: string;
    role: 'admin' | 'premium' | 'basic';
    status: 'active' | 'inactive' | 'suspended';
    lastLogin: Date | null;
    createdAt: Date;
    totalWorkouts: number;
    tier: string;
    subscription?: {
        plan: string;
        status: string;
        expiresAt: Date;
    };
}

interface UserStats {
    totalUsers: number;
    activeUsers: number;
    premiumUsers: number;
    newUsersThisMonth: number;
    churnRate: number;
}

const UserManagementSimple: React.FC = () => {
    const [users, setUsers] = useState<User[]>([]);
    const [userStats, setUserStats] = useState<UserStats | null>(null);
    const [isLoading, setIsLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [roleFilter, setRoleFilter] = useState<string>('all');
    const [statusFilter, setStatusFilter] = useState<string>('all');
    const [currentPage, setCurrentPage] = useState(1);
    const [itemsPerPage] = useState(10);

    // Mock data for development
    const loadMockData = useCallback(() => {
        const mockUsers: User[] = [
            {
                id: '1',
                email: 'admin@vigor.com',
                firstName: 'Admin',
                lastName: 'User',
                role: 'admin',
                status: 'active',
                lastLogin: new Date(),
                createdAt: new Date('2024-01-15'),
                totalWorkouts: 0,
                tier: 'Admin',
            },
            {
                id: '2',
                email: 'john.doe@example.com',
                firstName: 'John',
                lastName: 'Doe',
                role: 'premium',
                status: 'active',
                lastLogin: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
                createdAt: new Date('2024-03-10'),
                totalWorkouts: 45,
                tier: 'Premium',
                subscription: {
                    plan: 'Premium Monthly',
                    status: 'active',
                    expiresAt: new Date(Date.now() + 20 * 24 * 60 * 60 * 1000),
                },
            },
            {
                id: '3',
                email: 'jane.smith@example.com',
                firstName: 'Jane',
                lastName: 'Smith',
                role: 'basic',
                status: 'active',
                lastLogin: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
                createdAt: new Date('2024-05-20'),
                totalWorkouts: 12,
                tier: 'Basic',
            },
            {
                id: '4',
                email: 'inactive.user@example.com',
                firstName: 'Inactive',
                lastName: 'User',
                role: 'basic',
                status: 'inactive',
                lastLogin: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
                createdAt: new Date('2024-02-01'),
                totalWorkouts: 3,
                tier: 'Basic',
            },
            {
                id: '5',
                email: 'premium.user@example.com',
                firstName: 'Premium',
                lastName: 'User',
                role: 'premium',
                status: 'active',
                lastLogin: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
                createdAt: new Date('2024-04-15'),
                totalWorkouts: 67,
                tier: 'Premium',
            },
        ];

        const mockStats: UserStats = {
            totalUsers: 247,
            activeUsers: 189,
            premiumUsers: 43,
            newUsersThisMonth: 18,
            churnRate: 0.05,
        };

        setUsers(mockUsers);
        setUserStats(mockStats);
        setIsLoading(false);
    }, []);

    useEffect(() => {
        loadMockData();
    }, [loadMockData]);

    // Filter users based on search and filters
    const filteredUsers = users.filter(user => {
        const matchesSearch =
            user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
            user.firstName.toLowerCase().includes(searchTerm.toLowerCase()) ||
            user.lastName.toLowerCase().includes(searchTerm.toLowerCase());

        const matchesRole = roleFilter === 'all' || user.role === roleFilter;
        const matchesStatus = statusFilter === 'all' || user.status === statusFilter;

        return matchesSearch && matchesRole && matchesStatus;
    });

    // Pagination
    const totalPages = Math.ceil(filteredUsers.length / itemsPerPage);
    const startIndex = (currentPage - 1) * itemsPerPage;
    const paginatedUsers = filteredUsers.slice(startIndex, startIndex + itemsPerPage);

    const getRoleColor = (role: string) => {
        switch (role) {
            case 'admin':
                return 'red';
            case 'premium':
                return 'purple';
            case 'basic':
                return 'blue';
            default:
                return 'gray';
        }
    };

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'active':
                return 'green';
            case 'inactive':
                return 'yellow';
            case 'suspended':
                return 'red';
            default:
                return 'gray';
        }
    };

    const formatDate = (date: Date | null) => {
        if (!date) return 'Never';
        return date.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
        });
    };

    const formatPercentage = (value: number) => {
        return `${(value * 100).toFixed(1)}%`;
    };

    const StatCard = ({ icon, label, value, change }: {
        icon: React.ElementType;
        label: string;
        value: string | number;
        change?: number;
    }) => {
        const IconComponent = icon;
        return (
            <Box
                bg="white"
                p={6}
                borderRadius="lg"
                border="1px"
                borderColor="gray.200"
                shadow="sm"
                _dark={{
                    bg: 'gray.800',
                    borderColor: 'gray.600',
                }}
            >
                <VStack alignItems="flex-start" gap={2}>
                    <HStack>
                        <IconComponent color="blue.500" />
                        <Text fontSize="sm" color="gray.500">{label}</Text>
                    </HStack>
                    <Text fontSize="2xl" fontWeight="bold">{value}</Text>
                    {change !== undefined && (
                        <Text fontSize="sm" color={change >= 0 ? 'green.500' : 'red.500'}>
                            {change >= 0 ? '+' : ''}{change}% from last month
                        </Text>
                    )}
                </VStack>
            </Box>
        );
    };

    const UserCard = ({ user }: { user: User }) => (
        <Box
            bg="white"
            p={6}
            borderRadius="lg"
            border="1px"
            borderColor="gray.200"
            shadow="sm"
            _dark={{
                bg: 'gray.800',
                borderColor: 'gray.600',
            }}
        >
            <VStack alignItems="stretch" gap={4}>
                <HStack justify="space-between">
                    <VStack alignItems="flex-start" gap={1}>
                        <Heading size="sm">{user.firstName} {user.lastName}</Heading>
                        <Text fontSize="sm" color="gray.500">{user.email}</Text>
                    </VStack>
                    <VStack alignItems="flex-end" gap={1}>
                        <Badge colorScheme={getRoleColor(user.role)}>
                            {user.role.toUpperCase()}
                        </Badge>
                        <Badge colorScheme={getStatusColor(user.status)}>
                            {user.status.toUpperCase()}
                        </Badge>
                    </VStack>
                </HStack>

                <Grid templateColumns="repeat(2, 1fr)" gap={4}>
                    <VStack alignItems="flex-start">
                        <Text fontSize="sm" color="gray.500">Workouts</Text>
                        <Text fontWeight="bold">{user.totalWorkouts}</Text>
                    </VStack>
                    <VStack alignItems="flex-start">
                        <Text fontSize="sm" color="gray.500">Tier</Text>
                        <Text fontWeight="bold">{user.tier}</Text>
                    </VStack>
                    <VStack alignItems="flex-start">
                        <Text fontSize="sm" color="gray.500">Last Login</Text>
                        <Text fontSize="sm">{formatDate(user.lastLogin)}</Text>
                    </VStack>
                    <VStack alignItems="flex-start">
                        <Text fontSize="sm" color="gray.500">Member Since</Text>
                        <Text fontSize="sm">{formatDate(user.createdAt)}</Text>
                    </VStack>
                </Grid>

                {user.subscription && (
                    <Box>
                        <Text fontSize="sm" color="gray.500" mb={2}>Subscription</Text>
                        <VStack alignItems="flex-start" gap={1}>
                            <Text fontSize="sm">{user.subscription.plan}</Text>
                            <Text fontSize="sm" color="gray.500">
                                Expires: {formatDate(user.subscription.expiresAt)}
                            </Text>
                        </VStack>
                    </Box>
                )}

                <HStack justify="flex-end" gap={2}>
                    <Button size="sm" variant="outline">
                        <FiEdit style={{ marginRight: '8px' }} />
                        Edit
                    </Button>
                    <Button size="sm" colorScheme="red" variant="outline">
                        <FiTrash2 style={{ marginRight: '8px' }} />
                        Delete
                    </Button>
                </HStack>
            </VStack>
        </Box>
    );

    if (isLoading) {
        return (
            <Container maxW="7xl" py={8}>
                <VStack gap={8}>
                    <Heading>Loading User Management...</Heading>
                </VStack>
            </Container>
        );
    }

    return (
        <Container maxW="7xl" py={8}>
            <VStack gap={8} alignItems="stretch">
                {/* Header */}
                <Flex justify="space-between" align="center">
                    <VStack alignItems="flex-start" gap={1}>
                        <Heading size="lg">User Management</Heading>
                        <Text color="gray.500">
                            Manage users, roles, and permissions
                        </Text>
                    </VStack>

                    <HStack gap={4}>
                        <Button variant="outline">
                            <FiDownload style={{ marginRight: '8px' }} />
                            Export Users
                        </Button>
                        <Button colorScheme="blue">
                            <FiUserPlus style={{ marginRight: '8px' }} />
                            Add User
                        </Button>
                    </HStack>
                </Flex>

                {/* User Statistics */}
                {userStats && (
                    <Box>
                        <Heading size="md" mb={4}>Overview</Heading>
                        <Grid templateColumns="repeat(auto-fit, minmax(200px, 1fr))" gap={6}>
                            <StatCard
                                icon={FiUsers}
                                label="Total Users"
                                value={userStats.totalUsers.toLocaleString()}
                                change={12}
                            />
                            <StatCard
                                icon={FiActivity}
                                label="Active Users"
                                value={userStats.activeUsers.toLocaleString()}
                                change={8}
                            />
                            <StatCard
                                icon={FiShield}
                                label="Premium Users"
                                value={userStats.premiumUsers.toLocaleString()}
                                change={25}
                            />
                            <StatCard
                                icon={FiCalendar}
                                label="New This Month"
                                value={userStats.newUsersThisMonth.toLocaleString()}
                                change={15}
                            />
                            <StatCard
                                icon={FiMail}
                                label="Churn Rate"
                                value={formatPercentage(userStats.churnRate)}
                                change={-2}
                            />
                        </Grid>
                    </Box>
                )}

                {/* Filters and Search */}
                <Box
                    bg="white"
                    p={6}
                    borderRadius="lg"
                    border="1px"
                    borderColor="gray.200"
                    shadow="sm"
                    _dark={{
                        bg: 'gray.800',
                        borderColor: 'gray.600',
                    }}
                >
                    <Grid templateColumns="repeat(auto-fit, minmax(250px, 1fr))" gap={4}>
                        <Box>
                            <Text fontSize="sm" color="gray.500" mb={2}>Search Users</Text>
                            <Input
                                placeholder="Search by name or email..."
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                            />
                        </Box>
                        <Box>
                            <Text fontSize="sm" color="gray.500" mb={2}>Filter by Role</Text>
                            <select
                                value={roleFilter}
                                onChange={(e) => setRoleFilter(e.target.value)}
                                style={{
                                    width: '100%',
                                    padding: '8px 12px',
                                    borderRadius: '6px',
                                    border: '1px solid #e2e8f0',
                                    backgroundColor: 'white',
                                }}
                            >
                                <option value="all">All Roles</option>
                                <option value="admin">Admin</option>
                                <option value="premium">Premium</option>
                                <option value="basic">Basic</option>
                            </select>
                        </Box>
                        <Box>
                            <Text fontSize="sm" color="gray.500" mb={2}>Filter by Status</Text>
                            <select
                                value={statusFilter}
                                onChange={(e) => setStatusFilter(e.target.value)}
                                style={{
                                    width: '100%',
                                    padding: '8px 12px',
                                    borderRadius: '6px',
                                    border: '1px solid #e2e8f0',
                                    backgroundColor: 'white',
                                }}
                            >
                                <option value="all">All Status</option>
                                <option value="active">Active</option>
                                <option value="inactive">Inactive</option>
                                <option value="suspended">Suspended</option>
                            </select>
                        </Box>
                    </Grid>
                </Box>

                {/* Users Grid */}
                <Box>
                    <Flex justify="space-between" align="center" mb={4}>
                        <Text color="gray.500">
                            Showing {startIndex + 1}-{Math.min(startIndex + itemsPerPage, filteredUsers.length)} of {filteredUsers.length} users
                        </Text>
                        <HStack gap={2}>
                            <Button
                                size="sm"
                                variant="outline"
                                disabled={currentPage === 1}
                                onClick={() => setCurrentPage(currentPage - 1)}
                            >
                                Previous
                            </Button>
                            <Text fontSize="sm">
                                Page {currentPage} of {totalPages}
                            </Text>
                            <Button
                                size="sm"
                                variant="outline"
                                disabled={currentPage === totalPages}
                                onClick={() => setCurrentPage(currentPage + 1)}
                            >
                                Next
                            </Button>
                        </HStack>
                    </Flex>

                    <Grid templateColumns="repeat(auto-fit, minmax(400px, 1fr))" gap={6}>
                        {paginatedUsers.map((user) => (
                            <UserCard key={user.id} user={user} />
                        ))}
                    </Grid>
                </Box>
            </VStack>
        </Container>
    );
};

export default UserManagementSimple;
