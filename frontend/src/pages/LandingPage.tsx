import {
    Box,
    Button,
    Container,
    Flex,
    Grid,
    Heading,
    HStack,
    Icon,
    SimpleGrid,
    Text,
    VStack,
} from '@chakra-ui/react'
import { motion } from 'framer-motion'
import { useEffect, useState } from 'react'
import {
    FiActivity,
    FiAward,
    FiCheck,
    FiChevronRight,
    FiClock,
    FiCpu,
    FiHeart,
    FiMessageCircle,
    FiPlay,
    FiShield,
    FiSmartphone,
    FiStar,
    FiTarget,
    FiTrendingUp,
    FiUsers,
    FiZap,
} from 'react-icons/fi'
import { useNavigate } from 'react-router-dom'
import { useVedAuth } from '../contexts/useVedAuth'

// Motion components
const MotionBox = motion.create(Box)
const MotionText = motion.create(Text)

// Animation variants
const fadeInUp = {
  hidden: { opacity: 0, y: 30 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.6, ease: 'easeOut' } },
}

const staggerContainer = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.1, delayChildren: 0.2 },
  },
}

const scaleIn = {
  hidden: { opacity: 0, scale: 0.8 },
  visible: { opacity: 1, scale: 1, transition: { duration: 0.5, ease: 'easeOut' } },
}

// Rotating taglines for hero
const taglines = [
  'Your AI-Powered Fitness Coach',
  'Professional Training, Zero Cost',
  'Personalized Workouts in Seconds',
  '24/7 Expert Guidance',
]

export const LandingPage = () => {
  const navigate = useNavigate()
  const { login, isAuthenticated, isLoading } = useVedAuth()
  const [currentTagline, setCurrentTagline] = useState(0)

  // Redirect if already authenticated
  useEffect(() => {
    if (isAuthenticated) {
      navigate('/app/dashboard')
    }
  }, [isAuthenticated, navigate])

  // Rotate taglines
  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentTagline((prev) => (prev + 1) % taglines.length)
    }, 3000)
    return () => clearInterval(interval)
  }, [])

  const handleGetStarted = async () => {
    try {
      await login()
    } catch (err) {
      console.error('Login failed:', err)
    }
  }

  const scrollToSection = (id: string) => {
    const element = document.getElementById(id)
    element?.scrollIntoView({ behavior: 'smooth' })
  }

  return (
    <Box bg="gray.50" minH="100vh" w="100%" overflowX="hidden">
      {/* Navigation */}
      <Box
        as="nav"
        position="fixed"
        top={0}
        left={0}
        right={0}
        zIndex={1000}
        bg="rgba(255, 255, 255, 0.95)"
        backdropFilter="blur(10px)"
        borderBottom="1px solid"
        borderColor="gray.100"
        py={3}
      >
        <Container maxW="7xl">
          <Flex justify="space-between" align="center">
            <HStack gap={2}>
              <Box
                bg="purple.500"
                p={2}
                borderRadius="lg"
              >
                <Icon color="white" boxSize={6}>
                  <FiActivity />
                </Icon>
              </Box>
              <Heading size="md" fontWeight="bold" bgGradient="linear(to-r, #667eea, #764ba2)" bgClip="text">
                Vigor
              </Heading>
            </HStack>

            <HStack gap={6} display={{ base: 'none', md: 'flex' }}>
              <Button variant="ghost" size="sm" onClick={() => scrollToSection('features')}>
                Features
              </Button>
              <Button variant="ghost" size="sm" onClick={() => scrollToSection('how-it-works')}>
                How It Works
              </Button>
              <Button variant="ghost" size="sm" onClick={() => scrollToSection('beta')}>
                Join Beta
              </Button>
            </HStack>

            <HStack gap={3}>
              <Button
                variant="ghost"
                size="sm"
                onClick={handleGetStarted}
                loading={isLoading}
              >
                Sign In
              </Button>
              <Button
                bg="purple.500"
                color="white"
                size="sm"
                onClick={handleGetStarted}
                loading={isLoading}
                _hover={{ bg: 'purple.600', transform: 'translateY(-1px)' }}
                transition="all 0.2s"
              >
                Get Started Free
              </Button>
            </HStack>
          </Flex>
        </Container>
      </Box>

      {/* Hero Section */}
      <Box
        pt={{ base: 24, md: 32 }}
        pb={{ base: 16, md: 24 }}
        bg="linear-gradient(180deg, #f8fafc 0%, #eef2ff 50%, #f8fafc 100%)"
        position="relative"
        overflow="hidden"
      >
        {/* Background decoration */}
        <Box
          position="absolute"
          top="-50%"
          right="-20%"
          width="70%"
          height="150%"
          bg="linear-gradient(135deg, rgba(102, 126, 234, 0.08) 0%, rgba(118, 75, 162, 0.08) 100%)"
          borderRadius="full"
          filter="blur(60px)"
        />
        <Box
          position="absolute"
          bottom="-30%"
          left="-10%"
          width="50%"
          height="100%"
          bg="linear-gradient(135deg, rgba(102, 126, 234, 0.05) 0%, rgba(118, 75, 162, 0.05) 100%)"
          borderRadius="full"
          filter="blur(40px)"
        />

        <Container maxW="7xl" position="relative">
          <Grid templateColumns={{ base: '1fr', lg: '1fr 1fr' }} gap={12} alignItems="center">
            <MotionBox
              initial="hidden"
              animate="visible"
              variants={staggerContainer}
            >
              <VStack align="start" gap={6}>
                {/* Badge */}
                <MotionBox variants={fadeInUp}>
                  <HStack
                    bg="white"
                    px={4}
                    py={2}
                    borderRadius="full"
                    shadow="sm"
                    border="1px solid"
                    borderColor="gray.200"
                  >
                    <Box bg="green.100" p={1} borderRadius="full">
                      <Icon color="green.500" boxSize={3}>
                        <FiZap />
                      </Icon>
                    </Box>
                    <Text fontSize="sm" fontWeight="medium" color="gray.700">
                      Powered by Cutting-Edge AI
                    </Text>
                  </HStack>
                </MotionBox>

                {/* Main Headline */}
                <MotionBox variants={fadeInUp}>
                  <Heading
                    as="h1"
                    fontSize={{ base: '3xl', md: '5xl', lg: '6xl' }}
                    fontWeight="extrabold"
                    lineHeight="1.1"
                    color="gray.900"
                  >
                    Professional Fitness
                    <br />
                    <Box as="span" bgGradient="linear(to-r, #667eea, #764ba2)" bgClip="text">
                      Without the Price Tag
                    </Box>
                  </Heading>
                </MotionBox>

                {/* Rotating Tagline */}
                <MotionBox variants={fadeInUp} minH="32px">
                  <MotionText
                    key={currentTagline}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -10 }}
                    fontSize={{ base: 'lg', md: 'xl' }}
                    color="gray.600"
                    fontWeight="medium"
                  >
                    {taglines[currentTagline]}
                  </MotionText>
                </MotionBox>

                {/* Description */}
                <MotionBox variants={fadeInUp}>
                  <Text fontSize={{ base: 'md', md: 'lg' }} color="gray.600" maxW="xl" lineHeight="1.7">
                    Get personalized workout plans, real-time coaching, and intelligent progress tracking—all powered by advanced AI. No expensive trainers, no generic apps. Just results.
                  </Text>
                </MotionBox>

                {/* CTA Buttons */}
                <MotionBox variants={fadeInUp}>
                  <HStack gap={4} flexWrap="wrap">
                    <Button
                      size="lg"
                      bg="purple.500"
                      color="white"
                      px={8}
                      py={6}
                      fontSize="md"
                      fontWeight="semibold"
                      onClick={handleGetStarted}
                      loading={isLoading}
                      _hover={{ bg: 'purple.600', transform: 'translateY(-2px)', shadow: 'xl' }}
                      transition="all 0.2s"
                      shadow="lg"
                    >
                      Start Free Today
                      <Icon ml={2}>
                        <FiChevronRight />
                      </Icon>
                    </Button>
                    <Button
                      size="lg"
                      bg="white"
                      color="gray.700"
                      border="1px solid"
                      borderColor="gray.300"
                      px={6}
                      py={6}
                      fontSize="md"
                      onClick={() => scrollToSection('how-it-works')}
                      _hover={{ bg: 'gray.50', shadow: 'md' }}
                    >
                      <Icon mr={2}>
                        <FiPlay />
                      </Icon>
                      See How It Works
                    </Button>
                  </HStack>
                </MotionBox>

                {/* Trust Indicators */}
                <MotionBox variants={fadeInUp}>
                  <HStack gap={6} pt={4} flexWrap="wrap">
                    <HStack color="gray.500" fontSize="sm">
                      <Icon color="green.500">
                        <FiCheck />
                      </Icon>
                      <Text>No credit card required</Text>
                    </HStack>
                    <HStack color="gray.500" fontSize="sm">
                      <Icon color="green.500">
                        <FiCheck />
                      </Icon>
                      <Text>5 free workouts/month</Text>
                    </HStack>
                    <HStack color="gray.500" fontSize="sm">
                      <Icon color="green.500">
                        <FiCheck />
                      </Icon>
                      <Text>Cancel anytime</Text>
                    </HStack>
                  </HStack>
                </MotionBox>
              </VStack>
            </MotionBox>

            {/* Hero Visual */}
            <MotionBox
              initial="hidden"
              animate="visible"
              variants={scaleIn}
              display={{ base: 'none', lg: 'block' }}
            >
              <Box position="relative">
                {/* Phone mockup */}
                <Box
                  bg="gray.900"
                  borderRadius="3xl"
                  p={3}
                  shadow="2xl"
                  transform="rotate(3deg)"
                  maxW="320px"
                  mx="auto"
                >
                  <Box
                    bg="white"
                    borderRadius="2xl"
                    overflow="hidden"
                    minH="500px"
                  >
                    {/* App Preview */}
                    <Box bg="linear-gradient(135deg, #667eea 0%, #764ba2 100%)" p={4}>
                      <HStack justify="space-between">
                        <Text color="white" fontWeight="bold" fontSize="lg">
                          Today's Workout
                        </Text>
                        <Icon color="white">
                          <FiActivity />
                        </Icon>
                      </HStack>
                    </Box>
                    <VStack p={4} gap={4} align="stretch">
                      {/* Workout Card */}
                      <Box bg="gray.50" p={4} borderRadius="xl">
                        <HStack justify="space-between" mb={2}>
                          <Text fontWeight="semibold" color="gray.800">Full Body Strength</Text>
                          <HStack color="purple.500" fontSize="sm">
                            <Icon><FiClock /></Icon>
                            <Text>45 min</Text>
                          </HStack>
                        </HStack>
                        <Text fontSize="sm" color="gray.600">AI-personalized for your goals</Text>
                        <HStack mt={3} gap={2}>
                          {['💪', '🏋️', '🔥'].map((emoji, i) => (
                            <Box key={i} bg="white" px={2} py={1} borderRadius="md" fontSize="sm">
                              {emoji}
                            </Box>
                          ))}
                        </HStack>
                      </Box>

                      {/* Stats */}
                      <SimpleGrid columns={2} gap={3}>
                        <Box bg="purple.50" p={3} borderRadius="lg" textAlign="center">
                          <Text fontSize="2xl" fontWeight="bold" color="purple.600">12</Text>
                          <Text fontSize="xs" color="gray.600">Day Streak 🔥</Text>
                        </Box>
                        <Box bg="green.50" p={3} borderRadius="lg" textAlign="center">
                          <Text fontSize="2xl" fontWeight="bold" color="green.600">847</Text>
                          <Text fontSize="xs" color="gray.600">Calories Today</Text>
                        </Box>
                      </SimpleGrid>

                      {/* AI Coach Message */}
                      <Box bg="blue.50" p={4} borderRadius="xl" borderLeftWidth={3} borderColor="blue.400">
                        <HStack mb={2}>
                          <Icon color="blue.500"><FiMessageCircle /></Icon>
                          <Text fontWeight="semibold" fontSize="sm" color="blue.700">AI Coach</Text>
                        </HStack>
                        <Text fontSize="sm" color="gray.700">
                          "Great progress this week! Let's focus on core strength today to complement your cardio gains."
                        </Text>
                      </Box>
                    </VStack>
                  </Box>
                </Box>

                {/* Floating badges */}
                <Box
                  position="absolute"
                  top={8}
                  left={-8}
                  bg="white"
                  px={3}
                  py={2}
                  borderRadius="lg"
                  shadow="lg"
                  transform="rotate(-6deg)"
                >
                  <HStack>
                    <Icon color="yellow.500"><FiStar /></Icon>
                    <Text fontSize="sm" fontWeight="medium">4.9 Rating</Text>
                  </HStack>
                </Box>

                <Box
                  position="absolute"
                  bottom={12}
                  right={-4}
                  bg="white"
                  px={3}
                  py={2}
                  borderRadius="lg"
                  shadow="lg"
                  transform="rotate(6deg)"
                >
                  <HStack>
                    <Icon color="green.500"><FiUsers /></Icon>
                    <Text fontSize="sm" fontWeight="medium">10K+ Users</Text>
                  </HStack>
                </Box>
              </Box>
            </MotionBox>
          </Grid>
        </Container>
      </Box>

      {/* Social Proof Bar */}
      <Box bg="white" py={8} borderTop="1px solid" borderBottom="1px solid" borderColor="gray.100">
        <Container maxW="7xl">
          <VStack gap={4}>
            <Text fontSize="sm" color="gray.500" fontWeight="medium" textTransform="uppercase" letterSpacing="wider">
              Trusted by fitness enthusiasts worldwide
            </Text>
            <HStack gap={8} flexWrap="wrap" justify="center">
              {[
                { value: '10,000+', label: 'Active Users' },
                { value: '50,000+', label: 'Workouts Generated' },
                { value: '95%', label: 'Satisfaction Rate' },
                { value: '24/7', label: 'AI Support' },
              ].map((stat, i) => (
                <VStack key={i} gap={0}>
                  <Text fontSize="2xl" fontWeight="bold" bgGradient="linear(to-r, #667eea, #764ba2)" bgClip="text">
                    {stat.value}
                  </Text>
                  <Text fontSize="sm" color="gray.500">{stat.label}</Text>
                </VStack>
              ))}
            </HStack>
          </VStack>
        </Container>
      </Box>

      {/* Features Section */}
      <Box id="features" py={{ base: 16, md: 24 }} bg="white">
        <Container maxW="7xl">
          <VStack gap={16}>
            {/* Section Header */}
            <VStack textAlign="center" maxW="3xl" mx="auto" gap={4}>
              <Text
                fontSize="sm"
                fontWeight="semibold"
                textTransform="uppercase"
                letterSpacing="wider"
                color="purple.500"
              >
                Features
              </Text>
              <Heading as="h2" fontSize={{ base: '2xl', md: '4xl' }} fontWeight="bold" color="gray.900">
                Everything You Need to
                <Box as="span" bgGradient="linear(to-r, #667eea, #764ba2)" bgClip="text"> Transform Your Fitness</Box>
              </Heading>
              <Text fontSize="lg" color="gray.600">
                Vigor combines cutting-edge AI with proven fitness science to deliver a personal training experience that adapts to you.
              </Text>
            </VStack>

            {/* Features Grid */}
            <SimpleGrid columns={{ base: 1, md: 2, lg: 3 }} gap={8} w="full">
              {[
                {
                  icon: FiCpu,
                  title: 'AI-Powered Workouts',
                  description: 'Get personalized workout plans generated by Gemini AI based on your fitness level, goals, and available equipment.',
                  color: 'purple',
                },
                {
                  icon: FiMessageCircle,
                  title: '24/7 AI Coach',
                  description: 'Chat with your AI fitness coach anytime for form guidance, motivation, and answers to your fitness questions.',
                  color: 'blue',
                },
                {
                  icon: FiTrendingUp,
                  title: 'Smart Progress Tracking',
                  description: 'Track your workouts, monitor trends, and watch your fitness journey unfold with intelligent analytics.',
                  color: 'green',
                },
                {
                  icon: FiTarget,
                  title: 'Goal-Oriented Training',
                  description: 'Whether you want to build muscle, lose weight, or improve endurance—Vigor adapts to your goals.',
                  color: 'orange',
                },
                {
                  icon: FiAward,
                  title: 'Gamification & Streaks',
                  description: 'Stay motivated with achievement badges, daily streaks, and rewards that celebrate your consistency.',
                  color: 'yellow',
                },
                {
                  icon: FiSmartphone,
                  title: 'Works Everywhere',
                  description: 'Access your workouts on any device. Progressive Web App support means it works like a native app.',
                  color: 'cyan',
                },
              ].map((feature, i) => (
                <MotionBox
                  key={i}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.5, delay: i * 0.1 }}
                >
                  <Box
                    bg="white"
                    p={6}
                    borderRadius="2xl"
                    border="1px solid"
                    borderColor="gray.100"
                    _hover={{ shadow: 'xl', borderColor: `${feature.color}.200`, transform: 'translateY(-4px)' }}
                    transition="all 0.3s"
                    h="full"
                  >
                    <VStack align="start" gap={4}>
                      <Box
                        bg={`${feature.color}.100`}
                        p={3}
                        borderRadius="xl"
                      >
                        <Icon color={`${feature.color}.500`} boxSize={6}>
                          <feature.icon />
                        </Icon>
                      </Box>
                      <Heading as="h3" size="md" color="gray.800">
                        {feature.title}
                      </Heading>
                      <Text color="gray.600" lineHeight="1.7">
                        {feature.description}
                      </Text>
                    </VStack>
                  </Box>
                </MotionBox>
              ))}
            </SimpleGrid>
          </VStack>
        </Container>
      </Box>

      {/* How It Works Section */}
      <Box id="how-it-works" py={{ base: 16, md: 24 }} bg="gray.50">
        <Container maxW="7xl">
          <VStack gap={16}>
            {/* Section Header */}
            <VStack textAlign="center" maxW="3xl" mx="auto" gap={4}>
              <Text
                fontSize="sm"
                fontWeight="semibold"
                textTransform="uppercase"
                letterSpacing="wider"
                color="purple.500"
              >
                How It Works
              </Text>
              <Heading as="h2" fontSize={{ base: '2xl', md: '4xl' }} fontWeight="bold" color="gray.900">
                Your Fitness Journey in
                <Box as="span" bgGradient="linear(to-r, #667eea, #764ba2)" bgClip="text"> 3 Simple Steps</Box>
              </Heading>
            </VStack>

            {/* Steps */}
            <SimpleGrid columns={{ base: 1, md: 3 }} gap={8} w="full">
              {[
                {
                  step: '01',
                  title: 'Tell Us About You',
                  description: 'Quick onboarding captures your fitness level, goals, available equipment, and any limitations.',
                  icon: FiUsers,
                },
                {
                  step: '02',
                  title: 'Get AI-Generated Workouts',
                  description: 'Our AI creates personalized workout plans tailored specifically to your needs and preferences.',
                  icon: FiCpu,
                },
                {
                  step: '03',
                  title: 'Train & Track Progress',
                  description: 'Complete workouts, chat with your AI coach, and watch your fitness transform over time.',
                  icon: FiTrendingUp,
                },
              ].map((item, i) => (
                <MotionBox
                  key={i}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.5, delay: i * 0.15 }}
                >
                  <VStack
                    bg="white"
                    p={8}
                    borderRadius="2xl"
                    shadow="sm"
                    h="full"
                    position="relative"
                    overflow="hidden"
                  >
                    {/* Step Number */}
                    <Text
                      position="absolute"
                      top={4}
                      right={4}
                      fontSize="6xl"
                      fontWeight="bold"
                      color="gray.100"
                      lineHeight={1}
                    >
                      {item.step}
                    </Text>

                    <Box
                      bg="purple.500"
                      p={4}
                      borderRadius="xl"
                      mb={4}
                    >
                      <Icon color="white" boxSize={8}>
                        <item.icon />
                      </Icon>
                    </Box>
                    <Heading as="h3" size="md" color="gray.800" textAlign="center">
                      {item.title}
                    </Heading>
                    <Text color="gray.600" textAlign="center" lineHeight="1.7">
                      {item.description}
                    </Text>
                  </VStack>
                </MotionBox>
              ))}
            </SimpleGrid>
          </VStack>
        </Container>
      </Box>

      {/* Testimonials Section */}
      <Box py={{ base: 16, md: 24 }} bg="white">
        <Container maxW="7xl">
          <VStack gap={12}>
            <VStack textAlign="center" maxW="3xl" mx="auto" gap={4}>
              <Text
                fontSize="sm"
                fontWeight="semibold"
                textTransform="uppercase"
                letterSpacing="wider"
                color="purple.500"
              >
                Testimonials
              </Text>
              <Heading as="h2" fontSize={{ base: '2xl', md: '4xl' }} fontWeight="bold" color="gray.900">
                Loved by Fitness Enthusiasts
              </Heading>
            </VStack>

            <SimpleGrid columns={{ base: 1, md: 3 }} gap={8} w="full">
              {[
                {
                  name: 'Sarah K.',
                  role: 'Fitness Beginner',
                  quote: "As someone who was intimidated by the gym, Vigor's AI coach gave me the confidence to start. The personalized guidance is incredible!",
                  avatar: '👩‍💼',
                },
                {
                  name: 'Mike R.',
                  role: 'Busy Professional',
                  quote: "I don't have time for long workouts. Vigor creates efficient 30-minute sessions that fit my schedule and actually work.",
                  avatar: '👨‍💻',
                },
                {
                  name: 'Jennifer L.',
                  role: 'Fitness Enthusiast',
                  quote: "I've used many fitness apps, but Vigor's AI actually understands progressive overload. My gains have been consistent!",
                  avatar: '🏃‍♀️',
                },
              ].map((testimonial, i) => (
                <MotionBox
                  key={i}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.5, delay: i * 0.1 }}
                >
                  <Box
                    bg="gray.50"
                    p={6}
                    borderRadius="2xl"
                    h="full"
                    position="relative"
                  >
                    <VStack align="start" gap={4}>
                      {/* Stars */}
                      <HStack color="yellow.400">
                        {[...Array(5)].map((_, i) => (
                          <Icon key={i}><FiStar fill="currentColor" /></Icon>
                        ))}
                      </HStack>

                      <Text color="gray.700" fontStyle="italic" lineHeight="1.8">
                        "{testimonial.quote}"
                      </Text>

                      <HStack pt={2}>
                        <Box fontSize="2xl">{testimonial.avatar}</Box>
                        <VStack align="start" gap={0}>
                          <Text fontWeight="semibold" color="gray.800">{testimonial.name}</Text>
                          <Text fontSize="sm" color="gray.500">{testimonial.role}</Text>
                        </VStack>
                      </HStack>
                    </VStack>
                  </Box>
                </MotionBox>
              ))}
            </SimpleGrid>
          </VStack>
        </Container>
      </Box>

      {/* Beta Access Section */}
      <Box id="beta" py={{ base: 16, md: 24 }} bg="gray.50">
        <Container maxW="4xl">
          <VStack gap={8}>
            <VStack textAlign="center" maxW="3xl" mx="auto" gap={4}>
              <HStack
                bg="purple.100"
                px={4}
                py={2}
                borderRadius="full"
              >
                <Icon color="purple.600" boxSize={4}>
                  <FiStar />
                </Icon>
                <Text fontSize="sm" fontWeight="semibold" color="purple.700">
                  Limited Beta Access
                </Text>
              </HStack>
              <Heading as="h2" fontSize={{ base: '2xl', md: '4xl' }} fontWeight="bold" color="gray.900">
                Be Among the First to
                <Box as="span" bgGradient="linear(to-r, #667eea, #764ba2)" bgClip="text"> Experience Vigor</Box>
              </Heading>
              <Text fontSize="lg" color="gray.600" maxW="2xl">
                We're currently in beta testing and looking for fitness enthusiasts to help shape the future of AI-powered fitness coaching. Join now and get early access to all features.
              </Text>
            </VStack>

            <Box
              bg="white"
              p={8}
              borderRadius="2xl"
              border="1px solid"
              borderColor="gray.200"
              w="full"
              maxW="2xl"
              shadow="lg"
            >
              <VStack gap={6}>
                <SimpleGrid columns={{ base: 1, md: 2 }} gap={4} w="full">
                  {[
                    { icon: FiCpu, text: 'AI-generated workout plans' },
                    { icon: FiMessageCircle, text: '24/7 AI coaching chat' },
                    { icon: FiTrendingUp, text: 'Progress tracking & analytics' },
                    { icon: FiAward, text: 'Streaks & achievements' },
                  ].map((item, i) => (
                    <HStack key={i} bg="gray.50" p={3} borderRadius="lg">
                      <Icon color="purple.500"><item.icon /></Icon>
                      <Text fontSize="sm" color="gray.700">{item.text}</Text>
                    </HStack>
                  ))}
                </SimpleGrid>

                <Box
                  w="full"
                  p={4}
                  bg="purple.50"
                  borderRadius="xl"
                  borderLeftWidth={4}
                  borderColor="purple.400"
                >
                  <Text fontSize="sm" color="purple.800">
                    <Text as="span" fontWeight="bold">🎁 Beta Tester Benefits:</Text> Help us improve, provide feedback, and be the first to access new features as they launch.
                  </Text>
                </Box>

                <Button
                  w="full"
                  size="lg"
                  bg="purple.500"
                  color="white"
                  onClick={handleGetStarted}
                  loading={isLoading}
                  _hover={{ bg: 'purple.600', transform: 'translateY(-2px)', shadow: 'xl' }}
                  transition="all 0.2s"
                >
                  Join the Beta
                  <Icon ml={2}><FiChevronRight /></Icon>
                </Button>

                <Text fontSize="xs" color="gray.500" textAlign="center">
                  Free during beta • No credit card required • Microsoft account sign-in
                </Text>
              </VStack>
            </Box>
          </VStack>
        </Container>
      </Box>

      {/* Final CTA Section */}
      <Box py={{ base: 16, md: 24 }} bg="purple.600">
        <Container maxW="4xl">
          <VStack textAlign="center" gap={8}>
            <Heading as="h2" fontSize={{ base: '2xl', md: '4xl' }} fontWeight="bold" color="white">
              Ready to Transform Your Fitness?
            </Heading>
            <Text fontSize="lg" color="purple.100" maxW="2xl">
              Join thousands of users who have discovered the power of AI-driven personal training. Start your journey today—it's completely free.
            </Text>
            <HStack gap={4} flexWrap="wrap" justify="center">
              <Button
                size="lg"
                bg="white"
                color="purple.600"
                px={8}
                py={6}
                onClick={handleGetStarted}
                loading={isLoading}
                _hover={{ bg: 'gray.100', transform: 'translateY(-2px)' }}
                transition="all 0.2s"
                shadow="lg"
              >
                Start Free Today
                <Icon ml={2}><FiChevronRight /></Icon>
              </Button>
            </HStack>
            <HStack gap={4} color="purple.200" fontSize="sm">
              <HStack>
                <Icon><FiShield /></Icon>
                <Text>Secure Sign-in</Text>
              </HStack>
              <Text>•</Text>
              <HStack>
                <Icon><FiHeart /></Icon>
                <Text>No Credit Card</Text>
              </HStack>
              <Text>•</Text>
              <HStack>
                <Icon><FiZap /></Icon>
                <Text>Instant Access</Text>
              </HStack>
            </HStack>
          </VStack>
        </Container>
      </Box>

      {/* Footer */}
      <Box bg="gray.900" py={12}>
        <Container maxW="7xl">
          <Grid templateColumns={{ base: '1fr', md: '2fr 1fr 1fr 1fr' }} gap={8}>
            <VStack align="start" gap={4}>
              <HStack>
                <Box
                  bg="purple.500"
                  p={2}
                  borderRadius="lg"
                >
                  <Icon color="white" boxSize={5}>
                    <FiActivity />
                  </Icon>
                </Box>
                <Heading size="md" color="white">Vigor</Heading>
              </HStack>
              <Text color="gray.400" fontSize="sm" maxW="xs">
                AI-powered fitness coaching that adapts to you. Professional training without the price tag.
              </Text>
            </VStack>

            <VStack align="start" gap={3}>
              <Text fontWeight="semibold" color="white">Product</Text>
              <Text
                color="gray.400"
                fontSize="sm"
                cursor="pointer"
                _hover={{ color: 'white' }}
                onClick={() => scrollToSection('features')}
              >
                Features
              </Text>
              <Text
                color="gray.400"
                fontSize="sm"
                cursor="pointer"
                _hover={{ color: 'white' }}
                onClick={() => scrollToSection('beta')}
              >
                Join Beta
              </Text>
              <Text
                color="gray.400"
                fontSize="sm"
                cursor="pointer"
                _hover={{ color: 'white' }}
                onClick={() => scrollToSection('how-it-works')}
              >
                How It Works
              </Text>
            </VStack>

            <VStack align="start" gap={3}>
              <Text fontWeight="semibold" color="white">Company</Text>
              <Text color="gray.400" fontSize="sm">About Us</Text>
              <Text color="gray.400" fontSize="sm">Contact</Text>
              <Text color="gray.400" fontSize="sm">Blog</Text>
            </VStack>

            <VStack align="start" gap={3}>
              <Text fontWeight="semibold" color="white">Legal</Text>
              <Text color="gray.400" fontSize="sm">Privacy Policy</Text>
              <Text color="gray.400" fontSize="sm">Terms of Service</Text>
              <Text color="gray.400" fontSize="sm">Cookie Policy</Text>
            </VStack>
          </Grid>

          <Box borderTop="1px solid" borderColor="gray.800" mt={12} pt={8}>
            <Flex justify="space-between" align="center" flexWrap="wrap" gap={4}>
              <Text color="gray.500" fontSize="sm">
                © {new Date().getFullYear()} Vigor. All rights reserved.
              </Text>
              <Text color="gray.500" fontSize="sm">
                Built with ❤️ by Vedprakash
              </Text>
            </Flex>
          </Box>
        </Container>
      </Box>
    </Box>
  )
}

export default LandingPage
