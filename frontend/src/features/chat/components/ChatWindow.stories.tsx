import type { Meta, StoryObj } from '@storybook/react';
import { useChatStore } from '../../../store/chatStore';
import ChatWindow from './ChatWindow';

const meta: Meta<typeof ChatWindow> = {
  title: 'Features/Chat/ChatWindow',
  component: ChatWindow,
  decorators: [
    (Story) => {
      // reset store before each story
      useChatStore.getState().clear();
      return <Story />;
    },
  ],
};
export default meta;

type Story = StoryObj<typeof ChatWindow>;

export const Empty: Story = {};
