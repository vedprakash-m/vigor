// Temporary Chakra UI v3 compatibility layer - to be improved later
import { Box, Card as ChakraCard } from '@chakra-ui/react'

// Temporary stubs for missing components
export const Card = ({ children, ...props }: any) => (
  <ChakraCard.Root {...props}>
    <ChakraCard.Body>
      {children}
    </ChakraCard.Body>
  </ChakraCard.Root>
)

export const CardBody = ({ children, ...props }: any) => (
  <Box {...props}>{children}</Box>
)

export const Stat = ({ children, ...props }: any) => (
  <Box {...props}>{children}</Box>
)

export const StatLabel = ({ children, ...props }: any) => (
  <Box fontSize="sm" color="gray.500" {...props}>{children}</Box>
)

export const StatNumber = ({ children, ...props }: any) => (
  <Box fontSize="2xl" fontWeight="bold" {...props}>{children}</Box>
)

export const StatHelpText = ({ children, ...props }: any) => (
  <Box fontSize="xs" color="gray.400" {...props}>{children}</Box>
)

export const StatArrow = ({ children, ...props }: any) => (
  <Box as="span" {...props}>{children}</Box>
)

export const Avatar = ({ name, size, ...props }: any) => (
  <Box
    display="flex"
    alignItems="center"
    justifyContent="center"
    borderRadius="full"
    bg="blue.500"
    color="white"
    fontWeight="bold"
    w={size === 'sm' ? 8 : size === 'md' ? 10 : 12}
    h={size === 'sm' ? 8 : size === 'md' ? 10 : 12}
    fontSize={size === 'sm' ? 'sm' : 'md'}
    {...props}
  >
    {name?.charAt(0)?.toUpperCase() || 'U'}
  </Box>
)

export const Progress = ({ value, ...props }: any) => (
  <Box bg="gray.200" rounded="full" overflow="hidden" {...props}>
    <Box
      bg="blue.500"
      h="100%"
      w={`${value || 0}%`}
      transition="width 0.3s"
    />
  </Box>
)

// Tab components as simple wrappers
export const Tabs = ({ children, ...props }: any) => (
  <Box {...props}>{children}</Box>
)

export const TabList = ({ children, ...props }: any) => (
  <Box display="flex" gap={2} mb={4} {...props}>{children}</Box>
)

export const Tab = ({ children, ...props }: any) => (
  <Box
    px={4}
    py={2}
    borderRadius="md"
    bg="gray.100"
    cursor="pointer"
    _hover={{ bg: 'gray.200' }}
    {...props}
  >
    {children}
  </Box>
)

export const TabPanels = ({ children, ...props }: any) => (
  <Box {...props}>{children}</Box>
)

export const TabPanel = ({ children, ...props }: any) => (
  <Box {...props}>{children}</Box>
)

// Modal components - simplified
export const Modal = ({ isOpen, children, ...props }: any) => (
  isOpen ? <Box
    position="fixed"
    top={0}
    left={0}
    right={0}
    bottom={0}
    bg="blackAlpha.600"
    display="flex"
    alignItems="center"
    justifyContent="center"
    zIndex={1000}
    {...props}
  >
    {children}
  </Box> : null
)

export const ModalOverlay = () => null

export const ModalContent = ({ children, ...props }: any) => (
  <Box
    bg="white"
    borderRadius="lg"
    p={6}
    maxW="md"
    w="full"
    mx={4}
    {...props}
  >
    {children}
  </Box>
)

export const ModalHeader = ({ children, ...props }: any) => (
  <Box fontSize="lg" fontWeight="bold" mb={4} {...props}>{children}</Box>
)

export const ModalBody = ({ children, ...props }: any) => (
  <Box mb={4} {...props}>{children}</Box>
)

export const ModalFooter = ({ children, ...props }: any) => (
  <Box display="flex" gap={2} justifyContent="flex-end" {...props}>{children}</Box>
)

export const ModalCloseButton = ({ onClick, ...props }: any) => (
  <Box
    position="absolute"
    top={2}
    right={2}
    cursor="pointer"
    onClick={onClick}
    {...props}
  >
    ×
  </Box>
)

// Alert component
export const Alert = ({ children, status, ...props }: any) => (
  <Box
    p={4}
    borderRadius="md"
    bg={status === 'warning' ? 'orange.100' : status === 'error' ? 'red.100' : 'blue.100'}
    color={status === 'warning' ? 'orange.800' : status === 'error' ? 'red.800' : 'blue.800'}
    {...props}
  >
    {children}
  </Box>
)

export const AlertIcon = () => <Box as="span" mr={2}>⚠️</Box>

// Menu components
export const Menu = ({ children, ...props }: any) => (
  <Box position="relative" {...props}>{children}</Box>
)

export const MenuButton = ({ children, ...props }: any) => (
  <Box cursor="pointer" {...props}>{children}</Box>
)

export const MenuList = ({ children, ...props }: any) => (
  <Box
    position="absolute"
    top="100%"
    right={0}
    bg="white"
    borderRadius="md"
    boxShadow="lg"
    py={2}
    minW="200px"
    zIndex={1000}
    {...props}
  >
    {children}
  </Box>
)

export const MenuItem = ({ children, onClick, ...props }: any) => (
  <Box
    px={4}
    py={2}
    cursor="pointer"
    _hover={{ bg: 'gray.100' }}
    onClick={onClick}
    {...props}
  >
    {children}
  </Box>
)

export const MenuDivider = (props: any) => (
  <Box borderTop="1px" borderColor="gray.200" my={1} {...props} />
)

// Form components
export const FormControl = ({ children, ...props }: any) => (
  <Box mb={4} {...props}>{children}</Box>
)

export const FormLabel = ({ children, ...props }: any) => (
  <Box fontSize="sm" fontWeight="medium" mb={1} {...props}>{children}</Box>
)

export const Select = ({ children, ...props }: any) => (
  <Box as="select" p={2} borderRadius="md" border="1px" borderColor="gray.300" {...props}>
    {children}
  </Box>
)

// Drawer components
export const Drawer = ({ isOpen, children, ...props }: any) => (
  isOpen ? <Box
    position="fixed"
    top={0}
    left={0}
    right={0}
    bottom={0}
    bg="blackAlpha.600"
    zIndex={1000}
    {...props}
  >
    {children}
  </Box> : null
)

export const DrawerOverlay = () => null

export const DrawerContent = ({ children, ...props }: any) => (
  <Box
    position="fixed"
    left={0}
    top={0}
    bottom={0}
    w="280px"
    bg="white"
    p={4}
    {...props}
  >
    {children}
  </Box>
)

export const DrawerCloseButton = ({ onClick, ...props }: any) => (
  <Box
    position="absolute"
    top={2}
    right={2}
    cursor="pointer"
    onClick={onClick}
    {...props}
  >
    ×
  </Box>
)

export const DrawerHeader = ({ children, ...props }: any) => (
  <Box fontSize="lg" fontWeight="bold" mb={4} {...props}>{children}</Box>
)

export const DrawerBody = ({ children, ...props }: any) => (
  <Box {...props}>{children}</Box>
)

// Tooltip
export const Tooltip = ({ children, label, ...props }: any) => (
  <Box position="relative" {...props}>
    {children}
  </Box>
)

// Slider components
export const Slider = ({ children, value, onChange, min, max, ...props }: any) => (
  <Box {...props}>
    <Box
      as="input"
      type="range"
      value={value}
      onChange={(e: any) => onChange?.(e.target.value)}
      min={min}
      max={max}
    />
    {children}
  </Box>
)

export const SliderTrack = ({ children, ...props }: any) => (
  <Box {...props}>{children}</Box>
)

export const SliderFilledTrack = (props: any) => (
  <Box {...props} />
)

export const SliderThumb = ({ index, ...props }: any) => (
  <Box {...props} />
)

// useToast hook
export const useToast = () => ({
  toast: (options: any) => {
    console.log('Toast:', options)
  }
})

// useDisclosure hook
export const useDisclosure = () => ({
  open: false,
  onOpen: () => {},
  onClose: () => {},
  onToggle: () => {},
  setOpen: () => {}
})
