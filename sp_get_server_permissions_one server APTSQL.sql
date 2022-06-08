EXEC SP_DESCRIBE_FIRST_RESULT_SET N'  
 
 SELECT
        [ServerName] = ''DEV-ITSQL-01\APTSQL'',
		[UserName] = memberprinc.[name],
		[LoginType] = CASE memberprinc.[type]
								WHEN ''S'' THEN ''SQL User''
								WHEN ''U'' THEN ''Windows User''
								when ''G'' then ''AD Group''
							 END, 
        [GroupUserName] = null,
        [Role]             = roleprinc.[name],
        [PermissionType]   = null,
        [PermissionState]  = null,
        [ObjectType] = null,
        [Schema] = null,
        [ObjectName] = null,
        [ColumnName] = null
    FROM
        

    sys.server_role_members members
	JOIN
    sys.server_principals roleprinc ON roleprinc.[principal_id] = members.[role_principal_id]
	JOIN
    sys.server_principals memberprinc ON memberprinc.[principal_id] = members.[member_principal_id]




        --LEFT JOIN sys.server_principals    AS ulogin    ON ulogin.[sid] = princ.[sid]
        --Permissions
        --LEFT JOIN sys.server_permissions AS perm      ON perm.[grantee_principal_id] = memberprinc.[principal_id]
        --LEFT JOIN sys.schemas              AS permschem ON permschem.[schema_id] = perm.[major_id]
        --LEFT JOIN sys.objects              AS obj       ON obj.[object_id] = perm.[major_id]
        --LEFT JOIN sys.schemas              AS objschem  ON objschem.[schema_id] = obj.[schema_id]
        ----Table columns
        --LEFT JOIN sys.columns              AS col       ON col.[object_id] = perm.[major_id]
        --                                                   AND col.[column_id] = perm.[minor_id]
        ----Impersonations
        --LEFT JOIN sys.server_principals  AS imp       ON imp.[principal_id] = perm.[major_id]
    WHERE
        memberprinc.[type] IN (''S'',''U'')
        -- No need for these system accounts
        AND memberprinc.[name] NOT IN (''sys'', ''INFORMATION_SCHEMA'')	

		


 
 SELECT
        [ServerName] = ''DEV-ITSQL-01\APTSQL'',
		[UserName] = princ.[name],
		[LoginType] = CASE princ.[type]
								WHEN ''S'' THEN ''SQL User''
								WHEN ''U'' THEN ''Windows User''
								when ''G'' then ''AD Group''
							 END, 
        [GroupUserName] = null,
        [Role]             = null,
        [PermissionType]   = perm.[permission_name],
        [PermissionState]  = perm.[state_desc],
        [ObjectType] = CASE perm.[class]
                           WHEN 1 THEN obj.[type_desc]        -- Schema-contained objects
                           ELSE perm.[class_desc]             -- Higher-level objects
                       END,
        [Schema] = objschem.[name],
        [ObjectName] = CASE perm.[class]
                           WHEN 3 THEN permschem.[name]       -- Schemas
                           WHEN 4 THEN imp.[name]             -- Impersonations
                           ELSE OBJECT_NAME(perm.[major_id])  -- General objects
                       END,
        [ColumnName] = col.[name]
    FROM
        

 --   sys.server_role_members members
	--JOIN
 --   sys.server_principals roleprinc ON roleprinc.[principal_id] = members.[role_principal_id]
	--right JOIN
 --   sys.server_principals memberprinc ON memberprinc.[principal_id] = members.[member_principal_id]

 sys.server_principals            AS princ


        LEFT JOIN sys.server_principals    AS ulogin    ON ulogin.[sid] = princ.[sid]
        --Permissions
        LEFT JOIN sys.server_permissions AS perm      ON perm.[grantee_principal_id] = princ.[principal_id]
        LEFT JOIN sys.schemas              AS permschem ON permschem.[schema_id] = perm.[major_id]
        LEFT JOIN sys.objects              AS obj       ON obj.[object_id] = perm.[major_id]
        LEFT JOIN sys.schemas              AS objschem  ON objschem.[schema_id] = obj.[schema_id]
        --Table columns
        LEFT JOIN sys.columns              AS col       ON col.[object_id] = perm.[major_id]
                                                           AND col.[column_id] = perm.[minor_id]
        --Impersonations
        LEFT JOIN sys.server_principals  AS imp       ON imp.[principal_id] = perm.[major_id]
    WHERE
        princ.[type] IN (''S'',''U'')
        -- No need for these system accounts
        AND princ.[name] NOT IN (''sys'', ''INFORMATION_SCHEMA'')			
		'