
USE [DBA]

go

Drop procedure if exists [dbo].[sp_get_server_permissions]
go

CREATE procedure [dbo].[sp_get_server_permissions]


--@sqlrole nvarchar(100)

as



declare @db_name nvarchar(max);
declare @ad_name nvarchar(max);
declare @windows_user nvarchar(max);
declare @AD_Group nvarchar(max);
declare @endpoint_name nvarchar(max);
declare @SQL_user nvarchar(max); 
declare @sqlstr as nvarchar(max); 
declare @sqlstr2 as nvarchar(max); 
declare @sqlstr3 as nvarchar(max); 
declare @sqlstr4 as nvarchar(max);
declare @sqlstr5 as nvarchar(max);
declare @sqlstr6 as nvarchar(max);
declare @sql nvarchar(max);
declare @server_name sysname;
/* set params for major version */
declare @sqlmajorversion as nvarchar(max);
declare @majversion int;
declare @majversionparam NVARCHAR(MAX) = '@majorval int output';

/* set params for sql endpoint */
declare @sqlendpoint as nvarchar(max);
declare @endpoint as nvarchar(max);
declare @endpointparam NVARCHAR(MAX) = '@endpointval NVARCHAR(MAX) output';

/*set params for database name */

declare @sqldbname as nvarchar(max);
--declare @dbname as nvarchar(max);
declare @dbpointparam NVARCHAR(MAX) = '@dbval NVARCHAR(MAX) output';

--declare @servername as nvarchar(max);



/* create the temp table to insert permissions */
declare @insertstring as nvarchar(max);
declare @inserttable table
(
			[ServerName] nvarchar(500),
			[DatabaseName] nvarchar(500) null,
			[UserName] nvarchar(500), 
			[UserType] nvarchar(500),
			[DatabaseUserName] nvarchar(500),   
			[Role] nvarchar(500),
  
    [PermissionType] nvarchar(500), -- = perm.[permission_name],       
    [PermissionState] nvarchar(500),-- = perm.[state_desc],       
    [ObjectType] nvarchar(500),-- = obj.type_desc,--perm.[class_desc],       
    [ObjectName] nvarchar(500), --= OBJECT_NAME(perm.major_id),
    [ColumnName]  nvarchar(500) --= col.[name]

);
	
/* get the linked servers */

--declare @endpoint as nvarchar(max) 

declare servers_cursor  cursor for
select srvname from master.dbo.sysservers
where isremote = 0
and providername = 'SQLOLEDB'
order by srvname

open servers_cursor

fetch servers_cursor into @server_name
while @@fetch_status = 0 begin
	
	/* 1 - get the endpoint if it exists or return the servername */  
	
	--declare @majorval int

	set @sqlmajorversion = '
	select @majorval = (SELECT *
	FROM OPENQUERY(['+@server_name+'],''
	select cast(SERVERPROPERTY(''''ProductMajorVersion'''') as int)
	''))'

	begin try

	exec sp_executesql @sqlmajorversion, @majversionparam, @majorval = @majversion     OUTPUT

	end try

				BEGIN CATCH  
						--print @server_name; 
						print 
						'Error:' 
						+ char(10) 
						+ 'Server ' + @@servername
						+ char(10)
						+ 'Error Number ' + cast									(ERROR_NUMBER() as nvarchar) 
						+ char(10)
						+ 'Error Message ' + ERROR_MESSAGE();	
	
					END CATCH;
	--print @sqlmajorversion



	--print @sqlmajorversion
	--PRINT @server_name 
	--print @majversion


/* 2. If this is SQL Server 2012 or above, check for availability group listener */
--print @majversion

	if @majversion > 10
	begin

		begin try

		set @sqlendpoint = '
		select @endpointval = (SELECT *
		FROM OPENQUERY(['+@server_name+'],''
		select
	
		case when
			(select count (*) from master.sys.availability_group_listeners) = 1 /* this is an AG group */

		then 
		
		(select cast(dns_name as nvarchar(max))  from master.sys.availability_group_listeners)


		else /* this is not an AG group */
		(select cast(@@SERVERNAME as nvarchar(max)))
		--get_backup.[server_name]
		end
		''))'
		exec sp_executesql @sqlendpoint, @endpointparam, @endpointval = @endpoint     OUTPUT
		end try
					BEGIN CATCH  
					--print @server_name; 
					print 
					'Error:' 
					+ char(10) 
					+ 'Server ' + @@servername
					+ char(10)
					+ 'Error Number ' + cast									(ERROR_NUMBER() as nvarchar) 
					+ char(10)
					+ 'Error Message ' + ERROR_MESSAGE();	
	
					END CATCH;


	end
	else 

	set @endpoint = @server_name

	

--print @endpoint

/* 3. Get all role members for users */
--set @endpoint = 'DEV-ITSQL-01\aptsql'
--set @server_name = 'DEV-ITSQL-01\aptsql'

set @sqlstr3 =  '
insert into [DBA].[dbo].[server_roles_securables_group_users] 
			SELECT *
			FROM OPENQUERY(['+@server_name+'],''
SELECT
        [ServerName] = '''''+@endpoint+''''',
		[UserName] = memberprinc.[name] collate SQL_Latin1_General_CP1_CI_AS,
		[LoginType] = CASE memberprinc.[type]
								WHEN ''''S'''' THEN ''''SQL User''''
								WHEN ''''U'''' THEN ''''Windows User''''
								when ''''G'''' then ''''AD Group''''
							 END, 
        [GroupUserName] = null,
        [Role]             = roleprinc.[name] collate SQL_Latin1_General_CP1_CI_AS,
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


    WHERE
        memberprinc.[type] IN (''''S'''',''''U'''')
        -- No need for these system accounts
        AND memberprinc.[name] NOT IN (''''sys'''', ''''INFORMATION_SCHEMA'''')	

'')'

--print @sqlstr3


											begin try
											exec sp_executesql @sqlstr3 
											end try
											BEGIN CATCH  
												--print @server_name; 
												print 
												'Error:' 
												+ char(10) 
												+ 'Server ' + @@servername
												+ char(10)
												+ 'Error Number ' + cast													(ERROR_NUMBER() as nvarchar) 
												+ char(10)
												+ 'Error Message ' + ERROR_MESSAGE();	
	
											END CATCH;
	

/* 4. List all granted/denied server rights */

set @sqlstr4 = '
insert into [DBA].[dbo].[server_roles_securables_group_users] 
			SELECT *
			FROM OPENQUERY(['+@server_name+'],''
 SELECT
        [ServerName] = '''''+@endpoint+''''',
		[UserName] = princ.[name] collate SQL_Latin1_General_CP1_CI_AS,
		[LoginType] = CASE princ.[type]
								WHEN ''''S'''' THEN ''''SQL User''''
								WHEN ''''U'''' THEN ''''Windows User''''
								when ''''G'''' then ''''AD Group''''
							 END, 
        [GroupUserName] = null,
        [Role]             = null,
        [PermissionType]   = perm.[permission_name] collate SQL_Latin1_General_CP1_CI_AS,
        [PermissionState]  = perm.[state_desc] collate SQL_Latin1_General_CP1_CI_AS,
        [ObjectType] = CASE perm.[class]
                           WHEN 1 THEN obj.[type_desc]        -- Schema-contained objects
                           ELSE perm.[class_desc]              -- Higher-level objects
                       END,
        [Schema] = objschem.[name] collate SQL_Latin1_General_CP1_CI_AS,
        [ObjectName] = CASE perm.[class]
                           WHEN 3 THEN permschem.[name]       -- Schemas
                           WHEN 4 THEN imp.[name]             -- Impersonations
                           ELSE OBJECT_NAME(perm.[major_id])   -- General objects
                       END,
        [ColumnName] = col.[name] collate SQL_Latin1_General_CP1_CI_AS
    FROM
        
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
        princ.[type] IN (''''S'''',''''U'''')
        -- No need for these system accounts
        AND princ.[name] NOT IN (''''sys'''', ''''INFORMATION_SCHEMA'''')			


'')'	

--print @sqlstr4


											begin try
											exec sp_executesql @sqlstr4 
											end try
											BEGIN CATCH  
												--print @server_name; 
												print 
												'Error:' 
												+ char(10) 
												+ 'Server ' + @endpoint
												+ char(10)
												+ 'Error Number ' + cast													(ERROR_NUMBER() as nvarchar) 
												+ char(10)
												+ 'Error Message ' + ERROR_MESSAGE();	
	
											END CATCH;
	

/*5 get individual server rights by active directory group*/
		
			
			


			set @sqlstr5 = '
			insert into [DBA].[dbo].[server_roles_securables_group_users] 
			SELECT *
			FROM OPENQUERY(['+@server_name+'],''
	
			SELECT 
				  
				 [ServerName] = '''''+@endpoint+''''',
				 [UserName] = get_xp_login.[account name] collate SQL_Latin1_General_CP1_CI_AS,
				[LoginType] = CASE princ.[type]
								WHEN ''''S'''' THEN ''''SQL User''''
								WHEN ''''U'''' THEN ''''Windows User''''
								when ''''G'''' then ''''AD Group''''
							 END, 
        [GroupUserName] = get_xp_login.[permission path] collate SQL_Latin1_General_CP1_CI_AS,
        [Role]             = null,
        [PermissionType]   = perm.[permission_name] collate SQL_Latin1_General_CP1_CI_AS,
        [PermissionState]  = perm.[state_desc] collate SQL_Latin1_General_CP1_CI_AS,
        [ObjectType] = CASE perm.[class]
                           WHEN 1 THEN obj.[type_desc]       -- Schema-contained objects
                           ELSE perm.[class_desc]             -- Higher-level objects
                       END,
        [Schema] = objschem.[name] collate SQL_Latin1_General_CP1_CI_AS,
        [ObjectName] = CASE perm.[class]
                           WHEN 3 THEN permschem.[name]        -- Schemas
                           WHEN 4 THEN imp.[name]             -- Impersonations
                           ELSE OBJECT_NAME(perm.[major_id])  -- General objects
                       END,
        [ColumnName] = col.[name] collate SQL_Latin1_General_CP1_CI_AS
		FROM
        
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
		left join 
				[DBA].[dbo].[get_xp_logininfo] get_xp_login
			on princ.name collate SQL_Latin1_General_CP1_CI_AS = get_xp_login.[permission path]
    WHERE
        princ.[type] = ''''G''''
        -- No need for these system accounts
        AND princ.[name] NOT IN (''''sys'''', ''''INFORMATION_SCHEMA'''')		
				

				'')'
--	print @sqlstr5


	
											begin try
											exec sp_executesql @sqlstr5 
											end try
											BEGIN CATCH  
												--print @server_name; 
												print 
												'Error:' 
												+ char(10) 
												+ 'Server ' + @endpoint
												+ char(10)
												+ 'Error Number ' + cast													(ERROR_NUMBER() as nvarchar) 
												+ char(10)
												+ 'Error Message ' + ERROR_MESSAGE();	
	
											END CATCH;
											


/*6 get individual role membership by active directory group*/

set @sqlstr6 =

'			insert into [DBA].[dbo].[server_roles_securables_group_users] 
			SELECT *
			FROM OPENQUERY(['+@server_name+'],''
	
			SELECT 
				  
				 [ServerName] = '''''+@endpoint+''''',
				 [UserName] = get_xp_login.[account name] collate SQL_Latin1_General_CP1_CI_AS,
				[LoginType] = CASE memberprinc.[type]
								WHEN ''''S'''' THEN ''''SQL User''''
								WHEN ''''U'''' THEN ''''Windows User''''
								when ''''G'''' then ''''AD Group''''
							 END, 
         [GroupUserName] = get_xp_login.[permission path] collate SQL_Latin1_General_CP1_CI_AS,
        [Role]             = roleprinc.[name] collate SQL_Latin1_General_CP1_CI_AS,
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
	left join 
				[DBA].[dbo].[get_xp_logininfo] get_xp_login
			on memberprinc.name collate SQL_Latin1_General_CP1_CI_AS = get_xp_login.[permission path]

    WHERE
        memberprinc.[type] = ''''G''''
        -- No need for these system accounts
        AND memberprinc.[name] NOT IN (''''sys'''', ''''INFORMATION_SCHEMA'''')	
				

				'')'

--print @sqlstr6


	
											begin try
											exec sp_executesql @sqlstr6
											end try
											BEGIN CATCH  
												--print @server_name; 
												print 
												'Error:' 
												+ char(10) 
												+ 'Server ' + @endpoint
												+ char(10)
												+ 'Error Number ' + cast													(ERROR_NUMBER() as nvarchar) 
												+ char(10)
												+ 'Error Message ' + ERROR_MESSAGE();	
	
											END CATCH;
											



	fetch servers_cursor into @server_name
	end

	

	close servers_cursor
deallocate servers_cursor



