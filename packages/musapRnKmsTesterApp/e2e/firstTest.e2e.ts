import { device, element, by, expect as detoxExpect } from 'detox';
import { describe, it, beforeAll, beforeEach, expect } from 'vitest';

describe('Example', () => {
    beforeAll(async () => {
        await device.launchApp();
    });

    beforeEach(async () => {
        await device.reloadReactNative();
    });

    it('should have welcome screen', async () => {
        await detoxExpect(element(by.id('welcome'))).toBeVisible();
    });

    it('should show hello screen after tap', async () => {
        await element(by.id('hello_button')).tap();
        await detoxExpect(element(by.text('Hello!!!'))).toBeVisible();
    });
});
