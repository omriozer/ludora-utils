#!/usr/bin/env node

/**
 * Environment Detection Helper for Database Copy Management
 * Automatically detects current Ludora environment based on Heroku config
 */

const { execSync } = require('child_process');

class EnvironmentDetector {
  constructor() {
    this.environments = {
      'ludora-api': 'prod',
      'ludora-api-staging': 'staging',
      'ludora-api-dev': 'dev'
    };
  }

  /**
   * Detect current environment based on Heroku app
   */
  getCurrentEnvironment() {
    try {
      // Get current Heroku app name
      const appInfo = execSync('heroku apps:info --json', { encoding: 'utf8' });
      const app = JSON.parse(appInfo);
      const appName = app.name;

      const environment = this.environments[appName];
      if (!environment) {
        throw new Error(`Unknown Heroku app: ${appName}. Expected one of: ${Object.keys(this.environments).join(', ')}`);
      }

      return {
        name: environment,
        appName: appName,
        isProduction: environment === 'prod'
      };
    } catch (error) {
      throw new Error(`Failed to detect environment: ${error.message}`);
    }
  }

  /**
   * Get Heroku app name for a given environment
   */
  getAppNameForEnvironment(environment) {
    const appName = Object.keys(this.environments).find(
      key => this.environments[key] === environment
    );

    if (!appName) {
      throw new Error(`Unknown environment: ${environment}. Expected one of: ${Object.values(this.environments).join(', ')}`);
    }

    return appName;
  }

  /**
   * Validate if environment exists and is accessible
   */
  async validateEnvironment(environment) {
    try {
      const appName = this.getAppNameForEnvironment(environment);
      execSync(`heroku apps:info --app ${appName}`, { encoding: 'utf8' });
      return true;
    } catch (error) {
      return false;
    }
  }

  /**
   * Get all available environments
   */
  getAllEnvironments() {
    return Object.values(this.environments);
  }

  /**
   * Get environment display name
   */
  getDisplayName(environment) {
    const displayNames = {
      'prod': 'Production',
      'staging': 'Staging',
      'dev': 'Development'
    };
    return displayNames[environment] || environment;
  }
}

module.exports = EnvironmentDetector;