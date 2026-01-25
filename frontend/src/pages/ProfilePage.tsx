/**
 * Settings Page (formerly Profile Page)
 * Comprehensive settings hub for all user preferences
 *
 * Design Principle: All user configuration in one place.
 * Includes: Account info, fitness profile, preferences, accessibility, data management
 */

import {
    Box,
    Button,
    Card,
    Switch as ChakraSwitch,
    Heading,
    HStack,
    NativeSelect,
    Text,
    VStack
} from '@chakra-ui/react'
import { useEffect, useState } from 'react'
import { useAccessibility } from '../components/AccessibilityFeatures'
import { useVedAuth } from '../contexts/useVedAuth'
import { api } from '../services/api'

interface FitnessProfile {
    fitnessLevel: 'beginner' | 'intermediate' | 'advanced'
    fitnessGoal: string
    equipment: string[]
    weeklyGoal: number
}

export const ProfilePage = () => {
    const { user } = useVedAuth()
    const { settings: accessibilitySettings, updateSettings: updateAccessibility, resetSettings: resetAccessibility } = useAccessibility()

    const [fitnessProfile, setFitnessProfile] = useState<FitnessProfile>({
        fitnessLevel: 'beginner',
        fitnessGoal: 'general_fitness',
        equipment: ['bodyweight'],
        weeklyGoal: 4,
    })
    const [, setIsLoading] = useState(true)
    const [isSaving, setIsSaving] = useState(false)
    const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)

    useEffect(() => {
        const fetchProfile = async () => {
            try {
                const response = await api.users.getProfile()
                if (response.data?.profile) {
                    setFitnessProfile({
                        fitnessLevel: response.data.profile.fitnessLevel || 'beginner',
                        fitnessGoal: response.data.profile.fitnessGoal || 'general_fitness',
                        equipment: response.data.profile.equipment || ['bodyweight'],
                        weeklyGoal: response.data.profile.weeklyGoal || 4,
                    })
                }
            } catch (error) {
                console.error('Failed to fetch profile:', error)
            } finally {
                setIsLoading(false)
            }
        }
        fetchProfile()
    }, [])

    const handleSaveProfile = async () => {
        setIsSaving(true)
        try {
            await api.users.updateProfile({ profile: fitnessProfile })
        } catch (error) {
            console.error('Failed to save profile:', error)
        } finally {
            setIsSaving(false)
        }
    }

    const handleDeleteAccount = () => {
        console.log('Account scheduled for deletion - You have 14 days to undo via link in email.')
        // TODO: Call API to flag deletion
        setShowDeleteConfirm(false)
    }

    const memberSince = user?.createdAt
        ? new Date(user.createdAt).toLocaleDateString('en-US', { month: 'long', year: 'numeric' })
        : 'January 2026'

    return (
        <Box p={{ base: 4, md: 6 }} maxW="800px" mx="auto">
            <VStack align="stretch" gap={6}>
                {/* Header */}
                <Box>
                    <Heading size="xl" mb={2}>Settings</Heading>
                    <Text color="gray.600">Manage your profile and preferences</Text>
                </Box>

                {/* Account Section */}
                <Card.Root bg="white" shadow="sm" borderRadius="lg">
                    <Card.Body p={6}>
                        <HStack gap={4} mb={4}>
                            <Box
                                w="60px"
                                h="60px"
                                borderRadius="full"
                                bg="blue.100"
                                display="flex"
                                alignItems="center"
                                justifyContent="center"
                                fontSize="2xl"
                            >
                                👤
                            </Box>
                            <VStack align="start" gap={0}>
                                <Heading size="md">{user?.name || 'Vigor User'}</Heading>
                                <Text color="gray.500" fontSize="sm">{user?.email}</Text>
                                <Text color="gray.400" fontSize="xs">Member since {memberSince}</Text>
                            </VStack>
                        </HStack>
                    </Card.Body>
                </Card.Root>

                {/* Fitness Profile Section */}
                <Card.Root bg="white" shadow="sm" borderRadius="lg">
                    <Card.Body p={6}>
                        <Heading size="md" mb={4}>💪 Fitness Profile</Heading>
                        <VStack align="stretch" gap={4}>
                            <Box>
                                <Text fontWeight="medium" mb={2}>Fitness Level</Text>
                                <NativeSelect.Root>
                                    <NativeSelect.Field
                                        value={fitnessProfile.fitnessLevel}
                                        onChange={(e) => setFitnessProfile({
                                            ...fitnessProfile,
                                            fitnessLevel: e.target.value as FitnessProfile['fitnessLevel']
                                        })}
                                    >
                                        <option value="beginner">Beginner - New to fitness</option>
                                        <option value="intermediate">Intermediate - Some experience</option>
                                        <option value="advanced">Advanced - Experienced athlete</option>
                                    </NativeSelect.Field>
                                </NativeSelect.Root>
                            </Box>

                            <Box>
                                <Text fontWeight="medium" mb={2}>Primary Goal</Text>
                                <NativeSelect.Root>
                                    <NativeSelect.Field
                                        value={fitnessProfile.fitnessGoal}
                                        onChange={(e) => setFitnessProfile({
                                            ...fitnessProfile,
                                            fitnessGoal: e.target.value
                                        })}
                                    >
                                        <option value="weight_loss">Weight Loss</option>
                                        <option value="muscle_gain">Build Muscle</option>
                                        <option value="strength">Increase Strength</option>
                                        <option value="endurance">Improve Endurance</option>
                                        <option value="general_fitness">General Fitness</option>
                                    </NativeSelect.Field>
                                </NativeSelect.Root>
                            </Box>

                            <Box>
                                <Text fontWeight="medium" mb={2}>Available Equipment</Text>
                                <NativeSelect.Root>
                                    <NativeSelect.Field
                                        value={fitnessProfile.equipment[0] || 'bodyweight'}
                                        onChange={(e) => setFitnessProfile({
                                            ...fitnessProfile,
                                            equipment: [e.target.value]
                                        })}
                                    >
                                        <option value="bodyweight">Bodyweight Only</option>
                                        <option value="dumbbells">Dumbbells</option>
                                        <option value="resistance_bands">Resistance Bands</option>
                                        <option value="kettlebells">Kettlebells</option>
                                        <option value="full_gym">Full Gym Access</option>
                                    </NativeSelect.Field>
                                </NativeSelect.Root>
                            </Box>

                            <Box>
                                <Text fontWeight="medium" mb={2}>Weekly Workout Goal</Text>
                                <HStack gap={2}>
                                    {[2, 3, 4, 5, 6].map((num) => (
                                        <Button
                                            key={num}
                                            size="sm"
                                            variant={fitnessProfile.weeklyGoal === num ? 'solid' : 'outline'}
                                            colorScheme={fitnessProfile.weeklyGoal === num ? 'blue' : 'gray'}
                                            onClick={() => setFitnessProfile({ ...fitnessProfile, weeklyGoal: num })}
                                        >
                                            {num}
                                        </Button>
                                    ))}
                                    <Text fontSize="sm" color="gray.500">workouts/week</Text>
                                </HStack>
                            </Box>

                            <Button
                                colorScheme="blue"
                                onClick={handleSaveProfile}
                                loading={isSaving}
                                alignSelf="start"
                            >
                                Save Changes
                            </Button>
                        </VStack>
                    </Card.Body>
                </Card.Root>

                {/* Accessibility Section */}
                <Card.Root bg="white" shadow="sm" borderRadius="lg">
                    <Card.Body p={6}>
                        <Heading size="md" mb={4}>♿ Accessibility</Heading>
                        <VStack align="stretch" gap={4}>
                            <HStack justify="space-between">
                                <VStack align="start" gap={0}>
                                    <Text fontWeight="medium">High Contrast</Text>
                                    <Text fontSize="sm" color="gray.500">Increase color contrast for better visibility</Text>
                                </VStack>
                                <ChakraSwitch.Root
                                    checked={accessibilitySettings.highContrast}
                                    onCheckedChange={() =>
                                        updateAccessibility({ highContrast: !accessibilitySettings.highContrast })
                                    }
                                >
                                    <ChakraSwitch.HiddenInput />
                                    <ChakraSwitch.Control>
                                        <ChakraSwitch.Thumb />
                                    </ChakraSwitch.Control>
                                </ChakraSwitch.Root>
                            </HStack>

                            <HStack justify="space-between">
                                <VStack align="start" gap={0}>
                                    <Text fontWeight="medium">Reduce Motion</Text>
                                    <Text fontSize="sm" color="gray.500">Minimize animations and transitions</Text>
                                </VStack>
                                <ChakraSwitch.Root
                                    checked={accessibilitySettings.reducedMotion}
                                    onCheckedChange={() =>
                                        updateAccessibility({ reducedMotion: !accessibilitySettings.reducedMotion })
                                    }
                                >
                                    <ChakraSwitch.HiddenInput />
                                    <ChakraSwitch.Control>
                                        <ChakraSwitch.Thumb />
                                    </ChakraSwitch.Control>
                                </ChakraSwitch.Root>
                            </HStack>

                            <HStack justify="space-between">
                                <VStack align="start" gap={0}>
                                    <Text fontWeight="medium">Screen Reader Optimized</Text>
                                    <Text fontSize="sm" color="gray.500">Enhanced labels for screen readers</Text>
                                </VStack>
                                <ChakraSwitch.Root
                                    checked={accessibilitySettings.screenReaderOptimized}
                                    onCheckedChange={() =>
                                        updateAccessibility({
                                            screenReaderOptimized: !accessibilitySettings.screenReaderOptimized,
                                        })
                                    }
                                >
                                    <ChakraSwitch.HiddenInput />
                                    <ChakraSwitch.Control>
                                        <ChakraSwitch.Thumb />
                                    </ChakraSwitch.Control>
                                </ChakraSwitch.Root>
                            </HStack>

                            <Box>
                                <Text fontWeight="medium" mb={2}>Font Size</Text>
                                <HStack gap={2}>
                                    {(['normal', 'large', 'x-large'] as const).map((size) => (
                                        <Button
                                            key={size}
                                            size="sm"
                                            variant={accessibilitySettings.fontSize === size ? 'solid' : 'outline'}
                                            colorScheme={accessibilitySettings.fontSize === size ? 'blue' : 'gray'}
                                            onClick={() => updateAccessibility({ fontSize: size })}
                                        >
                                            {size === 'normal' ? 'A' : size === 'large' ? 'A+' : 'A++'}
                                        </Button>
                                    ))}
                                </HStack>
                            </Box>

                            <Button size="sm" variant="ghost" onClick={resetAccessibility} alignSelf="start">
                                Reset to Defaults
                            </Button>
                        </VStack>
                    </Card.Body>
                </Card.Root>

                {/* Data & Account Section */}
                <Card.Root bg="white" shadow="sm" borderRadius="lg">
                    <Card.Body p={6}>
                        <Heading size="md" mb={4}>📦 Data & Account</Heading>
                        <VStack align="stretch" gap={4}>
                            <HStack justify="space-between">
                                <VStack align="start" gap={0}>
                                    <Text fontWeight="medium">Export My Data</Text>
                                    <Text fontSize="sm" color="gray.500">Download all your workout data</Text>
                                </VStack>
                                <Button size="sm" variant="outline">
                                    Export →
                                </Button>
                            </HStack>
                        </VStack>
                    </Card.Body>
                </Card.Root>

                {/* Danger Zone */}
                <Card.Root bg="red.50" borderColor="red.200" borderWidth="1px" borderRadius="lg">
                    <Card.Body p={6}>
                        <Heading size="md" color="red.600" mb={4}>⚠️ Danger Zone</Heading>
                        {!showDeleteConfirm ? (
                            <VStack align="start" gap={2}>
                                <Text fontSize="sm" color="gray.600">
                                    Deleting your account will permanently remove all your data after a 14-day grace period.
                                </Text>
                                <Button
                                    colorScheme="red"
                                    variant="outline"
                                    size="sm"
                                    onClick={() => setShowDeleteConfirm(true)}
                                >
                                    Delete Account
                                </Button>
                            </VStack>
                        ) : (
                            <VStack align="start" gap={3}>
                                <Text color="red.600" fontWeight="medium">
                                    Are you sure? This action cannot be undone after 14 days.
                                </Text>
                                <HStack gap={2}>
                                    <Button
                                        colorScheme="red"
                                        size="sm"
                                        onClick={handleDeleteAccount}
                                    >
                                        Yes, Delete My Account
                                    </Button>
                                    <Button
                                        variant="ghost"
                                        size="sm"
                                        onClick={() => setShowDeleteConfirm(false)}
                                    >
                                        Cancel
                                    </Button>
                                </HStack>
                            </VStack>
                        )}
                    </Card.Body>
                </Card.Root>
            </VStack>
        </Box>
    )
}
