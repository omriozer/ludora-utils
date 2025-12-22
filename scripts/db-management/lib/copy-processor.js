#!/usr/bin/env node

/**
 * Copy Processor for Database Copy Management
 * Handles limited copy processing (truncating tables to 1000 records)
 */

const { Client } = require('pg');

class CopyProcessor {
  constructor(connectionUrl) {
    this.connectionUrl = connectionUrl;
    this.client = null;
  }

  /**
   * Connect to the database
   */
  async connect() {
    try {
      this.client = new Client({ connectionString: this.connectionUrl });
      await this.client.connect();
      console.log('✅ Connected to database for processing');
    } catch (error) {
      throw new Error(`Failed to connect to database: ${error.message}`);
    }
  }

  /**
   * Disconnect from the database
   */
  async disconnect() {
    if (this.client) {
      await this.client.end();
      console.log('✅ Disconnected from database');
    }
  }

  /**
   * Process limited copy by truncating tables to 1000 records
   */
  async processLimitedCopy() {
    try {
      console.log('🔄 Processing limited copy - truncating tables to 1000 records max...');

      // Get all user tables (excluding system tables)
      const userTables = await this.getUserTables();
      console.log(`Found ${userTables.length} user tables to process`);

      let processedTables = 0;
      let totalRecordsRemoved = 0;

      for (const table of userTables) {
        const recordsRemoved = await this.limitTableRecords(table);
        if (recordsRemoved > 0) {
          console.log(`  ✓ ${table}: removed ${recordsRemoved} records`);
          totalRecordsRemoved += recordsRemoved;
        }
        processedTables++;
      }

      console.log(`✅ Limited copy processing complete:`);
      console.log(`  - Processed ${processedTables} tables`);
      console.log(`  - Removed ${totalRecordsRemoved} total records`);
      console.log(`  - Each table now has max 1000 records`);

    } catch (error) {
      console.error('❌ Failed to process limited copy:', error.message);
      throw error;
    }
  }

  /**
   * Get all user tables from the database
   */
  async getUserTables() {
    const query = `
      SELECT table_name
      FROM information_schema.tables
      WHERE table_schema = 'public'
        AND table_type = 'BASE TABLE'
        AND table_name NOT LIKE 'SequelizeMeta'
      ORDER BY table_name;
    `;

    const result = await this.client.query(query);
    return result.rows.map(row => row.table_name);
  }

  /**
   * Limit a table to 1000 records, keeping the most recent ones
   */
  async limitTableRecords(tableName) {
    try {
      // First, check if table has more than 1000 records
      const countQuery = `SELECT COUNT(*) as count FROM "${tableName}"`;
      const countResult = await this.client.query(countQuery);
      const totalRecords = parseInt(countResult.rows[0].count);

      if (totalRecords <= 1000) {
        return 0; // No records to remove
      }

      // Check if table has 'created_at' or 'id' column for ordering
      const orderBy = await this.getOrderColumn(tableName);
      if (!orderBy) {
        console.log(`  ⚠️  ${tableName}: No suitable ordering column found, skipping`);
        return 0;
      }

      // Delete excess records, keeping the most recent 1000
      const deleteQuery = `
        DELETE FROM "${tableName}"
        WHERE ${orderBy} NOT IN (
          SELECT ${orderBy}
          FROM "${tableName}"
          ORDER BY ${orderBy} DESC
          LIMIT 1000
        )
      `;

      const deleteResult = await this.client.query(deleteQuery);
      return deleteResult.rowCount || 0;

    } catch (error) {
      console.log(`  ⚠️  ${tableName}: Error limiting records - ${error.message}`);
      return 0;
    }
  }

  /**
   * Determine the best column for ordering records (prefer created_at, fallback to id)
   */
  async getOrderColumn(tableName) {
    try {
      const columnsQuery = `
        SELECT column_name, data_type
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = $1
          AND column_name IN ('created_at', 'id', 'updated_at')
        ORDER BY
          CASE column_name
            WHEN 'created_at' THEN 1
            WHEN 'updated_at' THEN 2
            WHEN 'id' THEN 3
          END;
      `;

      const result = await this.client.query(columnsQuery, [tableName]);

      if (result.rows.length > 0) {
        return `"${result.rows[0].column_name}"`;
      }

      return null;
    } catch (error) {
      return null;
    }
  }

  /**
   * Get database statistics before/after processing
   */
  async getDatabaseStats() {
    try {
      const query = `
        SELECT
          schemaname,
          tablename,
          n_tup_ins as inserts,
          n_tup_upd as updates,
          n_tup_del as deletes,
          n_live_tup as live_tuples,
          n_dead_tup as dead_tuples
        FROM pg_stat_user_tables
        ORDER BY n_live_tup DESC;
      `;

      const result = await this.client.query(query);
      return result.rows;
    } catch (error) {
      console.error('Failed to get database stats:', error.message);
      return [];
    }
  }

  /**
   * Analyze database after processing to update statistics
   */
  async analyzeDatabase() {
    try {
      console.log('🔄 Analyzing database to update statistics...');
      await this.client.query('ANALYZE;');
      console.log('✅ Database analysis complete');
    } catch (error) {
      console.error('⚠️  Database analysis failed:', error.message);
    }
  }
}

module.exports = CopyProcessor;