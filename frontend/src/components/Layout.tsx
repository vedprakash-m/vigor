import { Box, Flex, Heading, Text } from '@chakra-ui/react'
import { Outlet, Link as RouterLink, useLocation } from 'react-router-dom'
import { useAuth } from '../contexts/useAuth'

const Links = [
  { name: 'Dashboard', path: '/' },
  { name: 'Workouts', path: '/workouts' },
  { name: 'AI Coach', path: '/coach' },
  { name: 'Tier Management', path: '/tiers' },
  { name: 'Profile', path: '/profile' },
]

export const Layout = () => {
  const { user, logout } = useAuth()
  const location = useLocation()

  return (
    <Flex minH="100vh" bg="gray.50">
      {/* Sidebar */}
      <Box
        bg="white"
        w="250px"
        p={6}
        borderRight="1px"
        borderRightColor="gray.200"
        display={{ base: 'none', md: 'block' }}
      >
        <Heading size="lg" color="blue.500" mb={8}>
          Vigor
        </Heading>
        
        <Box>
          {Links.map((link) => (
            <Box key={link.name} mb={2}>
              <Text
                as={RouterLink}
                to={link.path}
                display="block"
                p={3}
                rounded="md"
                bg={location.pathname === link.path ? 'blue.500' : 'transparent'}
                color={location.pathname === link.path ? 'white' : 'gray.700'}
                _hover={{ bg: location.pathname === link.path ? 'blue.600' : 'gray.100' }}
                textDecoration="none"
              >
                {link.name}
              </Text>
            </Box>
          ))}
        </Box>
        
        <Box mt={8} pt={4} borderTop="1px" borderTopColor="gray.200">
          <Text
            as="button"
            p={3}
            w="100%"
            textAlign="left"
            rounded="md"
            _hover={{ bg: 'gray.100' }}
            onClick={logout}
            cursor="pointer"
          >
            Logout
          </Text>
        </Box>
      </Box>

      {/* Main content */}
      <Box flex="1">
        {/* Header */}
        <Flex
          bg="white"
          px={6}
          py={4}
          align="center"
          justify="space-between"
          borderBottom="1px"
          borderBottomColor="gray.200"
        >
          <Heading size="md" display={{ base: 'block', md: 'none' }}>
            Vigor
          </Heading>
          
          <Text>Welcome, {user?.username}</Text>
        </Flex>

        {/* Page content */}
        <Box p={6}>
          <Outlet />
        </Box>
      </Box>
    </Flex>
  )
}