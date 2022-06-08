use [DBA]
go

--DECLARE @DomainFQDN VARCHAR(50) = '<your.domain.FQDN>';

IF OBJECT_ID('DBA..ADData') IS NOT NULL
begin
  Truncate TABLE ADData

end

-- Query AD for all known user accounts
else 

--drop table ADData

CREATE TABLE ADData(
    LoginName               NVARCHAR(256),
    firstName           NVARCHAR(256),
    lastName            NVARCHAR(256),
    email               NVARCHAR(256),
    costcenter          NVARCHAR(256),  --Our AD implementation uses the optional extensionAttributes, defining 1 as cost center
    mobile              NVARCHAR(256),  --In @Query below, the name of this column is the same as the LDAP returned parameter, so no equate is applied in the query
    country             NVARCHAR(256),
    usnCreated          BIGINT,
	userAccountControl  int,--uSNCreated is an INT64 object type
	department			 NVARCHAR(256),
	title		 NVARCHAR(256),
	account_disabled nvarchar(2)
);




--Define the AD LDAP connection
--IF NOT EXISTS(SELECT 1 FROM sys.servers WHERE name = 'ADSI') 
-- EXEC master.dbo.sp_addlinkedserver
--    @server = N'ADSI', 
--    @srvproduct = N'Active Directory Services',
--    @provider = N'ADsDSOObject', 
--    @datasrc = @DomainFQDN;

DECLARE @Rowcount int;
DECLARE @LastCreatedFilter VARCHAR(200) = '';
DECLARE @ADrecordsToReturn smallint = 901;  --AD will not return more than 901 records per query (changed from 1000 at some point). You can set it to any value smaller to control the 'pagesize' of returned results

--Loop mechanics:
-- - 1st loop: @Rowcount will be NULL but we need to looping to commence, thus ISNULL function
-- - Intermediate loops: Rowcount will equal the max number of requested records, indicating there may be more to query from AD
--SELECT @LastCreatedFilter = 'AND usnCreated = ''''<yourvalue>'''''; --Used during debugging to iniate the loop at a certain value
--DECLARE @TestStop int = 1;  -- @TestStop is a debug option to halt processing. It needs to be commented in or out at 3 places
WHILE ISNULL(@Rowcount,@ADrecordsToReturn) = @ADrecordsToReturn --AND @TestStop < 4  --Un-comment the three @TestStop lines to run a reduced sample query of AD, dictated by the value provided on this line (# of loops to process before stopping)
 BEGIN

    DECLARE @Query VARCHAR (2000) = 
     '
        SELECT TOP ' + CONVERT(varchar(10),@ADrecordsToReturn) + '
            LoginName               = ''MEMIC1\''+SamAccountName,
            firstName           = GivenName,
            lastName            = sn,
            email               = mail,
            costcenter               = extensionAttribute1,
            mobile,
            country             = c,
            usnCreated,
			userAccountControl,
			department,
			title,
			case when userAccountControl & 2 = 0 then ''N'' else ''Y'' end AS account_disabled
			
         FROM OpenQuery
          (
            ADSI,
            ''
                SELECT SamAccountName, GivenName, sn, mail, extensionAttribute1, mobile, c, usnCreated, userAccountControl, department,
			title 
                 FROM ''''LDAP://corp.memic.com/DC=corp,DC=memic,DC=com''''
                 WHERE objectCategory = ''''Person''''
                 AND objectClass = ''''user''''
                 ' + @LastCreatedFilter + '

                 ORDER BY usnCreated
            ''
          )
     ';  

--print @Query;
-- 				 AND ''''userAccountControl:1.2.840.113556.1.4.803:''''=2

    INSERT INTO ADData EXEC (@Query);
    SELECT @Rowcount = @@ROWCOUNT;
    SELECT @LastCreatedFilter = 'AND usnCreated > ' + LTRIM(STR((SELECT MAX(usnCreated) FROM ADData)));

--PRINT @LastCreatedFilter;  --While debugging, used to determine progress
--SET @TestStop = @TestStop + 1;  -- @TestStop is a debug option to halt processing. It needs to be commented in or out at 3 places
 END;

 --select * from ADData

--EXEC master.dbo.sp_dropserver 'ADSI';