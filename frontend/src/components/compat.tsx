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

// Toast system for v3
const toaster = createToaster({
  placement: 'top'
})

export const useToast = () => ({
  toast: (options: {
    title?: string
    description?: string
    status?: 'success' | 'error' | 'warning' | 'info'
    duration?: number
  }) => {
    toaster.create({
      title: options.title,
      description: options.description,
      status: options.status,
      duration: options.duration || 3000
    })
  }
})

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
