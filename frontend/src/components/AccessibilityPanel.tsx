import {
    Box,
    Button,
    HStack,
    Text,
    VStack,
} from '@chakra-ui/react';
import React, { useState } from 'react';
import { FiEye, FiMove, FiSettings, FiVolume2 } from 'react-icons/fi';

const AccessibilityPanel: React.FC = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [fontSize, setFontSize] = useState(16);
  const [highContrast, setHighContrast] = useState(false);
  const [reducedMotion, setReducedMotion] = useState(false);
  const [textToSpeech, setTextToSpeech] = useState(false);
  const [keyboardMode, setKeyboardMode] = useState(false);

  const changeFontSize = (increase: boolean) => {
    const newSize = increase ?
      Math.min(fontSize + 2, 24) :
      Math.max(fontSize - 2, 12);
    setFontSize(newSize);
    document.documentElement.style.fontSize = `${newSize}px`;
  };

  const toggleHighContrast = () => {
    setHighContrast(!highContrast);
    if (!highContrast) {
      document.documentElement.classList.add('high-contrast');
    } else {
      document.documentElement.classList.remove('high-contrast');
    }
  };

  const toggleReducedMotion = () => {
    setReducedMotion(!reducedMotion);
    if (!reducedMotion) {
      document.documentElement.classList.add('reduce-motion');
    } else {
      document.documentElement.classList.remove('reduce-motion');
    }
  };

  const resetSettings = () => {
    setFontSize(16);
    setHighContrast(false);
    setReducedMotion(false);
    setTextToSpeech(false);
    setKeyboardMode(false);

    document.documentElement.style.fontSize = '16px';
    document.documentElement.classList.remove('high-contrast', 'reduce-motion');
  };

  if (!isOpen) {
    return (
      <Button
        onClick={() => setIsOpen(true)}
        variant="ghost"
        size="sm"
        aria-label="Open accessibility settings"
      >
        <FiSettings style={{ marginRight: '8px' }} />
        Accessibility
      </Button>
    );
  }

  return (
    <Box
      position="fixed"
      top="50%"
      left="50%"
      transform="translate(-50%, -50%)"
      zIndex={1000}
      maxW="lg"
      w="full"
      mx={4}
      bg="white"
      borderRadius="lg"
      border="1px solid"
      borderColor="gray.200"
      boxShadow="xl"
    >
      <Box p={6}>
        <VStack gap={6} alignItems="stretch">
          {/* Header */}
          <HStack justifyContent="space-between">
            <HStack>
              <FiSettings />
              <Text fontWeight="bold" fontSize="lg">Accessibility Settings</Text>
            </HStack>
            <Button onClick={() => setIsOpen(false)} variant="ghost" size="sm">
              ×
            </Button>
          </HStack>

          {/* Visual Settings */}
          <Box>
            <Text fontWeight="bold" mb={4}>
              <FiEye style={{ display: 'inline', marginRight: '8px' }} />
              Visual Settings
            </Text>

            <VStack gap={3} alignItems="stretch">
              <HStack justifyContent="space-between">
                <Text>Font Size: {fontSize}px</Text>
                <HStack>
                  <Button
                    size="sm"
                    onClick={() => changeFontSize(false)}
                    aria-label="Decrease font size"
                  >
                    A-
                  </Button>
                  <Button
                    size="sm"
                    onClick={() => changeFontSize(true)}
                    aria-label="Increase font size"
                  >
                    A+
                  </Button>
                </HStack>
              </HStack>

              <Button
                variant={highContrast ? 'solid' : 'outline'}
                onClick={toggleHighContrast}
                w="full"
              >
                {highContrast ? 'Disable' : 'Enable'} High Contrast
              </Button>
            </VStack>
          </Box>

          {/* Motion Settings */}
          <Box>
            <Text fontWeight="bold" mb={4}>
              <FiMove style={{ display: 'inline', marginRight: '8px' }} />
              Motion & Animation
            </Text>

            <Button
              variant={reducedMotion ? 'solid' : 'outline'}
              onClick={toggleReducedMotion}
              w="full"
            >
              {reducedMotion ? 'Enable' : 'Disable'} Animations
            </Button>
          </Box>

          {/* Audio Settings */}
          <Box>
            <Text fontWeight="bold" mb={4}>
              <FiVolume2 style={{ display: 'inline', marginRight: '8px' }} />
              Audio & Speech
            </Text>

            <VStack gap={3} alignItems="stretch">
              <Button
                variant={textToSpeech ? 'solid' : 'outline'}
                onClick={() => setTextToSpeech(!textToSpeech)}
                w="full"
              >
                {textToSpeech ? 'Disable' : 'Enable'} Text-to-Speech
              </Button>
            </VStack>
          </Box>

          {/* Navigation Settings */}
          <Box>
            <Text fontWeight="bold" mb={4}>
              Navigation & Interaction
            </Text>

            <Button
              variant={keyboardMode ? 'solid' : 'outline'}
              onClick={() => setKeyboardMode(!keyboardMode)}
              w="full"
            >
              {keyboardMode ? 'Disable' : 'Enable'} Keyboard-Only Mode
            </Button>
          </Box>

          {/* Reset Button */}
          <Button
            variant="outline"
            onClick={resetSettings}
          >
            Reset to Defaults
          </Button>
        </VStack>
      </Box>
    </Box>
  );
};

export default AccessibilityPanel;
