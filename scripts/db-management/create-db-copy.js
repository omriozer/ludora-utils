#!/usr/bin/env node

/**
 * Database Copy Creation Script
 * Creates full or limited database copies with interactive type selection
 */

const readline = require('readline');
const EnvironmentDetector = require('./lib/environment');
const HerokuHelper = require('./lib/heroku-helper');
const CopyProcessor = require('./lib/copy-processor');

class DatabaseCopyCreator {
  constructor() {
    this.envDetector = new EnvironmentDetector();
    this.herokuHelper = new HerokuHelper();
    this.rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
  }

  /**
   * Main execution flow
   */
  async run() {
    try {
      console.log('🗂️  Ludora Database Copy Creator');
      console.log('═══════════════════════════════════\n');

      // Detect current environment
      const currentEnv = this.envDetector.getCurrentEnvironment();
      console.log(`Current Environment: ${this.envDetector.getDisplayName(currentEnv.name)}`);
      console.log(`Heroku App: ${currentEnv.appName}\n`);

      // Get copy type selection
      const copyType = await this.selectCopyType();

      // Confirm operation
      const confirmed = await this.confirmOperation(currentEnv, copyType);
      if (!confirmed) {
        console.log('❌ Operation cancelled.');
        return;
      }

      // Create the copy
      await this.createCopy(currentEnv, copyType);

    } catch (error) {
      console.error('❌ Error:', error.message);
      process.exit(1);
    } finally {
      this.rl.close();
    }
  }

  /**
   * Interactive copy type selection
   */
  async selectCopyType() {
    console.log('📋 Copy Type Selection');
    console.log('────────────────────────');
    console.log('1. Full Copy    - Complete database with all records');
    console.log('2. Limited Copy - Max 1000 records per table (for development)');
    console.log('');

    const choice = await this.prompt('Select copy type (1 or 2): ');

    switch (choice) {
      case '1':
        return 'full';
      case '2':
        return 'limited';
      default:
        console.log('Invalid choice. Please select 1 or 2.');
        return this.selectCopyType();
    }
  }

  /**
   * Confirm operation details
   */
  async confirmOperation(currentEnv, copyType) {
    console.log('\n📋 Operation Summary');
    console.log('──────────────────────');
    console.log(`Source Environment: ${this.envDetector.getDisplayName(currentEnv.name)}`);
    console.log(`Source App: ${currentEnv.appName}`);
    console.log(`Copy Type: ${copyType.toUpperCase()}`);

    if (copyType === 'limited') {
      console.log(`Processing: Tables will be truncated to max 1000 records`);
    }

    const estimated = copyType === 'full' ? '10-30 minutes' : '15-45 minutes';
    console.log(`Estimated Time: ${estimated}`);
    console.log('');

    const confirmation = await this.prompt('Proceed with copy creation? (y/N): ');
    return confirmation.toLowerCase() === 'y' || confirmation.toLowerCase() === 'yes';
  }

  /**
   * Create the database copy
   */
  async createCopy(currentEnv, copyType) {
    try {
      console.log(`\n🚀 Creating ${copyType} database copy...`);

      // Step 1: Create the Heroku copy
      const copyResult = await this.herokuHelper.createDatabaseCopy(currentEnv.appName, copyType);

      // Step 2: For limited copies, process the copy to limit records
      if (copyType === 'limited') {
        await this.processLimitedCopy(copyResult.copyName);
      }

      // Step 3: Display success information
      this.displaySuccess(copyResult, copyType);

    } catch (error) {
      console.error(`❌ Failed to create ${copyType} copy:`, error.message);
      throw error;
    }
  }

  /**
   * Process limited copy by truncating tables
   */
  async processLimitedCopy(copyName) {
    try {
      console.log('\n🔄 Processing limited copy (this may take several minutes)...');

      // Get connection URL for the copy
      const connectionUrl = this.herokuHelper.getDatabaseConnectionUrl(copyName);

      // Initialize copy processor and connect
      const processor = new CopyProcessor(connectionUrl);
      await processor.connect();

      try {
        // Process the copy to limit records
        await processor.processLimitedCopy();

        // Analyze database for updated statistics
        await processor.analyzeDatabase();

      } finally {
        await processor.disconnect();
      }

    } catch (error) {
      console.error('❌ Failed to process limited copy:', error.message);
      throw error;
    }
  }

  /**
   * Display success information
   */
  displaySuccess(copyResult, copyType) {
    console.log('\n✅ Database Copy Created Successfully!');
    console.log('════════════════════════════════════');
    console.log(`Copy Name: ${copyResult.copyName}`);
    console.log(`Copy Type: ${copyType.toUpperCase()}`);
    console.log(`Source: ${copyResult.sourceApp}`);
    console.log(`Created: ${new Date().toLocaleString()}`);

    if (copyType === 'limited') {
      console.log(`Processing: Tables limited to max 1000 records`);
    }

    console.log('\n📋 Usage:');
    console.log(`• Use this copy with the reset script: npm run db:reset`);
    console.log(`• View all copies: npm run db:manage-copies`);
    console.log(`• Copy can be used across all environments`);
    console.log('');
  }

  /**
   * Prompt helper
   */
  async prompt(question) {
    return new Promise((resolve) => {
      this.rl.question(question, resolve);
    });
  }
}

// Main execution
if (require.main === module) {
  const creator = new DatabaseCopyCreator();
  creator.run().catch(error => {
    console.error('Fatal error:', error.message);
    process.exit(1);
  });
}

module.exports = DatabaseCopyCreator;