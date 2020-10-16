IF OBJECT_ID('tempdb..#sql') IS NOT NULL DROP TABLE #sql

CREATE TABLE #sql ([line] BIGINT, [columns] BIGINT, [sql] NVARCHAR(MAX)) WITH (HEAP)

INSERT INTO #sql([line], [columns], [sql])
SELECT
	[line] = ROW_NUMBER() OVER (ORDER BY s.name, t.name),
	[columns] = COUNT(DISTINCT c.column_id),
	[sql] = CONCAT
	(
		'IF EXISTS (SELECT * FROM sys.stats WHERE [name] = ''',
		'stats_all_',
		REPLACE(REPLACE(QUOTENAME(s.name), '[', ''), ']', ''),
		'_',
		REPLACE(REPLACE(QUOTENAME(t.name), '[', ''), ']', ''),
		''') DROP STATISTICS ',
		QUOTENAME(s.name),
		'.',
		QUOTENAME(t.name),
		'.',
		'[stats_all_',
		REPLACE(REPLACE(QUOTENAME(s.name), '[', ''), ']', ''),
		'_',
		REPLACE(REPLACE(QUOTENAME(t.name), '[', ''), ']', ''),
		']; ',
		'CREATE STATISTICS [stats_all_',
		REPLACE(REPLACE(QUOTENAME(s.name), '[', ''), ']', ''),
		'_',
		REPLACE(REPLACE(QUOTENAME(t.name), '[', ''), ']', ''),
		'] ON ',
		QUOTENAME(s.name),
		'.',
		QUOTENAME(t.name),
		' (',
		STRING_AGG(QUOTENAME(c.name), ', ') WITHIN GROUP (ORDER BY c.column_id),
		') WITH FULLSCAN;'
	)
FROM
	sys.tables t
	INNER JOIN sys.columns c ON
		t.object_id = c.object_id AND
		c.column_id <= 32
	INNER JOIN sys.schemas s ON
		t.schema_id = s.schema_id
GROUP BY
	s.name, t.name

SELECT [sql] FROM #sql ORDER BY [line]

DROP TABLE #sql
