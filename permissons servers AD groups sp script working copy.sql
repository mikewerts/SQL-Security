/* first, get any AD groups the user is a member of */

--select * from sys.sysdatabases


--select * from master.dbo.syscolumns where name = 'dbid'
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
declare @majorversion int;
declare @endpoint as nvarchar(max) 

/* get the endpoint if it exists or return the server */

set @majorversion = (select cast(SERVERPROPERTY('ProductMajorVersion') as int))
--print @majorversion


if @majorversion > 10
	begin

		if 
		(select count (*) from master.sys.availability_group_listeners) = 1 /* this is an AG group */

		--then 
		--set @endpoint = 
		set @endpoint = (select dns_name from master.sys.availability_group_listeners )
	

	--print @endpoint

		else /* this is not an AG group */
		SELECT @endpoint = @@SERVERNAME
	--get_backup.[server_name]
	end

print @endpoint


set @windows_user = 'MEMIC1\EMJW'

/* Get all the server roles */
--declare @db_name nvarchar(max);
--declare @windows_user nvarchar(max);
--declare @SQL_user nvarchar(max); 
--declare @sqlstr as nvarchar(max); 


/* all server roles table */
If(OBJECT_ID('tempdb..#serverroles') Is Not Null)
Begin
    Drop Table #serverroles

End

create table #serverroles 
(
  
  [DatabaseUserName] nvarchar(max),   
    [login type] nvarchar(max), 
	[Role] nvarchar(max)

)
;

If(OBJECT_ID('tempdb..#group_user_info') Is Not Null)
Begin
    Drop Table #group_user_info

End

create table #group_user_info
(
  [Database User] nvarchar(max),   
    [Windows Group] nvarchar(max), 
	[Role] nvarchar(max)
)

--drop table #serverroles
/* get info from xp_loginfo */
If(OBJECT_ID('tempdb..#xp_logininfo') Is Not Null)
Begin
    Drop Table #xp_logininfo
End


create table #xp_logininfo
(
[account name]	sysname,	--Fully qualified Windows account name.
[type]	char(8),	--Type of Windows account. Valid values are user or group.
[privilege]	char(9),	--Access privilege for SQL Server. Valid values are admin, user, or null.
[mapped login name]	sysname,	--For user accounts that have user privilege, mapped login name shows the mapped login name that SQL Server tries to use when logging in with this account by using the mapped rules with the domain name added before it.
[permission path]	sysname null --Group membership that allowed the account access.
)

If(OBJECT_ID('tempdb..#endpoint') Is Not Null)
Begin
    Drop Table #endpoint
End

create table #endpoint
(
[name] nvarchar(max),
[privilege] nvarchar(max)
)

--select xp.[permission path] from 
--#xp_logininfo xp 
--where  xp.[account name] = 'MEMIC1\mjw'


exec xp_logininfo 'MEMIC1\emjw'

/* 1. insert AD info */

set @sqlstr = 'EXEC xp_logininfo '''+@windows_user+''''

/*
set @sqlstr2 = '
SELECT  

 [DatabaseUserName] = memberprinc.[name] ,   
	[Role] = roleprinc.[name] 

FROM    
    sys.server_role_members members
JOIN
    sys.server_principals roleprinc ON roleprinc.[principal_id] = members.[role_principal_id]
right JOIN
    sys.server_principals memberprinc ON memberprinc.[principal_id] = members.[member_principal_id]
where memberprinc.[name]  = '''+@windows_user+''''
*/
--print @sqlstr

--declare @perm_path nvarchar(max)

insert into #xp_logininfo exec sp_executesql @sqlstr

select * from #xp_logininfo

--insert into #endpoint exec sp_executesql @sqlstr2

/*
EXEC xp_logininfo 'MEMIC1\EMJW'
EXEC xp_logininfo 'MEMIC1\SQL Admins', 'members'
*/


/* 2. map all member groups */

declare get_windows_group_cursor cursor
for 
/*
	select   [DatabaseUserName]
	--,[Role] 
	 from  #serverroles
	where [login type] = 'WINDOWS_GROUP'

	*/

	SELECT  



	[DatabaseUserName] = memberprinc.[name] --,
	--[Role] = roleprinc.[name] 
	--memberprinc.type_desc
	FROM    
    sys.server_role_members members

	JOIN
    sys.server_principals roleprinc ON roleprinc.[principal_id] = members.[role_principal_id]
	right JOIN
    sys.server_principals memberprinc ON memberprinc.[principal_id] = members.[member_principal_id]

	where  memberprinc.type_desc = 'WINDOWS_GROUP'
		
	open get_windows_group_cursor
	
	fetch next from get_windows_group_cursor into @AD_Group

	while @@fetch_status = 0

	begin

	set @sqlstr2 = 'EXEC xp_logininfo '''+@AD_Group+''', ''members'''


	--print @sqlstr

	insert into #xp_logininfo exec sp_executesql @sqlstr2
	

	fetch get_windows_group_cursor into @AD_Group
	end

	close get_windows_group_cursor
deallocate get_windows_group_cursor

/*
select * from #xp_logininfo

select [account name], [permission path] from #xp_logininfo
group by rollup ([account name], [permission path])
*/



/* first insert the users and groups */

--insert into #group_user_info

--select s.DatabaseUserName as 'Database User', null as 'Windows Group', --xp.[account name] as 'Windows Group Member'
--  s.role from #serverroles s
--go

/* 3. Get the users and server privilege derived from xp_logininfo */


set @sqlstr3 =
'


If exists(
select xp.[account name], xp.[privilege] from 
#xp_logininfo xp where xp.[permission path] is NULL and xp.[account name] = '''+@windows_user+''')

Insert into #endpoint

select xp.[account name], xp.[privilege] from 
#xp_logininfo xp where xp.[permission path] is NULL and xp.[account name] = '''+@windows_user+'''

UNION 

select xp.[permission path], xp.[privilege] from 
#xp_logininfo xp 
where xp.[permission path] is NOT NULL and  xp.[account name] = '''+@windows_user+'''

else 

Insert into #endpoint

select '''+@windows_user+''', NULL

UNION 

select xp.[permission path], xp.[privilege] from 
#xp_logininfo xp 
where xp.[permission path] is NOT NULL and  xp.[account name] = '''+@windows_user+''''

--print @sqlstr3

exec sp_executesql @sqlstr3

/*

select xp.[account name], xp.[privilege] from 
#xp_logininfo xp where xp.[permission path] is NULL and xp.[account name] = 'MEMIC1\EMJW'

UNION 

select xp.[permission path], xp.[privilege] from 
#xp_logininfo xp 
where xp.[permission path] is NOT NULL and  xp.[account name] = 'MEMIC1\EMJW'

else 

select 'MEMIC1\ES2S', NULL

UNION 

select xp.[permission path], xp.[privilege] from 
#xp_logininfo xp 
where xp.[permission path] is NOT NULL and  xp.[account name] = 'MEMIC1\EMJW'

*/

select * from #endpoint
--'memic1\EMJW'



/* create the variable for the temp table */
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


	
	
	/* 4: get roles and privileges from all member groups */
	
		declare ad_cursor cursor for
		SELECT name from #endpoint

		open ad_cursor
	
		fetch next from ad_cursor into @ad_name

		while @@fetch_status = 0

		begin
			/* 5 Add the server roles granted for this user */


				set @sqlstr4 = '

				SELECT [ServerName] = '''+@endpoint+''',
				[DatabaseName] = null, 
				[UserName] = '''+@windows_user+''',
				[UserType] = CASE princ.[type]
								WHEN ''S'' THEN ''SQL User''
								WHEN ''U'' THEN ''Windows User''
								when ''G'' then ''AD Group''
							 END,  
				[DatabaseUserName] = princ.[name],       
				[Role] = r.name,      
				[PermissionType] = null,       
				[PermissionState] = null,       
				[ObjectType] = null,--perm.[class_desc],       
				[ObjectName] = null,
				[ColumnName] = null
			FROM
				--Database user
				
				sys.server_role_members rm

				left join

				sys.server_principals r on r.principal_id = rm.role_principal_id and r.type = ''R''

				left join

				sys.server_principals princ on princ.principal_id = rm.member_principal_id
				--sys.server_principals            AS princ
				--JOIN #endpoint e on e.[name] = princ.[name]	
				--Login accounts
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
				princ.[type] in (''S'',''U'',''G'')
				and princ.[name] = ('''+@ad_name+''') 
						'

			print @sqlstr4

			

			begin try
											--print @sqlstr5
											insert into @inserttable exec sp_executesql @sqlstr4 
											end try
											BEGIN CATCH  
												--print @server_name; 
												print 
												'Error:' 
												+ char(10) 
												+ 'Server ' + @endpoint
												+ char(10)
												+ 'Error Number ' + cast(ERROR_NUMBER() as nvarchar) 
												+ char(10)
												+ 'Error Message ' + ERROR_MESSAGE();	
	
											END CATCH; 
		

					/* 6. List all access provisioned directly on the SQL Instance  */

				set @sqlstr5 = '

		
					


				SELECT [ServerName] = '''+@endpoint+''',
				[DatabaseName] = null, 
				[UserName] = '''+@windows_user+''',
				[UserType] = CASE princ.[type]
								WHEN ''S'' THEN ''SQL User''
								WHEN ''U'' THEN ''Windows User''
								when ''G'' then ''AD Group''
							 END,  
				[DatabaseUserName] = princ.[name],       
				[Role] = null,      
				[PermissionType] = perm.[permission_name],       
				[PermissionState] = perm.[state_desc],       
				[ObjectType] = obj.type_desc,--perm.[class_desc],       
				[ObjectName] = OBJECT_NAME(perm.major_id),
				[ColumnName] = col.[name]
			FROM
				--Database user
				sys.server_principals            AS princ

				--Login accounts
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
				princ.[type] in (''S'',''U'',''G'')
				and princ.[name] = ('''+@ad_name+''')


				'
		
				--print @sqlstr5

				
		
											begin try
											--print @sqlstr5
											insert into @inserttable exec sp_executesql @sqlstr5 
											end try
											BEGIN CATCH  
												--print @server_name; 
												print 
												'Error:' 
												+ char(10) 
												+ 'Server ' + @endpoint
												+ char(10)
												+ 'Error Number ' + cast(ERROR_NUMBER() as nvarchar) 
												+ char(10)
												+ 'Error Message ' + ERROR_MESSAGE();	
	
											END CATCH; 



		fetch ad_cursor into @ad_name
		end

		close ad_cursor
		deallocate ad_cursor


	

	--select * from @inserttable






select * from @inserttable


/* get endpoint */






--as [Endpoint],




/*

				SELECT [ServerName] = 'PR-VINYL',
				[DatabaseName] = null, 
				[UserName] = 'MEMIC1\EMJW',
				[UserType] = CASE princ.[type]
								WHEN 'S' THEN 'SQL User'
								WHEN 'U' THEN 'Windows User'
								when 'G' then 'AD Group'
							 END,  
				[DatabaseUserName] = princ.[name],       
				[Role] = e.privilege,      
				[PermissionType] = perm.[permission_name],       
				[PermissionState] = perm.[state_desc],       
				[ObjectType] = obj.type_desc,--perm.[class_desc],       
				[ObjectName] = OBJECT_NAME(perm.major_id),
				[ColumnName] = col.[name]
			FROM
				--Database user
				sys.server_principals            AS princ
				JOIN #endpoint e on e.[name] = princ.[name]	
				--Login accounts
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
				princ.[type] in ('S','U','G')
				and princ.[name] = ('MEMIC1\EMJW') 
				
*/