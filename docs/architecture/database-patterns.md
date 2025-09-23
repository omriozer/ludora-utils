# Hybrid Database Patterns: JSONB + Structured Tables

This document outlines the hybrid database approach used in Ludora's game creation system, combining flexible JSONB storage with queryable structured tables.

## Overview

### Architecture Principles

1. **Single Source of Truth**: `game.game_settings` JSONB column contains complete settings
2. **Selective Normalization**: Critical queryable data extracted to structured tables
3. **Plugin-Driven**: Each game type plugin defines what should be normalized
4. **Data Integrity**: Sync service maintains consistency between JSONB and structured data

## JSONB Indexing Strategies

### Basic JSONB Indexes

```sql
-- Index commonly queried settings across all game types
CREATE INDEX idx_game_settings_type ON game
USING GIN ((game_settings->'type'));

-- Index nested boolean settings
CREATE INDEX idx_game_settings_published ON game
USING GIN ((game_settings->'is_published'));

-- Index numeric settings with conditional indexing
CREATE INDEX idx_memory_pairs_count ON game
USING BTREE (((game_settings->>'pairs_count')::int))
WHERE game_type = 'memory_game';

-- Index array containment for tags/skills
CREATE INDEX idx_game_settings_tags ON game
USING GIN ((game_settings->'tags'));
```

### Game-Type Specific Indexes

```sql
-- Memory Game Indexes
CREATE INDEX idx_memory_difficulty_progression ON game
USING GIN ((game_settings->'difficulty_progression'->'enabled'))
WHERE game_type = 'memory_game';

CREATE INDEX idx_memory_match_time ON game
USING BTREE (((game_settings->>'match_time_limit')::int))
WHERE game_type = 'memory_game'
AND game_settings->>'match_time_limit' IS NOT NULL;

-- Scatter Game Indexes
CREATE INDEX idx_scatter_grid_size ON game
USING BTREE (((game_settings->>'grid_size')::int))
WHERE game_type = 'scatter_game';

CREATE INDEX idx_scatter_difficulty ON game
USING HASH ((game_settings->>'difficulty_level'))
WHERE game_type = 'scatter_game';

-- Composite indexes for complex queries
CREATE INDEX idx_memory_pairs_and_time ON game
USING BTREE (
  ((game_settings->>'pairs_count')::int),
  ((game_settings->>'match_time_limit')::int)
)
WHERE game_type = 'memory_game';
```

### Expression Indexes for Complex Queries

```sql
-- Index calculated values
CREATE INDEX idx_estimated_difficulty ON game
USING BTREE (
  CASE game_type
    WHEN 'memory_game' THEN (game_settings->>'pairs_count')::int *
                           (CASE WHEN game_settings->>'match_time_limit' IS NULL
                                 THEN 1 ELSE (30 / (game_settings->>'match_time_limit')::int) END)
    WHEN 'scatter_game' THEN (game_settings->>'grid_size')::int *
                            (game_settings->>'words_per_level')::int
    ELSE 1
  END
);

-- Index for analytics queries
CREATE INDEX idx_game_complexity_score ON game
USING BTREE (
  (COALESCE((game_settings->>'pairs_count')::int, 0) +
   COALESCE((game_settings->>'grid_size')::int, 0) +
   COALESCE(jsonb_array_length(game_settings->'content_stages'), 0))
);
```

## Query Examples

### Efficient JSONB Queries

```sql
-- Find memory games with specific pair counts
SELECT id, title, game_settings->'pairs_count' as pairs
FROM game
WHERE game_type = 'memory_game'
  AND (game_settings->>'pairs_count')::int BETWEEN 6 AND 12;

-- Find games with difficulty progression enabled
SELECT id, title, game_settings->'difficulty_progression' as progression
FROM game
WHERE game_type = 'memory_game'
  AND game_settings->'difficulty_progression'->>'enabled' = 'true';

-- Complex memory game analytics
SELECT
  (game_settings->>'pairs_count')::int as pair_count,
  COUNT(*) as game_count,
  AVG((game_settings->>'match_time_limit')::int) as avg_time_limit
FROM game
WHERE game_type = 'memory_game'
  AND game_settings->>'match_time_limit' IS NOT NULL
GROUP BY (game_settings->>'pairs_count')::int
ORDER BY pair_count;
```

### Hybrid Queries (JSONB + Structured)

```sql
-- Find memory games with complex pairing rules
SELECT
  g.id,
  g.title,
  g.game_settings->'pairs_count' as total_pairs,
  COUNT(mpr.id) as rule_count,
  array_agg(mpr.rule_type) as rule_types
FROM game g
JOIN memory_pairing_rules mpr ON g.id = mpr.game_id
WHERE g.game_type = 'memory_game'
  AND mpr.is_active = true
GROUP BY g.id, g.title, g.game_settings->'pairs_count'
HAVING COUNT(mpr.id) > 1;

-- Analytics: Games by complexity and rule sophistication
WITH game_complexity AS (
  SELECT
    g.id,
    g.title,
    (g.game_settings->>'pairs_count')::int as pairs,
    COUNT(mpr.id) as rule_count,
    COUNT(mmp.id) as manual_pair_count
  FROM game g
  LEFT JOIN memory_pairing_rules mpr ON g.id = mpr.game_id AND mpr.is_active = true
  LEFT JOIN manual_memory_pairs mmp ON mpr.id = mmp.pairing_rule_id
  WHERE g.game_type = 'memory_game'
  GROUP BY g.id, g.title, g.game_settings->'pairs_count'
)
SELECT
  CASE
    WHEN pairs <= 6 AND rule_count <= 1 THEN 'Simple'
    WHEN pairs <= 10 AND rule_count <= 2 THEN 'Intermediate'
    ELSE 'Complex'
  END as complexity_level,
  COUNT(*) as game_count,
  AVG(pairs) as avg_pairs,
  AVG(rule_count) as avg_rules
FROM game_complexity
GROUP BY complexity_level;
```

### Performance-Optimized Reporting Queries

```sql
-- Fast aggregation using indexes
SELECT
  game_type,
  COUNT(*) as total_games,
  COUNT(CASE WHEN is_published = true THEN 1 END) as published_games,
  AVG(CASE
    WHEN game_type = 'memory_game' THEN (game_settings->>'pairs_count')::int
    WHEN game_type = 'scatter_game' THEN (game_settings->>'words_per_level')::int
    ELSE NULL
  END) as avg_difficulty_metric
FROM game
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY game_type;

-- Content usage analytics with JSONB operators
SELECT
  content_type,
  COUNT(DISTINCT g.id) as games_using,
  AVG((g.game_settings->>'pairs_count')::int) as avg_pairs_when_used
FROM game g
CROSS JOIN jsonb_array_elements(g.game_settings->'content_stages') as stage(stage_data)
CROSS JOIN jsonb_array_elements(stage_data->'contentConnection'->'content') as content(content_data)
JOIN content_list cl ON cl.id = (content_data->>'id')
WHERE g.game_type = 'memory_game'
  AND g.game_settings->>'pairs_count' IS NOT NULL
GROUP BY content_type
HAVING COUNT(DISTINCT g.id) >= 5;
```

## Best Practices

### Index Maintenance

1. **Monitor Query Performance**: Use `EXPLAIN ANALYZE` to validate index usage
2. **Selective Indexing**: Only index frequently queried JSONB paths
3. **Composite Indexes**: Combine multiple JSONB fields for common query patterns
4. **Conditional Indexes**: Use `WHERE` clauses to index only relevant rows

### Query Optimization

1. **Type Casting**: Always cast JSONB values to appropriate types for comparisons
2. **Null Handling**: Use `IS NOT NULL` checks before casting
3. **Index Hints**: Structure queries to use existing indexes
4. **Limit Result Sets**: Use appropriate `LIMIT` and `OFFSET` for pagination

### Schema Evolution

1. **Versioning**: Include version numbers in game_settings for migrations
2. **Backward Compatibility**: Support multiple setting formats during transitions
3. **Gradual Migration**: Migrate structured data progressively
4. **Validation**: Implement consistency checks between JSONB and structured data

## Migration Scripts

### Adding New Indexes

```sql
-- Add new index with minimal locking
CREATE INDEX CONCURRENTLY idx_new_game_setting ON game
USING BTREE ((game_settings->>'new_field'))
WHERE game_type = 'specific_type';

-- Drop old index after new one is built
DROP INDEX IF EXISTS idx_old_game_setting;
```

### Backfilling Structured Data

```sql
-- Backfill missing structured data from JSONB
INSERT INTO memory_pairing_rules (id, game_id, rule_type, pair_config, created_at, updated_at)
SELECT
  'backfill_' || g.id || '_' || generate_random_uuid(),
  g.id,
  'content_type_match',
  '{"auto_generated": true}'::jsonb,
  NOW(),
  NOW()
FROM game g
WHERE g.game_type = 'memory_game'
  AND NOT EXISTS (
    SELECT 1 FROM memory_pairing_rules mpr WHERE mpr.game_id = g.id
  )
  AND g.game_settings->'pairing_rules' IS NULL;
```

This hybrid approach provides the flexibility of JSONB with the queryability of structured tables, optimized for both development velocity and analytical performance.