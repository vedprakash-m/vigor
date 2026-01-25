/**
 * Tier Management Page
 * Subscription tier overview and management for users
 */

import {
    Badge,
    Box,
    Button,
    Card,
    Grid,
    GridItem,
    Heading,
    HStack,
    List,
    Text,
    VStack,
} from '@chakra-ui/react'
import { useAuth } from '../contexts/useAuth'

interface TierFeature {
    name: string
    free: boolean | string
    premium: boolean | string
    enterprise: boolean | string
}

const tierFeatures: TierFeature[] = [
    {
        name: 'AI Workout Generation',
        free: '5/month',
        premium: 'Unlimited',
        enterprise: 'Unlimited',
    },
    {
        name: 'AI Coach Chat',
        free: '10 messages/day',
        premium: 'Unlimited',
        enterprise: 'Unlimited',
    },
    {
        name: 'Progress Tracking',
        free: true,
        premium: true,
        enterprise: true,
    },
    {
        name: 'Advanced Analytics',
        free: false,
        premium: true,
        enterprise: true,
    },
    {
        name: 'Custom Workout Plans',
        free: false,
        premium: true,
        enterprise: true,
    },
    {
        name: 'Nutrition Guidance',
        free: false,
        premium: true,
        enterprise: true,
    },
    {
        name: 'Priority Support',
        free: false,
        premium: true,
        enterprise: true,
    },
    {
        name: 'API Access',
        free: false,
        premium: false,
        enterprise: true,
    },
    {
        name: 'Team Management',
        free: false,
        premium: false,
        enterprise: true,
    },
    {
        name: 'Custom Branding',
        free: false,
        premium: false,
        enterprise: true,
    },
]

interface TierCardProps {
    name: string
    price: string
    period: string
    description: string
    features: string[]
    isCurrentTier: boolean
    isPopular?: boolean
    onSelect: () => void
}

const TierCard = ({
    name,
    price,
    period,
    description,
    features,
    isCurrentTier,
    isPopular,
    onSelect,
}: TierCardProps) => (
    <Card.Root
        bg="white"
        shadow={isPopular ? 'lg' : 'sm'}
        borderRadius="lg"
        border={isPopular ? '2px solid' : '1px solid'}
        borderColor={isPopular ? 'blue.500' : 'gray.200'}
        position="relative"
        overflow="hidden"
    >
        {isPopular && (
            <Box
                position="absolute"
                top={4}
                right={-8}
                bg="blue.500"
                color="white"
                px={8}
                py={1}
                fontSize="xs"
                fontWeight="bold"
                transform="rotate(45deg)"
            >
                POPULAR
            </Box>
        )}
        <Card.Body p={6}>
            <VStack align="stretch" gap={4}>
                <Box>
                    <Heading size="lg" mb={1}>
                        {name}
                    </Heading>
                    <Text color="gray.500" fontSize="sm">
                        {description}
                    </Text>
                </Box>

                <HStack align="baseline">
                    <Text fontSize="4xl" fontWeight="bold">
                        {price}
                    </Text>
                    <Text color="gray.500">{period}</Text>
                </HStack>

                {isCurrentTier ? (
                    <Badge colorPalette="green" size="lg" p={2} textAlign="center">
                        Current Plan
                    </Badge>
                ) : (
                    <Button
                        colorScheme={isPopular ? 'blue' : 'gray'}
                        variant={isPopular ? 'solid' : 'outline'}
                        onClick={onSelect}
                    >
                        {price === '$0' ? 'Downgrade' : 'Upgrade'}
                    </Button>
                )}

                <List.Root gap={2}>
                    {features.map((feature) => (
                        <List.Item key={feature} display="flex" alignItems="center" gap={2}>
                            <Text color="green.500">✓</Text>
                            <Text fontSize="sm">{feature}</Text>
                        </List.Item>
                    ))}
                </List.Root>
            </VStack>
        </Card.Body>
    </Card.Root>
)

const TierManagementPage = () => {
    const { user } = useAuth()
    const currentTier = user?.tier || 'free'

    const handleSelectTier = (tier: string) => {
        // In production, this would redirect to a payment flow
        console.log(`Selected tier: ${tier}`)
        alert(
            `Tier upgrade to ${tier} would redirect to payment. This is a demo.`
        )
    }

    return (
        <Box p={6}>
            <VStack align="start" mb={8} gap={2}>
                <Heading size="xl">Subscription Plans</Heading>
                <Text color="gray.600">
                    Choose the plan that fits your fitness journey
                </Text>
            </VStack>

            {/* Tier Cards */}
            <Grid
                templateColumns={{ base: '1fr', md: 'repeat(3, 1fr)' }}
                gap={6}
                mb={10}
            >
                <GridItem>
                    <TierCard
                        name="Free"
                        price="$0"
                        period="/month"
                        description="Get started with basic features"
                        isCurrentTier={currentTier === 'free'}
                        onSelect={() => handleSelectTier('free')}
                        features={[
                            '5 AI workouts/month',
                            '10 coach messages/day',
                            'Basic progress tracking',
                            'Community access',
                        ]}
                    />
                </GridItem>
                <GridItem>
                    <TierCard
                        name="Premium"
                        price="$9.99"
                        period="/month"
                        description="Unlock your full potential"
                        isCurrentTier={currentTier === 'premium'}
                        isPopular
                        onSelect={() => handleSelectTier('premium')}
                        features={[
                            'Unlimited AI workouts',
                            'Unlimited coach chat',
                            'Advanced analytics',
                            'Custom workout plans',
                            'Nutrition guidance',
                            'Priority support',
                        ]}
                    />
                </GridItem>
                <GridItem>
                    <TierCard
                        name="Enterprise"
                        price="$49.99"
                        period="/month"
                        description="For teams and organizations"
                        isCurrentTier={currentTier === 'enterprise'}
                        onSelect={() => handleSelectTier('enterprise')}
                        features={[
                            'Everything in Premium',
                            'API access',
                            'Team management',
                            'Custom branding',
                            'Dedicated support',
                            'SLA guarantees',
                        ]}
                    />
                </GridItem>
            </Grid>

            {/* Feature Comparison Table */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg">
                <Card.Body p={6}>
                    <Heading size="md" mb={6}>
                        Feature Comparison
                    </Heading>
                    <Box overflowX="auto">
                        <Box as="table" w="full" fontSize="sm">
                            <Box as="thead">
                                <Box as="tr" borderBottom="1px" borderColor="gray.200">
                                    <Box as="th" p={3} textAlign="left" fontWeight="bold">
                                        Feature
                                    </Box>
                                    <Box as="th" p={3} textAlign="center" fontWeight="bold">
                                        Free
                                    </Box>
                                    <Box as="th" p={3} textAlign="center" fontWeight="bold" color="blue.500">
                                        Premium
                                    </Box>
                                    <Box as="th" p={3} textAlign="center" fontWeight="bold">
                                        Enterprise
                                    </Box>
                                </Box>
                            </Box>
                            <Box as="tbody">
                                {tierFeatures.map((feature) => (
                                    <Box as="tr" key={feature.name} borderBottom="1px" borderColor="gray.100">
                                        <Box as="td" p={3}>
                                            {feature.name}
                                        </Box>
                                        <Box as="td" p={3} textAlign="center">
                                            {typeof feature.free === 'boolean' ? (
                                                feature.free ? '✓' : '—'
                                            ) : (
                                                feature.free
                                            )}
                                        </Box>
                                        <Box as="td" p={3} textAlign="center" bg="blue.50">
                                            {typeof feature.premium === 'boolean' ? (
                                                feature.premium ? '✓' : '—'
                                            ) : (
                                                feature.premium
                                            )}
                                        </Box>
                                        <Box as="td" p={3} textAlign="center">
                                            {typeof feature.enterprise === 'boolean' ? (
                                                feature.enterprise ? '✓' : '—'
                                            ) : (
                                                feature.enterprise
                                            )}
                                        </Box>
                                    </Box>
                                ))}
                            </Box>
                        </Box>
                    </Box>
                </Card.Body>
            </Card.Root>

            {/* FAQ Section */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg" mt={8}>
                <Card.Body p={6}>
                    <Heading size="md" mb={6}>
                        Frequently Asked Questions
                    </Heading>
                    <VStack align="stretch" gap={4}>
                        <Box>
                            <Text fontWeight="bold" mb={1}>
                                Can I cancel anytime?
                            </Text>
                            <Text color="gray.600">
                                Yes, you can cancel your subscription at any time. You'll
                                continue to have access until the end of your billing period.
                            </Text>
                        </Box>
                        <Box>
                            <Text fontWeight="bold" mb={1}>
                                What happens to my data if I downgrade?
                            </Text>
                            <Text color="gray.600">
                                Your data is always safe. If you downgrade, you'll lose access
                                to premium features but keep all your workout history and
                                progress.
                            </Text>
                        </Box>
                        <Box>
                            <Text fontWeight="bold" mb={1}>
                                Do you offer refunds?
                            </Text>
                            <Text color="gray.600">
                                We offer a 14-day money-back guarantee if you're not satisfied
                                with your subscription.
                            </Text>
                        </Box>
                    </VStack>
                </Card.Body>
            </Card.Root>
        </Box>
    )
}

export default TierManagementPage
