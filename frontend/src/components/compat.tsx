// Chakra UI v3 compatibility layer
import {
    Box,
    Button,
    Card as ChakraCard,
    createToaster,
    DialogBackdrop,
    DialogBody,
    DialogCloseTrigger,
    DialogContent,
    DialogFooter,
    DialogHeader,
    DialogRoot,
    IconButton,
    Stack,
    Toaster
} from '@chakra-ui/react'
import { useCallback, useState } from 'react'

// Toast system for v3
const toaster = createToaster({
  placement: 'top'
})

export const useToast = () => {
  return (options: {
    title?: string
    description?: string
    status?: 'success' | 'error' | 'warning' | 'info'
    duration?: number
    isClosable?: boolean
  }) => {
    toaster.create({
      title: options.title,
      description: options.description,
      type: options.status,
      duration: options.duration || 3000
    })
  }
}

// useDisclosure hook for modal state management
export const useDisclosure = (initialState = false) => {
  const [isOpen, setIsOpen] = useState(initialState)
  const onOpen = useCallback(() => setIsOpen(true), [])
  const onClose = useCallback(() => setIsOpen(false), [])
  const onToggle = useCallback(() => setIsOpen(prev => !prev), [])
  return { isOpen, onOpen, onClose, onToggle }
}

// Card compatibility
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

// Modal compatibility using Dialog
export const Modal = ({ isOpen, onClose, children, ...props }: any) => (
  <DialogRoot open={isOpen} onOpenChange={(e) => e.open || onClose()} {...props}>
    {children}
  </DialogRoot>
)

export const ModalOverlay = () => <DialogBackdrop />

export const ModalContent = ({ children, ...props }: any) => (
  <DialogContent {...props}>{children}</DialogContent>
)

export const ModalHeader = ({ children, ...props }: any) => (
  <DialogHeader {...props}>{children}</DialogHeader>
)

export const ModalBody = ({ children, ...props }: any) => (
  <DialogBody {...props}>{children}</DialogBody>
)

export const ModalFooter = ({ children, ...props }: any) => (
  <DialogFooter {...props}>{children}</DialogFooter>
)

export const ModalCloseButton = (props: any) => (
  <DialogCloseTrigger asChild>
    <IconButton variant="ghost" {...props} />
  </DialogCloseTrigger>
)

// Stack compatibility
export const VStack = ({ children, spacing, ...props }: any) => (
  <Stack direction="vertical" gap={spacing} {...props}>
    {children}
  </Stack>
)

export const HStack = ({ children, spacing, ...props }: any) => (
  <Stack direction="horizontal" gap={spacing} {...props}>
    {children}
  </Stack>
)

// Button compatibility
export const ButtonWithIcon = ({ leftIcon, rightIcon, icon, children, ...props }: any) => {
  if (icon) {
    return (
      <IconButton {...props}>
        {icon}
      </IconButton>
    )
  }

  return (
    <Button {...props}>
      {leftIcon && <Box mr={2}>{leftIcon}</Box>}
      {children}
      {rightIcon && <Box ml={2}>{rightIcon}</Box>}
    </Button>
  )
}

// Export the toaster for app-level usage
export { toaster, Toaster }
