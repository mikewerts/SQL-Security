--insert into [DBA].[dbo].[server_roles_securables_group_users] 
			SELECT *
			FROM OPENQUERY([DEV-ITSQL-01\APTSQL],'
 SELECT
        [ServerName] = ''DEV-ITSQL-01\APTSQL'',
		[UserName] = memberprinc.[name],
		[LoginType] = CASE roleprinc.[type]
								WHEN ''S'' THEN ''SQL User''
								WHEN ''U'' THEN ''Windows User''
								when ''G'' then ''AD Group''
							 END, 
        [DatabaseUserName] = memberprinc.[name],
        [Role]             = roleprinc.[name],
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
        
		--Role/member associations
    sys.server_role_members members
	--sys.syslogins sys_login
	JOIN
    --Roles
    sys.server_principals roleprinc ON roleprinc.[principal_id] = members.[role_principal_id]
	right JOIN
    --Role members (server logins)
    sys.server_principals memberprinc ON memberprinc.[principal_id] = members.[member_principal_id]




        --LEFT JOIN sys.server_principals    AS ulogin    ON ulogin.[sid] = princ.[sid]
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
        roleprinc.[type] IN (''S'',''U'',''G'')
        -- No need for these system accounts
        AND roleprinc.[name] NOT IN (''sys'', ''INFORMATION_SCHEMA'')			


')