/*
USE [DBA]
GO
*/
/****** Object:  StoredProcedure [dbo].[sp_get_db_permissions]    Script Date: 12/22/2021 3:11:42 PM ******/

/*
DROP PROCEDURE IF EXISTS [dbo].[sp_get_db_permissions]
GO



CREATE procedure [dbo].[sp_get_db_permissions]
--@sqlrole nvarchar(100)

as

*/



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
	
drop table #db_nametable
create table  #db_nametable 
(
name nvarchar(500)
)
/* get the linked servers */

--declare @endpoint as nvarchar(max) 



--declare servers_cursor  cursor for
--select srvname from master.dbo.sysservers
--where isremote = 0
--and providername = 'SQLOLEDB'
--order by srvname

--open servers_cursor

--fetch servers_cursor into @server_name
--while @@fetch_status = 0 begin
	
--	/* 1 - get the endpoint if it exists or return the servername */  
	
--	--declare @majorval int

--	set @sqlmajorversion = '
--	select @majorval = (SELECT *
--	FROM OPENQUERY(['+@server_name+'],''
--	select cast(SERVERPROPERTY(''''ProductMajorVersion'''') as int)
--	''))'

--	exec sp_executesql @sqlmajorversion, @majversionparam, @majorval = @majversion     OUTPUT


	--print @sqlmajorversion
	--PRINT @server_name 
	--print @majversion


/* 2. If this is SQL Server 2012 or above, check for availability group listener */
--print @majversion

	/*

	if @majversion > 10
	begin

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

	end
	else 

	set @endpoint = @server_name



	*/

	

--print @sqlendpoint
--print @endpoint

set @server_name = 'ME-SPSQL1'




		/* 3: Get all online databases  */

SELECT @sqlstr3 = 'insert into #db_nametable  
					SELECT name FROM OPENQUERY(['+@server_name+'],''
					SELECT name from master.sys.databases where state_desc = ''''ONLINE'''''')'
			print @sqlstr3


			exec sp_executesql @sqlstr3



			declare db_cursor cursor
			for 
			--select name from @server_name.master.sys.databases 

				
					select name from #db_nametable



				--select @sqlstr3 = '
				--SELECT name FROM OPENQUERY(['+@server_name+'],''
				--SELECT name from master.sys.databases where state_desc = ''''ONLINE'''')'

				--select @db_name = exec sp_execute @sqlstr3

	
				
				/*
				SELECT name FROM OPENQUERY([DEV-ITSQL-01\APTSQL],'SELECT name from master.sys.databases where state_desc = ''ONLINE''')
				*/

				open db_cursor
	
				fetch next from db_cursor into @db_name

				while @@fetch_status = 0

				begin

				--print @db_name

				

/*4: get all the individual security rights */


				--DECLARE @server_db_name nvarchar(max)
				--select @endpoint = 'DEV-ITSQL-01\APTSQL'
				--select @server_name = 'DEV-ITSQL-01\APTSQL'

				--insert into @inserttable
				set @sqlstr4 = '
				insert into [DBA].[dbo].[db_roles_securables_group_users] 
	
				SELECT *
				FROM OPENQUERY(['+@server_name+'],''
	
				SELECT 
				  
				 [ServerName] = '''''+@server_name+''''',
				  [Database Name] = '''''+@db_name+''''',
				[UserName] = princ.[name],
				[UserType] = CASE princ.[type]
								WHEN ''''S'''' THEN ''''SQL User''''
								WHEN ''''U'''' THEN ''''Windows User''''
								when ''''G'''' then ''''AD Group''''
							 END,  
				[DatabaseUserName] = princ.[name],       
				[Role] = null,      
				[PermissionType] = perm.[permission_name],       
				[PermissionState] = perm.[state_desc],       
				[ObjectType] = obj.type_desc,--perm.[class_desc],       
				[ObjectName] = OBJECT_NAME(perm.major_id),
				[ColumnName] = col.[name]
			FROM    
				['+@db_name+'].sys.database_principals princ  
			--JOIN #endpoint e on e.[name] = princ.[name]	
			LEFT JOIN
				['+@db_name+'].sys.login_token ulogin on princ.[sid] = ulogin.[sid]
			LEFT JOIN        
				['+@db_name+'].sys.database_permissions perm ON perm.[grantee_principal_id] = princ.[principal_id]
			LEFT JOIN
				['+@db_name+'].sys.columns col ON col.[object_id] = perm.major_id 
								AND col.[column_id] = perm.[minor_id]
			LEFT JOIN
				['+@db_name+'].sys.objects obj ON perm.[major_id] = obj.[object_id]
			WHERE 
				princ.[type] in (''''S'''',''''U'''')
				

				/* add any principals to further qualify */


			UNION


				SELECT 
			[ServerName] = '''''+@server_name+''''',
				  [Database Name] = '''''+@db_name+''''',
				[UserName] = memberprinc.[name],
				[UserType] = CASE memberprinc.[type]
								WHEN ''''S'''' THEN ''''SQL User''''
								WHEN ''''U'''' THEN ''''Windows User''''
								when ''''G'''' then ''''AD Group''''
								END, 
				[DatabaseUserName] = memberprinc.[name],   
				[Role] = roleprinc.[name],   
				[PermissionType] = perm.[permission_name],       
				[PermissionState] = perm.[state_desc],       
				[ObjectType] = obj.type_desc,--perm.[class_desc],   
				[ObjectName] = OBJECT_NAME(perm.major_id),
				[ColumnName] = col.[name]  

					FROM    
						['+@db_name+'].sys.database_role_members members
					JOIN
						['+@db_name+'].sys.database_principals roleprinc ON roleprinc.[principal_id] = members.[role_principal_id]
					JOIN
						['+@db_name+'].sys.database_principals memberprinc ON memberprinc.[principal_id] = members.[member_principal_id]
					--JOIN #endpoint e on e.[name] = memberprinc.[name]
					LEFT JOIN
						['+@db_name+'].sys.login_token ulogin on memberprinc.[sid] = ulogin.[sid]
					LEFT JOIN        
						['+@db_name+'].sys.database_permissions perm ON perm.[grantee_principal_id] = roleprinc.[principal_id]
					LEFT JOIN
						['+@db_name+'].sys.columns col on col.[object_id] = perm.major_id 
								AND col.[column_id] = perm.[minor_id]
					LEFT JOIN
						['+@db_name+'].sys.objects obj ON perm.[major_id] = obj.[object_id]

					where memberprinc.[type] in (''''S'''',''''U'''') 
	'')'

	print @sqlstr4
	

	/*
	
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
												+ 'Error Number ' + cast									(ERROR_NUMBER() as nvarchar) 
												+ char(10)
												+ 'Error Message ' + ERROR_MESSAGE();	
	
											END CATCH;
*/

			
/* 5: get all the group security rights and join them on each individual in that group */


			set @sqlstr5 = '
			insert into [DBA].[dbo].[db_roles_securables_group_users] 
			SELECT *
			FROM OPENQUERY(['+@server_name+'],''
	
			SELECT 
				  
				 [ServerName] = '''''+@server_name+''''',
				  [Database Name] = '''''+@db_name+''''',
				[UserName] = get_xp_login.[account name],
				[UserType] = CASE princ.[type]
								WHEN ''''S'''' THEN ''''SQL User''''
								WHEN ''''U'''' THEN ''''Windows User''''
								when ''''G'''' then ''''AD Group''''
							 END,  
				[DatabaseUserName] = princ.[name],       
				[Role] = null,      
				[PermissionType] = perm.[permission_name],       
				[PermissionState] = perm.[state_desc],       
				[ObjectType] = obj.type_desc,--perm.[class_desc],       
				[ObjectName] = OBJECT_NAME(perm.major_id),
				[ColumnName] = col.[name]
			FROM    
				['+@db_name+'].sys.database_principals princ  
			--JOIN #endpoint e on e.[name] = princ.[name]	
			LEFT JOIN
				['+@db_name+'].sys.login_token ulogin on princ.[sid] = ulogin.[sid]
			LEFT JOIN        
				['+@db_name+'].sys.database_permissions perm ON perm.[grantee_principal_id] = princ.[principal_id]
			LEFT JOIN
				['+@db_name+'].sys.columns col ON col.[object_id] = perm.major_id 
								AND col.[column_id] = perm.[minor_id]
			LEFT JOIN
				['+@db_name+'].sys.objects obj ON perm.[major_id] = obj.[object_id]
			left join 
				[master].[dbo].[get_xp_logininfo] get_xp_login
			on princ.name = get_xp_login.[permission path]

			WHERE 
				princ.[type] = (''''G'''')
				

				/* add any principals to further qualify */


			UNION


				SELECT 
			[ServerName] = '''''+@server_name+''''',
				  [Database Name] = '''''+@db_name+''''',
				[UserName] = get_xp_login.[account name],
				[UserType] = CASE memberprinc.[type]
								WHEN ''''S'''' THEN ''''SQL User''''
								WHEN ''''U'''' THEN ''''Windows User''''
								when ''''G'''' then ''''AD Group''''
								END, 
				[DatabaseUserName] = memberprinc.[name],   
				[Role] = roleprinc.[name],   
				[PermissionType] = perm.[permission_name],       
				[PermissionState] = perm.[state_desc],       
				[ObjectType] = obj.type_desc,--perm.[class_desc],   
				[ObjectName] = OBJECT_NAME(perm.major_id),
				[ColumnName] = col.[name]  

					FROM    
						['+@db_name+'].sys.database_role_members members
					JOIN
						['+@db_name+'].sys.database_principals roleprinc ON roleprinc.[principal_id] = members.[role_principal_id]
					JOIN
						['+@db_name+'].sys.database_principals memberprinc ON memberprinc.[principal_id] = members.[member_principal_id]
					--JOIN #endpoint e on e.[name] = memberprinc.[name]
					LEFT JOIN
						['+@db_name+'].sys.login_token ulogin on memberprinc.[sid] = ulogin.[sid]
					LEFT JOIN        
						['+@db_name+'].sys.database_permissions perm ON perm.[grantee_principal_id] = roleprinc.[principal_id]
					LEFT JOIN
						['+@db_name+'].sys.columns col on col.[object_id] = perm.major_id 
								AND col.[column_id] = perm.[minor_id]
					LEFT JOIN
						['+@db_name+'].sys.objects obj ON perm.[major_id] = obj.[object_id]
							left join 
				[master].[dbo].[get_xp_logininfo] get_xp_login
			on memberprinc.name = get_xp_login.[permission path]

					where memberprinc.[type]  = (''''G'''')
	'')'
	print @sqlstr5
	/*
	
	
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
											
	
			*/	
				

				fetch db_cursor into @db_name
				end


				close db_cursor
				deallocate db_cursor

				/* truncate the temp table for the next server */

				truncate table #db_nametable


		



	--fetch servers_cursor into @server_name
	--end

	

--	close servers_cursor
--deallocate servers_cursor





