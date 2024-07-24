const fs = require('fs-extra');
const path = require('path');

const sourceDir = 'musap-ios.github';
const iosDestDir = './ios';
const rootDestDir = './';

const itemsToCopyToIos = [
  'Sources',
  'Package.resolved',
  'Package.swift',
  'LICENSE'
];

const itemsToCopyToRoot = [
 // 'musap-ios.podspec' RN podspec is a bit different; ./ios/**
];

async function copyMusapIos() {
  try {
    // Ensure the destination directories exist
    await fs.ensureDir(iosDestDir);

    // Copy items to iOS directory
    for (const item of itemsToCopyToIos) {
      const sourcePath = path.join(sourceDir, item);
      const destPath = path.join(iosDestDir, item);

      console.log(`Copying ${sourcePath} to ${destPath}`);
      await fs.copy(sourcePath, destPath);
    }

    // Copy items to root directory
    for (const item of itemsToCopyToRoot) {
      const sourcePath = path.join(sourceDir, item);
      const destPath = path.join(rootDestDir, item);

      console.log(`Copying ${sourcePath} to ${destPath}`);
      await fs.copy(sourcePath, destPath);
    }

    console.log('Copy process completed successfully.');
  } catch (error) {
    console.error('An error occurred during the copy process:');
    console.error(error);
    process.exit(1);
  }
}

copyMusapIos();
