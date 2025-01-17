EXEC tSQLt.NewTestClass 'InfoTests';
GO
CREATE PROCEDURE InfoTests.[test tSQLt.Info() returns a row with a Version column containing latest build number]
AS
BEGIN
  DECLARE @Version NVARCHAR(MAX);
  DECLARE @ClrInfo NVARCHAR(MAX);
  
  SELECT @Version = Version
    FROM tSQLt.Info();
  
  SELECT @ClrInfo=clr_name FROM sys.assemblies WHERE name='tSQLtCLR'  
  
  IF(@ClrInfo NOT LIKE '%version='+@Version+'%')
  BEGIN
    EXEC tSQLt.Fail 'Expected ''version=',@Version,''' to be part of ''',@ClrInfo,'''.'
  END
END;
GO
CREATE PROCEDURE InfoTests.[test tSQLt.Info() returns a row with a ClrSigningKey column containing the binary thumbprint of the signing key]
AS
BEGIN
  DECLARE @SigningKeyPattern NVARCHAR(MAX);
  DECLARE @ClrInfo NVARCHAR(MAX);
  
  SELECT @SigningKeyPattern = '%publickeytoken='+LOWER(CONVERT(NVARCHAR(MAX),I.ClrSigningKey,2))+',%'
    FROM tSQLt.Info() I;
  
  SELECT @ClrInfo=clr_name FROM sys.assemblies WHERE name='tSQLtCLR'  

  EXEC tSQLt.AssertLike @ExpectedPattern = @SigningKeyPattern, @Actual = @ClrInfo, @Message = 'The value returned by tSQLt.Info().ClrSigningKey was not part of the clr_name of the assembly' ;  
END;
GO
CREATE FUNCTION InfoTests.[42.17.1986.57]()
RETURNS TABLE
AS
RETURN SELECT CAST(N'42.17.1986.57' AS NVARCHAR(128)) AS ProductVersion, 'My Edition' AS Edition, NULL HostPlatform;
GO
CREATE FUNCTION InfoTests.[SomePlatform]()
RETURNS TABLE
AS
RETURN SELECT NULL AS ProductVersion, NULL AS Edition, 'SomePlatform' HostPlatform;
GO
CREATE PROCEDURE InfoTests.[test returns HostPlatform]
AS
BEGIN

  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'InfoTests.[SomePlatform]';

  SELECT I.HostPlatform
    INTO #Actual
    FROM tSQLt.Info() AS I;
  
  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES('SomePlatform');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE InfoTests.[test returns SqlVersion and SqlBuild]
AS
BEGIN

  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'InfoTests.[42.17.1986.57]';

  SELECT I.SqlVersion, I.SqlBuild
    INTO #Actual
    FROM tSQLt.Info() AS I;
  
  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES(42.17, 1986.57);

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE InfoTests.[test returns SqlEdition]
AS
BEGIN
  EXEC tSQLt.FakeFunction @FunctionName = 'tSQLt.Private_SqlVersion', @FakeFunctionName = 'InfoTests.[42.17.1986.57]';

  SELECT I.SqlEdition
    INTO #Actual
    FROM tSQLt.Info() AS I;
  
  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  VALUES('My Edition');

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;
GO
CREATE PROCEDURE InfoTests.[test double ledger for tSQLt.Private_SqlVersion]
AS
BEGIN

  SELECT *
    INTO #Actual
    FROM tSQLt.Private_SqlVersion() AS PSV;
  
  SELECT TOP(0) *
  INTO #Expected
  FROM #Actual;
  
  INSERT INTO #Expected
  SELECT 
      CAST(SERVERPROPERTY('ProductVersion')AS NVARCHAR(128)) ProductVersion,
      CAST(SERVERPROPERTY('Edition')AS NVARCHAR(128)) Edition, 
		    host_platform HostPlatform 
    FROM sys.dm_os_host_info;

  EXEC tSQLt.AssertEqualsTable '#Expected','#Actual';
END;

--TODO:
-- include minimum supported version, like column with the lowest number that we run CI tests on (hardcoded)