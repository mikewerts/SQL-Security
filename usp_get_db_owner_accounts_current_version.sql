
CREATE procedure [dbo].[usp_get_db_owner_accounts]
--@sqlrole nvarchar(100)

as

declare @db_name nvarchar(max);
declare @windows_user nvarchar(max);
declare @SQL_user nvarchar(max); 
declare @sqlstr as nvarchar(max); 
declare @sqlrole nvarchar(100)

--declare @sqlusername nvarchar(100)
--set @sqlusername = 
-- 'MEMIC1\Insurity_SQL_Project_Team'

--set @sqlrole = 
-- 'db_owner'

/* create the variable for the temp table */
declare @insertstring as nvarchar(max);
declare @inserttable table
(
			[dbname] nvarchar(500),
			[UserName] nvarchar(500), 
			[UserType] nvarchar(500),
			[Role] nvarchar(500)
  
 
)
	
declare db_cursor cursor
for 
	SELECT name from sys.databases
	where state_desc = 'ONLINE'
	and name NOT IN('master', 'model', 'msdb', 'tempdb')
	open db_cursor
	fetch next from db_cursor into @db_name
		while @@fetch_status = 0

	begin
	/* first, List all access provisioned to a sql user or windows user/group through a database or application role */

	set @sqlstr = '

		
		Use ['+ @db_name +'] 


		
		SELECT '''+ @db_name +''' as ''Database'',
						
			[DatabaseUserName] = memberprinc.[name], 
			[UserType] = CASE memberprinc.[type]
							WHEN ''S'' THEN ''SQL User''
							WHEN ''U'' THEN ''Windows User''
							when ''G'' then ''AD Group''
						 END,   
			[Role] = roleprinc.[name]--,   
			

		FROM    
			sys.database_role_members members
		JOIN
			sys.database_principals roleprinc ON roleprinc.[principal_id] = members.[role_principal_id]
		JOIN
			sys.database_principals memberprinc ON memberprinc.[principal_id] = members.[member_principal_id]
		LEFT JOIN
			sys.login_token ulogin on memberprinc.[sid] = ulogin.[sid]
		
	
	where memberprinc.[name] <> ''dbo'''
	--print @sqlstr
	-- 
	-- where roleprinc.[name] = '''+@sqlrole+'''
	
									begin try
                                    --print @sqlstr
									insert into _db_security_table 
									exec sp_executesql @sqlstr 
									end try
									BEGIN CATCH  
										--print @server_name; 
										print 
										'Error:' 
										+ char(10) 
										+ 'Server ' + @@servername
										+ char(10)
										+ 'Error Number ' + cast(ERROR_NUMBER() as nvarchar) 
										+ char(10)
										+ 'Error Message ' + ERROR_MESSAGE();	
										--+	'ErrorSeverity ' + cast(ERROR_SEVERITY() as nvarchar)    
										--+	'ErrorState ' + cast(ERROR_STATE() as nvarchar)   
 									--	+	'ErrorProcedure ' + cast(ERROR_PROCEDURE() as nvarchar)   
										--+	'ErrorLine ' + cast(ERROR_LINE() as nvarchar)    
																			 

										--SELECT  
										--@server_name,
											--ERROR_NUMBER() AS ErrorNumber  
											--,ERROR_SEVERITY() AS ErrorSeverity  
											--,ERROR_STATE() AS ErrorState  
											--,ERROR_PROCEDURE() AS ErrorProcedure  
											--,ERROR_LINE() AS ErrorLine  
											--,ERROR_MESSAGE() AS ErrorMessage;  
									END CATCH; 

		
	

	--insert into _db_security_table select * from @inserttable 

	fetch db_cursor into @db_name
	end

	close db_cursor
deallocate db_cursor

--	select * from @inserttable

-- get the members from the AD Group

-- EXEC xp_logininfo 'MEMIC1\DLG_InsurityAdmin_RW', 'members'

--exec usp_get_db_owner_accounts --'db_datareader'

--select * from _db_security_table



