				SELECT *
				FROM OPENQUERY([DEV-ITSQL-01\APTSQL],'
	
				SELECT 
				  
				 [ServerName] = ''DEV-ITSQL-01\APTSQL'',
				  [Database Name] = ''AS400'',
				[UserName] = princ.[name] collate SQL_Latin1_General_CP1_CI_AS,
				[LoginName] = svprinc.[name] collate SQL_Latin1_General_CP1_CI_AS,
				[UserType] = CASE princ.[type] 
								WHEN ''S'' THEN ''SQL User''
								WHEN ''U'' THEN ''Windows User''
								when ''G'' then ''AD Group''
							 END,  
				[GroupUserName] = null,       
				[Role] = null,      
				[PermissionType] = perm.[permission_name] collate SQL_Latin1_General_CP1_CI_AS,       
				[PermissionState] = perm.[state_desc] collate SQL_Latin1_General_CP1_CI_AS,       
				[ObjectType] = obj.type_desc collate SQL_Latin1_General_CP1_CI_AS,--perm.[class_desc],       
				[ObjectName] = OBJECT_NAME(perm.major_id) collate SQL_Latin1_General_CP1_CI_AS,
				[ColumnName] = col.[name] collate SQL_Latin1_General_CP1_CI_AS
			FROM    
				[AS400].sys.database_principals princ  
			--JOIN #endpoint e on e.[name] = princ.[name]	
			left join sys.server_principals svprinc on princ.[sid] = svprinc.[sid] 
			LEFT JOIN
				[AS400].sys.login_token ulogin on princ.[sid] = ulogin.[sid]
			LEFT JOIN        
				[AS400].sys.database_permissions perm ON perm.[grantee_principal_id] = princ.[principal_id]
			LEFT JOIN
				[AS400].sys.columns col ON col.[object_id] = perm.major_id 
								AND col.[column_id] = perm.[minor_id]
			LEFT JOIN
				[AS400].sys.objects obj ON perm.[major_id] = obj.[object_id] 
			WHERE 
				princ.[type] in (''S'',''U'')
				

				/* add any principals to further qualify */


			UNION


				SELECT 
			[ServerName] = ''DEV-ITSQL-01\APTSQL'',
				  [Database Name] = ''AS400'',
				[UserName] = memberprinc.[name] collate SQL_Latin1_General_CP1_CI_AS,
				[LoginName] = svprinc.[name] collate SQL_Latin1_General_CP1_CI_AS,
				[UserType] = CASE memberprinc.[type]
								WHEN ''S'' THEN ''SQL User''
								WHEN ''U'' THEN ''Windows User''
								when ''G'' then ''AD Group''
								END, 
				[GroupUserName] = null, -- = memberprinc.[name] collate SQL_Latin1_General_CP1_CI_AS,   
				[Role] = roleprinc.[name] collate SQL_Latin1_General_CP1_CI_AS,   
				[PermissionType] = perm.[permission_name] collate SQL_Latin1_General_CP1_CI_AS,       
				[PermissionState] = perm.[state_desc] collate SQL_Latin1_General_CP1_CI_AS,       
				[ObjectType] = obj.type_desc,--perm.[class_desc] collate SQL_Latin1_General_CP1_CI_AS,   
				[ObjectName] = OBJECT_NAME(perm.major_id) collate SQL_Latin1_General_CP1_CI_AS,
				[ColumnName] = col.[name] collate SQL_Latin1_General_CP1_CI_AS  

					FROM    
						[AS400].sys.database_role_members members
					
					JOIN
						[AS400].sys.database_principals roleprinc ON roleprinc.[principal_id] = members.[role_principal_id]

					JOIN
						[AS400].sys.database_principals memberprinc ON memberprinc.[principal_id] = members.[member_principal_id]

					left join sys.server_principals svprinc on memberprinc.[sid] = svprinc.[sid] 
			



					--JOIN #endpoint e on e.[name] = memberprinc.[name]
					LEFT JOIN
						[AS400].sys.login_token ulogin on memberprinc.[sid] = ulogin.[sid]
					LEFT JOIN        
						[AS400].sys.database_permissions perm ON perm.[grantee_principal_id] = roleprinc.[principal_id]
					LEFT JOIN
						[AS400].sys.columns col on col.[object_id] = perm.major_id 
								AND col.[column_id] = perm.[minor_id]
					LEFT JOIN
						[AS400].sys.objects obj ON perm.[major_id] = obj.[object_id]

					where memberprinc.[type] in (''S'',''U'') 
	')

			--insert into [DBA].[dbo].[db_roles_securables_group_users] 
			SELECT *
			FROM OPENQUERY([DEV-ITSQL-01\APTSQL],'
	
			SELECT 
				  
				 [ServerName] = ''DEV-ITSQL-01\APTSQL'',
				  [Database Name] = ''AS400'',
				[UserName] = get_xp_login.[account name] collate SQL_Latin1_General_CP1_CI_AS,
				[LoginName] = get_xp_login.[account name] collate SQL_Latin1_General_CP1_CI_AS,
				[UserType] = CASE princ.[type]
								WHEN ''S'' THEN ''SQL User''
								WHEN ''U'' THEN ''Windows User''
								when ''G'' then ''AD Group''
							 END,  
				[GroupUserName] = princ.[name] collate SQL_Latin1_General_CP1_CI_AS,       
				[Role] = null,      
				[PermissionType] = perm.[permission_name] collate SQL_Latin1_General_CP1_CI_AS,       
				[PermissionState] = perm.[state_desc] collate SQL_Latin1_General_CP1_CI_AS,       
				[ObjectType] = obj.type_desc,--perm.[class_desc] collate SQL_Latin1_General_CP1_CI_AS,       
				[ObjectName] = OBJECT_NAME(perm.major_id) collate SQL_Latin1_General_CP1_CI_AS,
				[ColumnName] = col.[name] collate SQL_Latin1_General_CP1_CI_AS
			FROM    
				[AS400].sys.database_principals princ  
			--JOIN #endpoint e on e.[name]  = princ.[name]	
			LEFT JOIN
				[AS400].sys.login_token ulogin on princ.[sid] = ulogin.[sid]
			LEFT JOIN        
				[AS400].sys.database_permissions perm ON perm.[grantee_principal_id] = princ.[principal_id]
			LEFT JOIN
				[AS400].sys.columns col ON col.[object_id] = perm.major_id 
								AND col.[column_id] = perm.[minor_id]
			LEFT JOIN
				[AS400].sys.objects obj  ON perm.[major_id] = obj.[object_id]
			left join 
				[DBA].[dbo].[get_xp_logininfo] get_xp_login 
			on princ.name collate SQL_Latin1_General_CP1_CI_AS = get_xp_login.[permission path]

			WHERE 
				princ.[type] = (''G'')
				

				/* add any principals to further qualify */


			UNION


				SELECT 
			[ServerName] = ''DEV-ITSQL-01\APTSQL'',
				  [Database Name] = ''AS400'',
				[UserName] = get_xp_login.[account name] collate SQL_Latin1_General_CP1_CI_AS,
				[LoginName] = get_xp_login.[account name] collate SQL_Latin1_General_CP1_CI_AS,
				[UserType] = CASE memberprinc.[type]
								WHEN ''S'' THEN ''SQL User''
								WHEN ''U'' THEN ''Windows User''
								when ''G'' then ''AD Group''
								END, 
				[GroupUserName] = memberprinc.[name] collate SQL_Latin1_General_CP1_CI_AS,   
				[Role] = roleprinc.[name] collate SQL_Latin1_General_CP1_CI_AS,   
				[PermissionType] = perm.[permission_name] collate SQL_Latin1_General_CP1_CI_AS,       
				[PermissionState] = perm.[state_desc] collate SQL_Latin1_General_CP1_CI_AS,       
				[ObjectType] = obj.type_desc,--perm.[class_desc] collate SQL_Latin1_General_CP1_CI_AS,   
				[ObjectName] = OBJECT_NAME(perm.major_id) collate SQL_Latin1_General_CP1_CI_AS,
				[ColumnName] = col.[name]  

					FROM    
						[AS400].sys.database_role_members members
					JOIN
						[AS400].sys.database_principals roleprinc ON roleprinc.[principal_id] = members.[role_principal_id]
					JOIN
						[AS400].sys.database_principals memberprinc ON memberprinc.[principal_id] = members.[member_principal_id]
					--JOIN #endpoint e on e.[name] = memberprinc.[name]
					LEFT JOIN
						[AS400].sys.login_token ulogin on memberprinc.[sid] = ulogin.[sid]
					LEFT JOIN        
						[AS400].sys.database_permissions perm ON perm.[grantee_principal_id] = roleprinc.[principal_id]
					LEFT JOIN
						[AS400].sys.columns col on col.[object_id] = perm.major_id 
								AND col.[column_id] = perm.[minor_id]
					LEFT JOIN
						[AS400].sys.objects obj ON perm.[major_id] = obj.[object_id]
							left join 
				[DBA].[dbo].[get_xp_logininfo] get_xp_login
			on memberprinc.name collate SQL_Latin1_General_CP1_CI_AS = get_xp_login.[permission path]

					where memberprinc.[type]  = (''G'')
	')