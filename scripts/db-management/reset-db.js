#!/usr/bin/env node

/**
 * Database Reset Script
 * Interactive database reset using full copies only with security checks
 */

const readline = require('readline');
const EnvironmentDetector = require('./lib/environment');
const HerokuHelper = require('./lib/heroku-helper');
const SecurityHelper = require('./lib/security');

class DatabaseResetter {
  constructor() {
    this.envDetector = new EnvironmentDetector();
    this.herokuHelper = new HerokuHelper();
    this.securityHelper = new SecurityHelper();
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
      console.log('🔄 Ludora Database Reset Tool');
      console.log('═════════════════════════════');
      console.log('⚠️  WARNING: This will replace your current database!');
      console.log('    Only FULL copies can be used for database resets.\n');

      // Detect current environment
      const currentEnv = this.envDetector.getCurrentEnvironment();
      console.log(`Target Environment: ${this.envDetector.getDisplayName(currentEnv.name)}`);
      console.log(`Target App: ${currentEnv.appName}\n`);

      // Security validation for production
      const accessGranted = await this.securityHelper.validateEnvironmentAccess(
        currentEnv.name,
        'Database Reset'
      );

      if (!accessGranted) {
        console.log('❌ Access denied. Operation cancelled.');
        return;
      }

      // Get copy source selection
      const copySelection = await this.selectCopySource(currentEnv);

      // Confirm the reset operation
      const confirmed = await this.confirmReset(currentEnv, copySelection);
      if (!confirmed) {
        console.log('❌ Operation cancelled.');
        return;
      }

      // Execute the reset
      await this.executeReset(currentEnv, copySelection);

    } catch (error) {
      console.error('❌ Error:', error.message);
      process.exit(1);
    } finally {
      this.rl.close();
      this.securityHelper.close();
    }
  }

  /**
   * Interactive copy source selection
   */
  async selectCopySource(currentEnv) {
    console.log('\n📋 Copy Source Selection');
    console.log('─────────────────────────');
    console.log('1. Use local copy    - Latest full copy from current environment');
    console.log('2. Pull from another - Get full copy from different environment');
    console.log('');

    const choice = await this.prompt('Select copy source (1 or 2): ');

    switch (choice) {
      case '1':
        return this.selectLocalCopy(currentEnv);
      case '2':
        return this.selectRemoteCopy(currentEnv);
      default:
        console.log('Invalid choice. Please select 1 or 2.');
        return this.selectCopySource(currentEnv);
    }
  }

  /**
   * Select local copy from current environment
   */
  async selectLocalCopy(currentEnv) {
    console.log(`\n🔍 Searching for full copies in ${currentEnv.name} environment...`);

    const latestCopy = await this.herokuHelper.getLatestCopy(currentEnv.name, 'full');

    if (!latestCopy) {
      console.log('❌ No full copies found in current environment.');
      console.log('   You can create one with: npm run db:create-copy');
      throw new Error('No local full copies available');
    }

    console.log(`✅ Found latest full copy: ${latestCopy.name}`);
    console.log(`   Created: ${latestCopy.displayTimestamp}`);

    return {
      type: 'local',
      copyName: latestCopy.name,
      sourceEnvironment: currentEnv.name
    };
  }

  /**
   * Select copy from remote environment
   */
  async selectRemoteCopy(currentEnv) {
    const availableEnvs = this.envDetector.getAllEnvironments()
      .filter(env => env !== currentEnv.name);

    console.log('\n🌐 Available Environments:');
    availableEnvs.forEach((env, index) => {
      console.log(`${index + 1}. ${this.envDetector.getDisplayName(env)} (${env})`);
    });

    const envChoice = await this.prompt(`Select source environment (1-${availableEnvs.length}): `);
    const envIndex = parseInt(envChoice) - 1;

    if (envIndex < 0 || envIndex >= availableEnvs.length) {
      console.log('Invalid environment choice.');
      return this.selectRemoteCopy(currentEnv);
    }

    const sourceEnv = availableEnvs[envIndex];

    // Check for existing copies vs creating new one
    console.log('\n📋 Copy Options:');
    console.log('1. Use existing copy - Latest full copy from selected environment');
    console.log('2. Create new copy   - Create fresh full copy first, then use it');

    const copyChoice = await this.prompt('Select copy option (1 or 2): ');

    switch (copyChoice) {
      case '1':
        return this.selectExistingRemoteCopy(sourceEnv);
      case '2':
        return this.createNewRemoteCopy(sourceEnv);
      default:
        console.log('Invalid choice. Please select 1 or 2.');
        return this.selectRemoteCopy(currentEnv);
    }
  }

  /**
   * Select existing copy from remote environment
   */
  async selectExistingRemoteCopy(sourceEnv) {
    console.log(`\n🔍 Searching for full copies in ${sourceEnv} environment...`);

    const latestCopy = await this.herokuHelper.getLatestCopy(sourceEnv, 'full');

    if (!latestCopy) {
      console.log(`❌ No full copies found in ${sourceEnv} environment.`);
      console.log('   Creating a new copy instead...');
      return this.createNewRemoteCopy(sourceEnv);
    }

    console.log(`✅ Found latest full copy: ${latestCopy.name}`);
    console.log(`   Created: ${latestCopy.displayTimestamp}`);

    return {
      type: 'existing-remote',
      copyName: latestCopy.name,
      sourceEnvironment: sourceEnv
    };
  }

  /**
   * Create new copy from remote environment
   */
  async createNewRemoteCopy(sourceEnv) {
    console.log(`\n🚀 Creating new full copy from ${sourceEnv} environment...`);

    const sourceAppName = this.envDetector.getAppNameForEnvironment(sourceEnv);
    const copyResult = await this.herokuHelper.createDatabaseCopy(sourceAppName, 'full');

    console.log(`✅ New copy created: ${copyResult.copyName}`);

    return {
      type: 'new-remote',
      copyName: copyResult.copyName,
      sourceEnvironment: sourceEnv
    };
  }

  /**
   * Confirm the reset operation
   */
  async confirmReset(currentEnv, copySelection) {
    console.log('\n⚠️  FINAL CONFIRMATION');
    console.log('════════════════════════');
    console.log(`Target Environment: ${this.envDetector.getDisplayName(currentEnv.name)}`);
    console.log(`Target Database: ${currentEnv.appName}`);
    console.log(`Copy Source: ${copySelection.copyName}`);
    console.log(`Source Environment: ${this.envDetector.getDisplayName(copySelection.sourceEnvironment)}`);

    if (currentEnv.isProduction) {
      console.log('\n🚨 PRODUCTION RESET WARNING:');
      console.log('   This will PERMANENTLY replace the production database!');
      console.log('   A safety backup will be created before the operation.');
    }

    const confirmation = await this.prompt('\nType "RESET DATABASE" to confirm (case sensitive): ');
    return confirmation === 'RESET DATABASE';
  }

  /**
   * Execute the database reset
   */
  async executeReset(currentEnv, copySelection) {
    try {
      console.log('\n🔄 Executing database reset...');
      console.log('   This operation may take 10-30 minutes.');

      // Execute the restore
      const restoreResult = await this.herokuHelper.restoreFromCopy(
        currentEnv.appName,
        copySelection.copyName
      );

      // Display success
      this.displayResetSuccess(currentEnv, copySelection, restoreResult);

    } catch (error) {
      console.error('❌ Database reset failed:', error.message);
      console.log('\n🔧 Recovery Options:');
      console.log('   1. Check Heroku logs for detailed error information');
      console.log('   2. Verify the copy exists and is accessible');
      console.log('   3. Try again with a different copy');
      throw error;
    }
  }

  /**
   * Display reset success information
   */
  displayResetSuccess(currentEnv, copySelection, restoreResult) {
    console.log('\n✅ Database Reset Completed Successfully!');
    console.log('═══════════════════════════════════════');
    console.log(`Target Environment: ${this.envDetector.getDisplayName(currentEnv.name)}`);
    console.log(`Copy Used: ${copySelection.copyName}`);
    console.log(`Source Environment: ${this.envDetector.getDisplayName(copySelection.sourceEnvironment)}`);

    if (restoreResult.safetyBackup) {
      console.log(`Safety Backup: ${restoreResult.safetyBackup}`);
    }

    console.log(`Completed: ${new Date().toLocaleString()}`);

    console.log('\n📋 Important Notes:');
    console.log('   • Database has been completely replaced');
    console.log('   • Application restart may be required');
    console.log('   • Test the application thoroughly');

    if (restoreResult.safetyBackup) {
      console.log(`   • Safety backup available: ${restoreResult.safetyBackup}`);
    }
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
  const resetter = new DatabaseResetter();
  resetter.run().catch(error => {
    console.error('Fatal error:', error.message);
    process.exit(1);
  });
}

module.exports = DatabaseResetter;