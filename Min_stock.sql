DECLARE @BrandID    VARCHAR(MAX) = 32;
DECLARE @DealerID   VARCHAR(MAX);
DECLARE @max        INT;                   
DECLARE @td         INT;                    
DECLARE @Perc       NVARCHAR(20);       

SET @max = 1;                    
SELECT @td = COUNT(DISTINCT dealerid) 
FROM Dealer_Workshop_Master
WHERE BrandID = @BrandID AND Status = 1  ;

-- Display total dealers
PRINT CONCAT('In This BrandID ', @BrandID, ' TOTAL NO OF Dealers= ', @td);


declare @Grouptbl varchar(MAX);

DECLARE @sql NVARCHAR(MAX);
DECLARE @D1 NVARCHAR(MAX), @D2 NVARCHAR(MAX), @D3 NVARCHAR(MAX), @D4 NVARCHAR(MAX), @D5 NVARCHAR(MAX), @D6 NVARCHAR(MAX), @D7 NVARCHAR(MAX);

-- Set the dates for the last 7 days
    SELECT @D1 = FORMAT(DATEADD(MONTH, -1, GETDATE()), 'MMMyyyy');
    SELECT @D2 = FORMAT(DATEADD(MONTH, -2, GETDATE()), 'MMMyyyy');
    SELECT @D3 = FORMAT(DATEADD(MONTH, -3, GETDATE()), 'MMMyyyy');
    SELECT @D4 = FORMAT(DATEADD(MONTH, -4, GETDATE()), 'MMMyyyy');
    SELECT @D5 = FORMAT(DATEADD(MONTH, -5, GETDATE()), 'MMMyyyy');
    SELECT @D6 = FORMAT(DATEADD(MONTH, -6, GETDATE()), 'MMMyyyy');
    SELECT @D7 = FORMAT(DATEADD(MONTH, 0, GETDATE()), 'MMMyyyy');

--------------------- table create and drop table

set @Grouptbl = 'Uad_minstk_6m_'+@brandid
print (@Grouptbl)

SET @sql = '
    ALTER TABLE ' + (@Grouptbl) + '
    DROP COLUMN ' + QUOTENAME(@D6) + ';
    ALTER TABLE ' + (@Grouptbl) + '
    ADD ' + QUOTENAME(@D6) + 'Nvarchar(Max);

				
/*Create Table '+@Grouptbl+' (
                Dealer Varchar(max),
Location Varchar(max),
PARTNUMBER Varchar(Max),
PARTDESC Varchar(Max),
CATEGORY Varchar(Max),                                     
LANDEDCOST Decimal(18,2),
MRP Decimal(18,2),
MOQ Decimal(18,2),
                ' + QUOTENAME(@D1) + ' DECIMAL(10, 2),
				' + QUOTENAME(@D2) + ' DECIMAL(10, 2),
				' + QUOTENAME(@D3) + ' DECIMAL(10, 2),
				' + QUOTENAME(@D4) + ' DECIMAL(10, 2),
				' + QUOTENAME(@D5) + ' DECIMAL(10, 2),
				' + QUOTENAME(@D6) + ' DECIMAL(10, 2),
				' + QUOTENAME(@D7) + ' DECIMAL(10, 2)
            );*/' 
--PRINT @SQL  

EXEC sp_executesql @sql;



WHILE(@max <= @td)
BEGIN
    -- Get the dealerid for current iteration
    SELECT @DealerID = DealerID 
    FROM (
        SELECT DealerID, ROW_NUMBER() OVER (ORDER BY DealerID ASC) AS m
        FROM (
            SELECT DealerID, ROW_NUMBER() OVER (PARTITION BY DealerID ORDER BY DealerID ASC) AS w
            FROM Dealer_Workshop_Master
            WHERE BrandID = @BrandID AND Status = 1
        ) AS td
        WHERE w = 1
    ) AS tes
    WHERE m = @max;

    PRINT(@max);
    PRINT(@DealerID);

    -- Set dynamic stock table name
    DECLARE @Stktbl NVARCHAR(MAX);
  --  DECLARE @sql NVARCHAR(MAX);
    

    -- Set the dynamic date labels (MMMyyyy format)
      -- Current month

    SET @Stktbl = 'stock_upload_spm_td001_' + @DealerID;

    -- Build the dynamic SQL query
    SET @sql =' insert into ' + (@Grouptbl) + ' (Dealer,Location,Partnumber,Partdesc,Category,LandedCost,MRP,MOQ,
	'+@D1+','+@D2+','+@D3+','+@D4+','+@D5+','+@D6+','+@D7+')
    SELECT 
        l.Dealer,
        l.Location,
        s.PARTNUMBER,
        pm.PARTDESC,
        pm.CATEGORY,
        pm.LANDEDCOST,
        pm.MRP,
        pm.MOQ,
        ISNULL(MIN(CASE WHEN FORMAT(s.Stockdate, ''MMMyyyy'') = ''' + @D1 + ''' THEN s.Qty ELSE NULL END), 0) AS ' + @D1 + ',
        ISNULL(MIN(CASE WHEN FORMAT(s.Stockdate, ''MMMyyyy'') = ''' + @D2 + ''' THEN s.Qty ELSE NULL END), 0) AS ' + @D2 + ',
        ISNULL(MIN(CASE WHEN FORMAT(s.Stockdate, ''MMMyyyy'') = ''' + @D3 + ''' THEN s.Qty ELSE NULL END), 0) AS ' + @D3 + ',
        ISNULL(MIN(CASE WHEN FORMAT(s.Stockdate, ''MMMyyyy'') = ''' + @D4 + ''' THEN s.Qty ELSE NULL END), 0) AS ' + @D4 + ',
        ISNULL(MIN(CASE WHEN FORMAT(s.Stockdate, ''MMMyyyy'') = ''' + @D5 + ''' THEN s.Qty ELSE NULL END), 0) AS ' + @D5 + ',
        ISNULL(MIN(CASE WHEN FORMAT(s.Stockdate, ''MMMyyyy'') = ''' + @D6 + ''' THEN s.Qty ELSE NULL END), 0) AS ' + @D6 + ',
        ISNULL(MIN(CASE WHEN FORMAT(s.Stockdate, ''MMMyyyy'') = ''' + @D7 + ''' THEN s.Qty ELSE NULL END), 0) AS ' + @D7 + '
    FROM ' + @Stktbl + ' AS s
    inner JOIN locationinfo AS l ON s.locationid = l.locationid AND s.dealerid = l.dealerid
    inner JOIN PART_MASTER pm ON pm.PARTNUMBER = s.PARTNUMBER AND pm.brandid = s.brandid
    WHERE s.Stockdate >= CAST(DATEADD(MONTH, -6, GETDATE()) AS DATE)  -- Last 7 months
        AND l.status = 1 
    GROUP BY l.Dealer, l.Location, s.PARTNUMBER, pm.PARTDESC, pm.CATEGORY, pm.LANDEDCOST, pm.MRP, pm.MOQ
    ORDER BY l.Dealer, l.Location, s.PARTNUMBER';

    -- Uncomment to debug and check the dynamic SQL query
    -- PRINT @sql;

    -- Execute the dynamic SQL query
    EXEC sp_executesql @sql;

    -- Increment the max variable for the next dealer
    SET @max = @max + 1;
END


-- select * from Uad_minstk_6m_32








