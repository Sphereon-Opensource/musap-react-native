const { detox } = require('detox');
const adapter = require('detox/runners/jest/adapter');
const config = require('./package.json').detox;

jest.setTimeout(120000);

beforeAll(async () => {
    await detox.init(config);
});

beforeEach(async () => {
    await adapter.beforeEach();
});

afterEach(async () => {
    await adapter.afterEach();
});

afterAll(async () => {
    await detox.cleanup();
});
