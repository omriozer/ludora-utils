#!/usr/bin/env node

/**
 * Security Helper for Database Copy Management
 * Handles production password validation and security checks
 */

const { execSync } = require('child_process');
const readline = require('readline');

class SecurityHelper {
  constructor() {
    this.rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });
  }

  /**
   * Validate production access using maintenance page admin password
   */
  async validateProductionAccess() {
    try {
      console.log('\n🔐 Production Security Check');
      console.log('This operation requires the maintenance page admin password.');

      const enteredPassword = await this.promptPassword('Enter maintenance admin password: ');
      const actualPassword = this.getMaintenancePassword();

      if (enteredPassword !== actualPassword) {
        console.log('❌ Invalid password. Access denied.');
        return false;
      }

      console.log('✅ Password validated. Production access granted.');
      return true;
    } catch (error) {
      console.error('❌ Security validation failed:', error.message);
      return false;
    }
  }

  /**
   * Get maintenance page admin password from environment
   */
  getMaintenancePassword() {
    try {
      // Get the maintenance password from Heroku config
      const password = execSync('heroku config:get MAINTENANCE_ADMIN_PASSWORD --app ludora-api', { encoding: 'utf8' });
      return password.trim();
    } catch (error) {
      throw new Error('Failed to retrieve maintenance password from Heroku config');
    }
  }

  /**
   * Prompt for password input (hidden)
   */
  async promptPassword(prompt) {
    return new Promise((resolve) => {
      // Hide input for password
      const stdin = process.openStdin();
      process.stdout.write(prompt);

      let password = '';
      stdin.on('data', (char) => {
        char = char.toString();
        switch (char) {
          case '\n':
          case '\r':
          case '\u0004':
            stdin.pause();
            process.stdout.write('\n');
            resolve(password);
            break;
          case '\u0003':
            console.log('\nOperation cancelled.');
            process.exit(0);
            break;
          default:
            password += char;
            break;
        }
      });
    });
  }

  /**
   * Production operation confirmation
   */
  async confirmProductionOperation(operation, targetData) {
    console.log('\n⚠️  PRODUCTION OPERATION WARNING');
    console.log('═══════════════════════════════════');
    console.log(`Operation: ${operation}`);
    console.log(`Target: ${targetData}`);
    console.log('Environment: PRODUCTION');
    console.log('═══════════════════════════════════');

    const confirmation = await this.prompt(
      'Type "CONFIRM PRODUCTION" to proceed (case sensitive): '
    );

    if (confirmation !== 'CONFIRM PRODUCTION') {
      console.log('❌ Operation cancelled. Confirmation text did not match.');
      return false;
    }

    return true;
  }

  /**
   * Standard prompt helper
   */
  async prompt(question) {
    return new Promise((resolve) => {
      this.rl.question(question, resolve);
    });
  }

  /**
   * Validate environment access permissions
   */
  async validateEnvironmentAccess(environment, operation) {
    if (environment === 'prod') {
      console.log('\n🔒 Production environment detected');

      // Require password validation for production
      const passwordValid = await this.validateProductionAccess();
      if (!passwordValid) {
        return false;
      }

      // Require explicit confirmation for production operations
      const confirmed = await this.confirmProductionOperation(operation, 'ludora-api (Production)');
      if (!confirmed) {
        return false;
      }
    } else {
      // For non-production environments, just confirm the operation
      const confirmed = await this.prompt(
        `Confirm ${operation} on ${environment} environment? (y/N): `
      );

      if (confirmed.toLowerCase() !== 'y' && confirmed.toLowerCase() !== 'yes') {
        console.log('❌ Operation cancelled.');
        return false;
      }
    }

    return true;
  }

  /**
   * Cleanup readline interface
   */
  close() {
    this.rl.close();
  }
}

module.exports = SecurityHelper;