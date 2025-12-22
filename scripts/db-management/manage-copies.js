#!/usr/bin/env node

/**
 * Database Copy Management Script
 * Admin interface to view and delete database copies across all environments
 */

const readline = require('readline');
const EnvironmentDetector = require('./lib/environment');
const HerokuHelper = require('./lib/heroku-helper');

class DatabaseCopyManager {
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
      console.log('🗂️  Ludora Database Copy Manager');
      console.log('═════════════════════════════════');
      console.log('Admin interface for copy management across all environments\n');

      // Show main menu
      await this.showMainMenu();

    } catch (error) {
      console.error('❌ Error:', error.message);
      process.exit(1);
    } finally {
      this.rl.close();
    }
  }

  /**
   * Show main management menu
   */
  async showMainMenu() {
    while (true) {
      console.log('\n📋 Copy Management Options');
      console.log('──────────────────────────');
      console.log('1. List all copies');
      console.log('2. Delete copies');
      console.log('3. Copy statistics');
      console.log('4. Exit');
      console.log('');

      const choice = await this.prompt('Select option (1-4): ');

      switch (choice) {
        case '1':
          await this.listAllCopies();
          break;
        case '2':
          await this.deleteCopiesMenu();
          break;
        case '3':
          await this.showStatistics();
          break;
        case '4':
          console.log('👋 Goodbye!');
          return;
        default:
          console.log('Invalid choice. Please select 1-4.');
      }
    }
  }

  /**
   * List all database copies
   */
  async listAllCopies() {
    try {
      console.log('\n🔍 Fetching all database copies...');
      const copies = await this.herokuHelper.listAllCopies();

      if (copies.length === 0) {
        console.log('📭 No database copies found.');
        console.log('   Create copies with: npm run db:create-copy');
        return;
      }

      this.displayCopiesList(copies);

    } catch (error) {
      console.error('❌ Failed to list copies:', error.message);
    }
  }

  /**
   * Display formatted copies list
   */
  displayCopiesList(copies) {
    console.log('\n📊 Database Copies');
    console.log('══════════════════════════════════════════════════════════');

    // Group by environment
    const copiesByEnv = this.groupCopiesByEnvironment(copies);

    for (const [environment, envCopies] of Object.entries(copiesByEnv)) {
      console.log(`\n🏷️  ${this.envDetector.getDisplayName(environment)} Environment:`);
      console.log('─'.repeat(50));

      envCopies.forEach((copy, index) => {
        const typeIcon = this.getCopyTypeIcon(copy.copyType);
        const typeText = copy.copyType.toUpperCase().padEnd(7);
        const sizeText = copy.size || 'Unknown';

        console.log(`${index + 1}. ${typeIcon} ${copy.name}`);
        console.log(`   Type: ${typeText} | Size: ${sizeText} | Created: ${copy.displayTimestamp}`);
      });
    }

    console.log('\n📊 Summary:');
    console.log(`Total copies: ${copies.length}`);
    this.showCopyTypeSummary(copies);
  }

  /**
   * Group copies by environment
   */
  groupCopiesByEnvironment(copies) {
    const grouped = {};

    for (const copy of copies) {
      if (!grouped[copy.environment]) {
        grouped[copy.environment] = [];
      }
      grouped[copy.environment].push(copy);
    }

    return grouped;
  }

  /**
   * Get icon for copy type
   */
  getCopyTypeIcon(copyType) {
    const icons = {
      'full': '🗄️',
      'limited': '📦',
      'safety': '🛡️'
    };
    return icons[copyType] || '📁';
  }

  /**
   * Show copy type summary
   */
  showCopyTypeSummary(copies) {
    const summary = {};
    copies.forEach(copy => {
      summary[copy.copyType] = (summary[copy.copyType] || 0) + 1;
    });

    Object.entries(summary).forEach(([type, count]) => {
      const icon = this.getCopyTypeIcon(type);
      console.log(`${icon} ${type}: ${count}`);
    });
  }

  /**
   * Delete copies menu
   */
  async deleteCopiesMenu() {
    try {
      console.log('\n🗑️  Delete Database Copies');
      console.log('───────────────────────────');

      const copies = await this.herokuHelper.listAllCopies();

      if (copies.length === 0) {
        console.log('📭 No database copies found to delete.');
        return;
      }

      console.log('⚠️  WARNING: Copy deletion is permanent and cannot be undone!\n');

      // Show copies with selection numbers
      this.displayCopiesForSelection(copies);

      await this.selectAndDeleteCopy(copies);

    } catch (error) {
      console.error('❌ Failed to access deletion menu:', error.message);
    }
  }

  /**
   * Display copies formatted for selection
   */
  displayCopiesForSelection(copies) {
    console.log('Available copies for deletion:');
    console.log('');

    copies.forEach((copy, index) => {
      const typeIcon = this.getCopyTypeIcon(copy.copyType);
      const envDisplay = this.envDetector.getDisplayName(copy.environment);

      console.log(`${index + 1}. ${typeIcon} ${copy.name}`);
      console.log(`   Environment: ${envDisplay} | Type: ${copy.copyType.toUpperCase()} | Created: ${copy.displayTimestamp}`);
      console.log('');
    });

    console.log(`0. Cancel (go back to main menu)`);
  }

  /**
   * Handle copy selection and deletion
   */
  async selectAndDeleteCopy(copies) {
    const selection = await this.prompt(`Select copy to delete (0-${copies.length}): `);
    const index = parseInt(selection);

    if (index === 0) {
      console.log('❌ Deletion cancelled.');
      return;
    }

    if (index < 1 || index > copies.length) {
      console.log('Invalid selection. Please try again.');
      return this.selectAndDeleteCopy(copies);
    }

    const selectedCopy = copies[index - 1];

    // Confirm deletion
    const confirmed = await this.confirmDeletion(selectedCopy);
    if (!confirmed) {
      console.log('❌ Deletion cancelled.');
      return;
    }

    // Execute deletion
    try {
      await this.herokuHelper.deleteCopy(selectedCopy.name);
      console.log(`✅ Copy deleted successfully: ${selectedCopy.name}`);
    } catch (error) {
      console.error('❌ Failed to delete copy:', error.message);
    }
  }

  /**
   * Confirm copy deletion
   */
  async confirmDeletion(copy) {
    console.log('\n⚠️  DELETION CONFIRMATION');
    console.log('═══════════════════════════');
    console.log(`Copy Name: ${copy.name}`);
    console.log(`Environment: ${this.envDetector.getDisplayName(copy.environment)}`);
    console.log(`Type: ${copy.copyType.toUpperCase()}`);
    console.log(`Created: ${copy.displayTimestamp}`);
    console.log('\n🚨 This action is PERMANENT and cannot be undone!');

    const confirmation = await this.prompt('Type "DELETE COPY" to confirm deletion (case sensitive): ');
    return confirmation === 'DELETE COPY';
  }

  /**
   * Show copy statistics
   */
  async showStatistics() {
    try {
      console.log('\n📊 Database Copy Statistics');
      console.log('═══════════════════════════');

      const copies = await this.herokuHelper.listAllCopies();

      if (copies.length === 0) {
        console.log('📭 No database copies found.');
        return;
      }

      // Environment distribution
      console.log('\n🏷️  Distribution by Environment:');
      const envStats = {};
      copies.forEach(copy => {
        envStats[copy.environment] = (envStats[copy.environment] || 0) + 1;
      });

      Object.entries(envStats).forEach(([env, count]) => {
        const envName = this.envDetector.getDisplayName(env);
        console.log(`   ${envName}: ${count} copies`);
      });

      // Copy type distribution
      console.log('\n📦 Distribution by Type:');
      const typeStats = {};
      copies.forEach(copy => {
        typeStats[copy.copyType] = (typeStats[copy.copyType] || 0) + 1;
      });

      Object.entries(typeStats).forEach(([type, count]) => {
        const icon = this.getCopyTypeIcon(type);
        console.log(`   ${icon} ${type.toUpperCase()}: ${count} copies`);
      });

      // Recent activity
      console.log('\n🕐 Recent Activity:');
      const recentCopies = copies.slice(0, 5);
      recentCopies.forEach(copy => {
        const icon = this.getCopyTypeIcon(copy.copyType);
        const envName = this.envDetector.getDisplayName(copy.environment);
        console.log(`   ${icon} ${copy.name} (${envName}, ${copy.displayTimestamp})`);
      });

      console.log(`\n📊 Total: ${copies.length} database copies`);

    } catch (error) {
      console.error('❌ Failed to generate statistics:', error.message);
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
  const manager = new DatabaseCopyManager();
  manager.run().catch(error => {
    console.error('Fatal error:', error.message);
    process.exit(1);
  });
}

module.exports = DatabaseCopyManager;