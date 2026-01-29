/**
 * Tier Management Page
 * Subscription tier overview with Ghost-specific features
 * Per UX Spec Part V §5.10 and PRD §2.4 - $49/month Premium
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
}

// Ghost-specific tier features per PRD
const tierFeatures: TierFeature[] = [
    {
        name: 'Ghost AI Mode',
        free: 'Observer only',
        premium: 'Full Ghost (5 phases)',
    },
    {
        name: 'Trust System',
        free: 'Basic',
        premium: 'Full progression',
    },
    {
        name: 'Workout Mutations',
        free: false,
        premium: 'Unlimited',
    },
    {
        name: 'Decision Receipts',
        free: false,
        premium: true,
    },
    {
        name: 'Apple Watch Integration',
        free: 'Read only',
        premium: 'Full (required)',
    },
    {
        name: 'Phenome Data Store',
        free: '30 days',
        premium: 'Unlimited',
    },
    {
        name: 'RAG-Enhanced Context',
        free: false,
        premium: true,
    },
    {
        name: 'Safety Breakers',
        free: true,
        premium: true,
    },
    {
        name: 'Progress Analytics',
        free: 'Basic',
        premium: 'Advanced',
    },
    {
        name: 'Behavior Learning',
        free: false,
        premium: true,
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

            {/* Tier Cards - Free and Premium only per PRD */}
            <Grid
                templateColumns={{ base: '1fr', md: 'repeat(2, 1fr)' }}
                gap={6}
                mb={10}
                maxW="800px"
                mx="auto"
            >
                <GridItem>
                    <TierCard
                        name="Free"
                        price="$0"
                        period="/month"
                        description="Experience Ghost in Observer mode"
                        isCurrentTier={currentTier === 'free'}
                        onSelect={() => handleSelectTier('free')}
                        features={[
                            'Ghost Observer mode only',
                            'Basic Trust progression',
                            'Apple Watch read-only',
                            '30-day Phenome storage',
                            'Basic progress tracking',
                            'Safety breaker protection',
                        ]}
                    />
                </GridItem>
                <GridItem>
                    <TierCard
                        name="Premium"
                        price={`$${TIER_PRICING.PREMIUM_MONTHLY}`}
                        period="/month"
                        description="Full Ghost AI with Apple Watch required"
                        isCurrentTier={currentTier === 'premium'}
                        isPopular
                        onSelect={() => handleSelectTier('premium')}
                        features={[
                            'Full Ghost (all 5 Trust phases)',
                            'Unlimited workout mutations',
                            'Full Apple Watch integration ⌚',
                            'Unlimited Phenome storage',
                            'RAG-enhanced personalization',
                            'Decision receipts & transparency',
                            'Behavior learning',
                            'Priority support',
                        ]}
                    />
                </GridItem>
            </Grid>

            {/* Apple Watch Requirement Note */}
            <Card.Root bg="orange.50" borderColor="orange.200" border="1px" borderRadius="lg" mb={8} maxW="800px" mx="auto">
                <Card.Body p={4}>
                    <HStack gap={3}>
                        <Text fontSize="xl">⌚</Text>
                        <VStack align="start" gap={0}>
                            <Text fontWeight="medium" color="orange.700">
                                Apple Watch Required for Premium
                            </Text>
                            <Text fontSize="sm" color="orange.600">
                                Ghost's full capabilities require Apple Watch for real-time biometric
                                data collection (HRV, recovery, sleep). The Watch enables Ghost to
                                make intelligent, context-aware decisions about your training.
                            </Text>
                        </VStack>
                    </HStack>
                </Card.Body>
            </Card.Root>

            {/* Annual Savings */}
            <Card.Root bg="green.50" borderColor="green.200" border="1px" borderRadius="lg" mb={8} maxW="800px" mx="auto">
                <Card.Body p={4}>
                    <HStack justify="space-between" flexWrap="wrap" gap={4}>
                        <VStack align="start" gap={0}>
                            <Text fontWeight="bold" color="green.700">
                                Save with Annual Billing
                            </Text>
                            <Text fontSize="sm" color="green.600">
                                ${TIER_PRICING.PREMIUM_YEARLY}/year (save ${TIER_PRICING.PREMIUM_MONTHLY * 12 - TIER_PRICING.PREMIUM_YEARLY}/year)
                            </Text>
                        </VStack>
                        <Badge colorPalette="green" p={2}>
                            ~15% OFF
                        </Badge>
                    </HStack>
                </Card.Body>
            </Card.Root>

            {/* Feature Comparison Table */}
            <Card.Root bg="white" shadow="sm" borderRadius="lg">
                <Card.Body p={6}>
                    <Heading size="md" mb={6}>
                        Ghost Feature Comparison
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
                                        Premium ($49/mo)
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
                                Why is Apple Watch required for Premium?
                            </Text>
                            <Text color="gray.600">
                                Ghost uses real-time biometric data (HRV, recovery metrics, sleep
                                quality) from Apple Watch to make intelligent training decisions.
                                Without this data, Ghost cannot reliably progress through Trust phases.
                            </Text>
                        </Box>
                        <Box>
                            <Text fontWeight="bold" mb={1}>
                                What are Trust phases?
                            </Text>
                            <Text color="gray.600">
                                Trust phases (Observer → Scheduler → Auto-Scheduler → Transformer →
                                Full Ghost) represent how much autonomy Ghost has to modify your
                                training. You start in Observer mode and graduate based on workout
                                completion and feedback consistency.
                            </Text>
                        </Box>
                        <Box>
                            <Text fontWeight="bold" mb={1}>
                                Can I cancel anytime?
                            </Text>
                            <Text color="gray.600">
                                Yes, you can cancel your subscription at any time. You'll continue
                                to have access until the end of your billing period. Your Phenome
                                data and Trust progress are preserved.
                            </Text>
                        </Box>
                        <Box>
                            <Text fontWeight="bold" mb={1}>
                                What happens to my data if I downgrade?
                            </Text>
                            <Text color="gray.600">
                                Your Phenome data beyond 30 days becomes read-only. Ghost reverts
                                to Observer mode. Your Trust progress is preserved if you upgrade
                                again within 90 days.
                            </Text>
                        </Box>
                    </VStack>
                </Card.Body>
            </Card.Root>
        </Box>
    )
}

export default TierManagementPage
