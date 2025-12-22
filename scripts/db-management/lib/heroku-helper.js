#!/usr/bin/env node

/**
 * Heroku Helper for Database Copy Management
 * Handles all Heroku CLI operations for database copying and management
 */

const { execSync, spawn } = require('child_process');
const path = require('path');

class HerokuHelper {
  constructor() {
    this.copyPrefix = 'ludora';
  }

  /**
   * Create a database copy with specified type and naming
   */
  async createDatabaseCopy(sourceAppName, copyType = 'full') {
    const timestamp = this.generateTimestamp();
    const copyName = `${this.copyPrefix}-${this.getEnvironmentFromApp(sourceAppName)}-backup-${copyType}-${timestamp}`;

    try {
      console.log(`Creating ${copyType} database copy: ${copyName}`);
      console.log(`Source: ${sourceAppName}`);

      // Create the Heroku postgres copy
      const command = `heroku pg:copy ${sourceAppName}::DATABASE_URL ${copyName} --app ${sourceAppName}`;
      const result = execSync(command, { encoding: 'utf8', stdio: 'inherit' });

      console.log(`✅ ${copyType} copy created successfully: ${copyName}`);
      return {
        copyName,
        copyType,
        sourceApp: sourceAppName,
        timestamp,
        success: true
      };
    } catch (error) {
      console.error(`❌ Failed to create ${copyType} copy:`, error.message);
      throw error;
    }
  }

  /**
   * List all database copies across environments
   */
  async listAllCopies() {
    const copies = [];

    try {
      // List all Heroku postgres databases
      const result = execSync('heroku pg:info --all --json', { encoding: 'utf8' });
      const databases = JSON.parse(result);

      // Filter for our backup copies
      for (const db of databases) {
        if (db.name && db.name.startsWith(this.copyPrefix)) {
          const copyInfo = this.parseCopyName(db.name);
          if (copyInfo) {
            copies.push({
              ...copyInfo,
              name: db.name,
              size: db.plan || 'Unknown',
              status: db.state || 'Unknown',
              created: db.created_at || 'Unknown'
            });
          }
        }
      }

      // Sort by timestamp (newest first)
      return copies.sort((a, b) => b.timestamp.localeCompare(a.timestamp));
    } catch (error) {
      console.error('❌ Failed to list copies:', error.message);
      return [];
    }
  }

  /**
   * Get latest copy of specific type for environment
   */
  async getLatestCopy(environment, copyType = 'full') {
    const allCopies = await this.listAllCopies();
    const filteredCopies = allCopies.filter(copy =>
      copy.environment === environment && copy.copyType === copyType
    );

    return filteredCopies.length > 0 ? filteredCopies[0] : null;
  }

  /**
   * Delete a database copy
   */
  async deleteCopy(copyName) {
    try {
      console.log(`Deleting database copy: ${copyName}`);
      const command = `heroku addons:destroy ${copyName} --confirm ${copyName}`;
      execSync(command, { encoding: 'utf8', stdio: 'inherit' });
      console.log(`✅ Copy deleted successfully: ${copyName}`);
      return true;
    } catch (error) {
      console.error(`❌ Failed to delete copy ${copyName}:`, error.message);
      throw error;
    }
  }

  /**
   * Restore database from copy
   */
  async restoreFromCopy(targetAppName, copyName) {
    try {
      console.log(`Restoring database for ${targetAppName} from copy: ${copyName}`);

      // First create a backup of current database as safety net
      const safetyBackup = await this.createDatabaseCopy(targetAppName, 'safety');
      console.log(`✅ Safety backup created: ${safetyBackup.copyName}`);

      // Restore from the specified copy
      const command = `heroku pg:copy ${copyName}::DATABASE_URL ${targetAppName}::DATABASE_URL --app ${targetAppName} --confirm ${targetAppName}`;
      execSync(command, { encoding: 'utf8', stdio: 'inherit' });

      console.log(`✅ Database restored successfully from ${copyName}`);
      return {
        success: true,
        safetyBackup: safetyBackup.copyName
      };
    } catch (error) {
      console.error(`❌ Failed to restore from copy ${copyName}:`, error.message);
      throw error;
    }
  }

  /**
   * Connect to a database copy for limited processing
   */
  getDatabaseConnectionUrl(copyName) {
    try {
      const result = execSync(`heroku config:get DATABASE_URL --app ${copyName}`, { encoding: 'utf8' });
      return result.trim();
    } catch (error) {
      throw new Error(`Failed to get connection URL for ${copyName}: ${error.message}`);
    }
  }

  /**
   * Generate timestamp for copy naming
   */
  generateTimestamp() {
    const now = new Date();
    return now.toISOString()
      .replace(/[-:T]/g, '')
      .replace(/\.\d{3}Z$/, '')
      .slice(0, 14); // YYYYMMDDHHMMSS
  }

  /**
   * Parse copy name to extract metadata
   */
  parseCopyName(copyName) {
    // Expected format: ludora-{environment}-backup-{type}-{timestamp}
    const regex = /^ludora-(\w+)-backup-(full|limited|safety)-(\d{14})$/;
    const match = copyName.match(regex);

    if (!match) {
      return null;
    }

    return {
      environment: match[1],
      copyType: match[2],
      timestamp: match[3],
      displayTimestamp: this.formatTimestamp(match[3])
    };
  }

  /**
   * Format timestamp for display
   */
  formatTimestamp(timestamp) {
    // Convert YYYYMMDDHHMMSS to readable format
    const year = timestamp.slice(0, 4);
    const month = timestamp.slice(4, 6);
    const day = timestamp.slice(6, 8);
    const hour = timestamp.slice(8, 10);
    const minute = timestamp.slice(10, 12);
    const second = timestamp.slice(12, 14);

    return `${year}-${month}-${day} ${hour}:${minute}:${second}`;
  }

  /**
   * Extract environment from Heroku app name
   */
  getEnvironmentFromApp(appName) {
    if (appName === 'ludora-api') return 'prod';
    if (appName === 'ludora-api-staging') return 'staging';
    if (appName === 'ludora-api-dev') return 'dev';
    throw new Error(`Unknown app name: ${appName}`);
  }

  /**
   * Validate if copy exists
   */
  async copyExists(copyName) {
    try {
      execSync(`heroku pg:info ${copyName} --json`, { encoding: 'utf8' });
      return true;
    } catch (error) {
      return false;
    }
  }
}

module.exports = HerokuHelper;