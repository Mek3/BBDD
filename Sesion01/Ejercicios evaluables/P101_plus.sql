﻿USE master
GO

set nocount on
go

IF DB_ID (N'P101') IS NOT NULL
BEGIN
	ALTER DATABASE P101 SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
	DROP DATABASE P101;
END
GO
CREATE DATABASE P101
GO
USE P101
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- The below scipt enables the use of In-Memory OLTP in the current database, 
--   provided it is supported in the edition / pricing tier of the database.
-- It does the following:
-- 1. Validate that In-Memory OLTP is supported. 
-- 2. In SQL Server, it will add a MEMORY_OPTIMIZED_DATA filegroup to the database
--    and create a container within the filegroup in the default data folder.
-- 3. Change the database compatibility level to 130 (needed for parallel queries
--    and auto-update of statistics).
-- 4. Enables the database option MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT to avoid the 
--    need to use the WITH (SNAPSHOT) hint for ad hoc queries accessing memory-optimized
--    tables.
--
-- Applies To: SQL Server 2016 (or higher); Azure SQL Database
-- Author: Jos de Bruijn (Microsoft)
-- Last Updated: 2016-05-02

SET NOCOUNT ON;
SET XACT_ABORT ON;

-- 1. validate that In-Memory OLTP is supported
IF SERVERPROPERTY(N'IsXTPSupported') = 0 
BEGIN                                    
    PRINT N'Error: In-Memory OLTP is not supported for this server edition or database pricing tier.';
END 
IF DB_ID() < 5
BEGIN                                    
    PRINT N'Error: In-Memory OLTP is not supported in system databases. Connect to a user database.';
END 
ELSE 
BEGIN 
	BEGIN TRY;
-- 2. add MEMORY_OPTIMIZED_DATA filegroup when not using Azure SQL DB
	IF SERVERPROPERTY('EngineEdition') != 5 
	BEGIN
		DECLARE @SQLDataFolder varchar(max) = cast(SERVERPROPERTY('InstanceDefaultDataPath') as varchar(max))
		DECLARE @MODName varchar(max) = DB_NAME() + N'_mod';
		DECLARE @MemoryOptimizedFilegroupFolder varchar(max) = @SQLDataFolder + @MODName;

		DECLARE @SQL varchar(max) = N'';

		-- add filegroup
		IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE type = N'FX')
		BEGIN
		ALTER DATABASE CURRENT  SET AUTO_CLOSE OFF
			SET @SQL = N'
ALTER DATABASE CURRENT 
ADD FILEGROUP ' + QUOTENAME(@MODName) + N' CONTAINS MEMORY_OPTIMIZED_DATA;';
			EXECUTE (@SQL);

		END;

		-- add container in the filegroup
		IF NOT EXISTS (SELECT * FROM sys.database_files WHERE data_space_id IN (SELECT data_space_id FROM sys.filegroups WHERE type = N'FX'))
		BEGIN
			SET @SQL = N'
ALTER DATABASE CURRENT
ADD FILE (name = N''' + @MODName + ''', filename = '''
						+ @MemoryOptimizedFilegroupFolder + N''') 
TO FILEGROUP ' + QUOTENAME(@MODName);
			EXECUTE (@SQL);
		END
	END

	-- 3. set compat level to 130 if it is lower
	IF (SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID()) < 130
		ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 130 

	-- 4. enable MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT for the database
	ALTER DATABASE CURRENT SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON;


    END TRY
    BEGIN CATCH
        PRINT N'Error enabling In-Memory OLTP';
		IF XACT_STATE() != 0
			ROLLBACK;
        THROW;
    END CATCH;
END;
go
--Creaciףn de tablas

create table perfil (
	perfil char(3) primary key,
	descripcion varchar(20)
);

create table usuario (
    usuId int IDENTITY(1,1) constraint PK_usuario primary key,
	password varbinary(64),
    apodo varchar(15),
	email varchar(254) not null,
	nombre varchar(50) not null,
	apellidos varchar(75) not null,
	nacido date not null,
	perfil char(3) default '0',
	constraint FK_usuario_perfil foreign key (perfil) references perfil(perfil)
);

create table conexion (
	numconex int IDENTITY(1,1) constraint PK_conexion primary key,
	usuId int,
	entra datetime,
	constraint FK_conexion_usuario foreign key (usuId) references usuario(usuId)
);

create table sigue (
	usuId int,
	siguea int,
	constraint PK_sigue primary key (usuId,siguea),
	foreign key (usuId) references usuario(usuId),
	foreign key (siguea) references usuario(usuId)
);

create table comentario (
	usuId int,
	numcom smallint,
	comenta varchar(1000) not null,
	respondea int,
	respondeanum smallint,
	cuando datetime2,
	constraint PK_comentario primary key (usuId,numcom),
	constraint FK_comentario_usuario foreign key (usuId) references usuario(usuId),
	constraint FK_comentario_comentario foreign key (respondea,respondeanum) references comentario(usuId,numcom)
);

create table palabrasclave (
	keyw varchar(25) constraint PK_palabrasclave primary key
); 

create table comkeyw (
	keyw varchar(25),
	usuId int,
	numcom smallint,
	constraint PK_comkeyw primary key (keyw,usuId,numcom),
	constraint FK_comkeyw_palabrasclave foreign key (keyw) references palabrasclave(keyw),
	constraint FK_comkeyw_comentario foreign key (usuId,numcom) references comentario(usuId,numcom)
);

create table valora (
	numVal bigint IDENTITY(1,1) constraint PK_valora primary key,
	usuId int,
	valorado int,
	numcom smallint,
	estrellas tinyint constraint CHK_estrellas_valor check (estrellas >0 and estrellas <6),
	constraint FK_valora_usuario foreign key (usuId) references usuario(usuId),
	constraint FK_valora_comentario foreign key (valorado,numcom) references comentario(usuId,numcom)
);

GO

-- insertando datos estבticos
insert into perfil values ('0','Bבsico'),('1','Estבndar'),('2','Premium');

GO

--select * from perfil;

-- datos temporales para generaciףn aleatoria
DROP TABLE IF EXISTS #apellido;
DROP TABLE IF EXISTS #nombre;
DROP TABLE IF EXISTS #correo;
create table #apellido (apellido varchar(75));
create table #nombre (nombre varchar(50));
create table #correo (correo varchar(254));
go

insert into #apellido values ('Andreo'),('Adבnez'),('Alejבndrez'),('�lvarez'),('Alves'),('Ansתrez'),('Antolםnez'),('Antתnez'),('Arranz'),('Aznבrez'),('Bבez'),('Baz'),('Benיitez'),('Benםtez'),('Bermתdez'),('Bernבrdez'),('Blבnquez'),('Blבzquez'),('Briz'),('Chaves'),('Chבvez'),('Dםaz'),('Diיguez'),('Dםez'),('Dםez'),('Diz'),('Domםnguez'),('Enrםquez'),('Escבmez'),('Estיbanez'),('Estיvez'),('Fיlez'),('Fernandes'),('Fernבndez'),('Ferrandis'),('Ferrבndiz'),('Ferris'),('Fיrriz'),('Fortתnez'),('Froilaz'),('Galםndez'),('Gבlvez'),('Gבmez'),('Gבmiz'),('Garcיs'),('Garcםa'),('Gבsquez'),('Gelmםrez'),('Gimיnez'),('Girבldez'),('Gomבriz'),('Gomes'),('Gףmez'),('Gomis'),('Gonzales'),('Gonzבlez'),('Gonzבlvez'),('Gutiיrrez'),('Henrםquez'),('Hernבez'),('Hernבiz'),('Hernבndez'),('Hernanz'),('Herrבez'),('Herraiz'),('Herranz'),('Ibבסez'),('�סiguez'),('Jבסez'),('Jimיnez'),('Juבrez'),('Jתlvez'),('Laםnez'),('Lendםnez'),('Lopes'),('Lףpez'),('Lupiaסez'),('Mבrques'),('Mבrquez'),('Martםnez'),('Matesanz'),('Melיndez'),('Mendes'),('Mיndez'),('Menיndez'),('Miguelבסez'),('Miguיlez'),('Mםguez'),('Mםnguez'),('Muסiz'),('Muסoz'),('Narvבez'),('Nunes'),('Nתסez'),('Ordףסez'),('Ortiz'),('Pבez'),('Pelבez'),('Pיrez'),('Periבסez'),('Peribבסez'),('Peris'),('Piris'),('Piriz'),('Pףbez'),('Quiles'),('Quםlez'),('Raimתndez'),('Ramםrez'),('Rםsquez'),('Rodrigues'),('Rodrםguez'),('Ruipיrez'),('Ruiz'),('Rupיrez'),('Rus'),('Ruz'),('Sבenz'),('Sבez'),('Sבinz'),('Sבiz'),('Salvadףrez'),('Sבnchez'),('Sanchםs'),('Sבnchiz'),('Sanz'),('Saz'),('Segתndez'),('Suבrez'),('Tיllez'),('Valdיs'),('Valdez'),('Vבsquez'),('Vaz'),('Vבzquez'),('Velבsquez'),('Velבzquez'),('Vיlez'),('Vיliz'),('Viיitez'),('Viתdez'),('Ximיnez'),('Suבrez'),('Yבg�e'),('Yבg�ez'),('Yanes'),('Yבnez'),('Yבסez');
insert into #nombre values ('Antonio'),('Jose'),('Manuel'),('Francisco'),('Juan'),('David'),('Jose Antonio'),('Jose Luis'),('Javier'),('Francisco Javier'),('Jesus'),('Daniel'),('Carlos'),('Miguel'),('Alejandro'),('Jose Manuel'),('Rafael'),('Pedro'),('Angel'),('Miguel Angel'),('Jose Maria'),('Fernando'),('Pablo'),('Luis'),('Sergio'),('Jorge'),('Alberto'),('Juan Carlos'),('Juan Jose'),('Alvaro'),('Diego'),('Adrian'),('Juan Antonio'),('Raul'),('Enrique'),('Ramon'),('Vicente'),('Ivan'),('Ruben'),('Oscar'),('Andres'),('Joaquin'),('Juan Manuel'),('Santiago'),('Eduardo'),('Victor'),('Roberto'),('Jaime'),('Francisco Jose'),('Mario'),('Ignacio'),('Alfonso'),('Salvador'),('Ricardo'),('Marcos'),('Jordi'),('Emilio'),('Julian'),('Julio'),('Guillermo'),('Gabriel'),('Tomas'),('Agustin'),('Jose Miguel'),('Marc'),('Gonzalo'),('Felix'),('Jose Ramon'),('Mohamed'),('Hugo'),('Joan'),('Ismael'),('Nicolas'),('Cristian'),('Samuel'),('Mariano'),('Josep'),('Domingo'),('Juan Francisco'),('Aitor'),('Martin'),('Alfredo'),('Sebastian'),('Jose Carlos'),('Felipe'),('Hector'),('Cesar'),('Jose Angel'),('Jose Ignacio'),('Victor Manuel'),('Iker'),('Gregorio'),('Luis Miguel'),('Alex'),('Jose Francisco'),('Juan Luis'),('Rodrigo'),('Albert'),('Xavier'),('Lorenzo ');
insert into #correo values ('gmail.com'),('hotmail.com'),('outlook.com'),('alu.ua.es'),('ua.es'),('gcloud.ua.es'),('mscloud.ua.es');
go

-- palabras clave
insert into palabrasclave values ('albacete'),('gratis'),('barato'),('empleo'),('.doc'),('alicante'),('gratuito'),('barata'),('empleos'),('.docx'),('almeria'),('gratuita'),('economico'),('trabajo'),('.docm'),('alava'),('gratuitamente'),('economica'),('trabajos'),('.pages'),('asturias'),('RRSS'),('promocion'),('trabajar'),('.pdf'),('avila'),('facebook'),('oferta'),('practica'),('.pub'),('badajoz'),('fb'),('low'),('cost'),('practicas'),('.txt'),('baleares'),('instagram'),('asequible'),('rrhh'),('.xml'),('barcelona'),('insta'),('rebaja'),('recursos'),('humanos'),('.xps'),('bizkaia'),('twitter'),('rebajas'),('cv'),('doc'),('burgos'),('rebajado'),('vitae'),('docx'),('caceres'),('snapchat'),('rebajada'),('infojobs'),('docm'),('cadiz'),('youtube'),('ganga'),('trabajando'),('pages'),('cantabria'),('pinterest'),('ocasiףn'),('linkedin'),('pdf'),('castellon'),('slideshare'),('descuento'),('job'),('pub'),('ciudad'),('real'),('OTROS'),('descuentos'),('jobs'),('txt'),('cardoba'),('video'),('CONSULTAS'),('beca'),('xml'),('coruסa'),('videos'),('que es'),('becario'),('xps'),('cuenca'),('foto'),('como'),('becas'),('.csv'),('gipuzkoa'),('fotografia'),('quien'),('master'),('.xls'),('girona'),('fotografias'),('traduccion'),('masters'),('csv'),('granada'),('imagen'),('traductor'),('universidad'),('xls'),('guadalajara'),('imבgenes'),('ingles'),('universitario'),('.ai'),('huelva'),('fotolia'),('english'),('universitaria'),('ai'),('huesca'),('groupon'),('frances'),('universitarios'),('.azw'),('jaen'),('blog'),('french'),('universitarias'),('.azw3'),('leon'),('blogs'),('aleman'),('curso'),('.epub'),('lleida'),('foro'),('german'),('cursos'),('.lit'),('lugo'),('foros'),('opinion'),('tutorial'),('.mobi'),('madrid'),('portal'),('opiniones'),('libro'),('azw'),('malaga'),('portales'),('definicion'),('libros'),('azw3'),('murcia'),('sexo'),('tutoriales'),('epub'),('navarra'),('sexual'),('significado'),('clase'),('lit'),('ourense'),('sexuales'),('sinonimo'),('clases'),('mobi'),('palencia'),('porno'),('sinonimos'),('estudio'),('.gif'),('palmas'),('pornografia'),('antonimo'),('estudios'),('.ico'),('pontevedra'),('xxx'),('antonimos'),('asignatura'),('.jpeg'),('rioja'),('podcast'),('wikipedia'),('asignaturas'),('.jpg'),('salamanca'),('ebook'),('wiki'),('proyecto'),('.png'),('juancarballo.com'),('tenerife'),('contacto'),('traducir'),('proyectos'),('.psd'),('segovia'),('contactar'),('concepto'),('.tif'),('sevilla'),('email'),('conceptos'),('gif'),('soria'),('mail'),('ico'),('tarragona'),('telefono'),('inventor'),('jpeg'),('teruel'),('telefonos'),('invento'),('jpg'),('toledo'),('segunda mano'),('manual'),('png'),('valencia'),('ebay'),('manuales'),('psd'),('valladolid'),('amazon'),('instruccion'),('tif'),('zamora'),('shopping'),('instrucciones'),('.key'),('zaragoza'),('milanuncios'),('saber'),('.pps'),('ceuta'),('segundamano'),('dossier'),('.ppsx'),('melilla'),('descargar'),('dosier'),('.ppt'),('descargas'),('dossieres'),('.pptm'),('dosieres'),('.pptx'),('portfolio'),('key'),('portfolios'),('pps'),('presentacion'),('ppsx'),('presentaciones'),('ppt'),('comparar'),('pptm'),('comparador'),('pptx'),('guia'),('.avi'),('guias'),('.divx'),('ejemplo'),('.mov'),('ejemplos'),('.mp4'),('herramienta'),('.mpeg'),('herramientas'),('.mpg'),('casero'),('.wmv'),('caseros'),('avi'),('remedios'),('divx'),('remedio'),('mov'),('a mano'),('mp4'),('en casa'),('mpeg'),('lista'),('mpg'),('listado'),('wmv');
go

--select * from #apellido;
--select * from #nombre;
--select * from #correo;


-- Para generar fechas aleatorias------------------------------------------------------------
-- Visto en https://misalgoritmosnet.wordpress.com/2013/07/24/fecha-aleatoria-sql-server/
drop view  if exists seeder
go
CREATE VIEW seeder
AS
    SELECT RAND(CONVERT(VARBINARY, NEWID())) seed
GO


drop fUNCTION if exists getRandomDate
go
CREATE FUNCTION getRandomDate(@lower DATE,@upper DATE)
RETURNS DATE
AS
	BEGIN
		DECLARE @random DATE
		SELECT @random = DATEADD(day, DATEDIFF(DAY, @lower, @upper) * seed, @lower) from seeder
		RETURN @random
	END
go
---------------------------------------------------------------------------------------------------

/*************************************************************************************************************/
/*************************************     P101  ************************************************************
*************************************************************************************************************/

drop procedure if exists generar_usuarios;
go

create procedure generar_usuarios @cantusu int 
as 
declare @contador int, @cantnum int , @numalea int,
		@nom varchar(25), @apes varchar(75), 
		@serv varchar(50), @email varchar(254),
		@usuario varchar (75), @nomuser varchar (75),
		@pos int;

IF OBJECT_ID('#natemporal') IS NOT NULL
	DROP TABLE #natemporal;

drop table if EXISTS #natemporal;

select row_number() over (order by nombre)
		orden, nombre, a1.apellido + ' ' + a2.apellido apellidos 
		into #natemporal
		from #nombre, #apellido a1, #apellido a2;

set @cantnum =  (select count(*) from #natemporal);
set @contador = 1
set @pos = 0;

while(@contador <= @cantusu)
	begin
		set @numalea = (SELECT FLOOR(RAND()*(@cantnum-1)+1));
		set @nom = (select nombre from #natemporal where orden=@numalea);
		set @numalea = (SELECT FLOOR(RAND()*(@cantnum-1)+1));
		set @apes = (select apellidos from #natemporal where orden=@numalea);
		
		select top 1 @serv='@'+correo from #correo order by newid();
		
		set @pos  = (select charindex(' ', @nom));
		if(@pos>0)
			set @nomuser =  SUBSTRING(@nom, 1,CHARINDEX(' ', @nom) - 1) +
							SUBSTRING(@nom, CHARINDEX(' ', @nom) + 1, len(@nom)-1);
		else 
		 set @nomuser = @nom;
		
		set @email = @nomuser + '.' + SUBSTRING(@apes, 1,CHARINDEX(' ', @apes) - 1)
					 + cast(floor(rand()*999) as varchar(3)) + @serv;
		
		set @contador = @contador + 1;
		set @pos = 0;
		
		insert into usuario(email,nombre,apellidos,nacido) 
			values (@email, @nom, @apes,
					dbo.getRandomDate('1960-01-01', '2019-10-11'))
	end	

GO

-- exec generar_usuarios 5;
-- select * from usuario;

/*************************************************************************************************************/
/*************************************     P101 plus  ********************************************************
*************************************************************************************************************/

-----------------------------------------------------------------
----------------------- Modificar perfil ------------------------
-----------------------------------------------------------------

drop procedure if exists  modificarPerfiles;
go 

create procedure modificarPerfiles
as
declare @cantus int;
IF OBJECT_ID('#temporalperfil') IS NOT NULL
	DROP TABLE #temporalperfil;

drop table if EXISTS #temporalperfil;

select top(cast((select count(*) from usuario)*.20 as int))
		usuid, perfil into #temporalperfil from usuario order by newid()

set @cantus = (select count(*) from usuario);

with cons_temp(usuid,perfil) 
as
(select u.usuid, u.perfil from usuario u, #temporalperfil tp where u.usuId = tp.usuId) 
update cons_temp set perfil=1;

with cons_temp_res(usuid,perfil) 
as
(select top(cast((select count(*) from usuario)*.05 as int))
		u.usuid, u.perfil from usuario u, #temporalperfil tp  where u.usuId != tp.usuId order by newid()) 
update cons_temp_res set perfil=2;

go

-----------------------------------------------------------------
----------------------- Generar seguidores ----------------------
-----------------------------------------------------------------

drop procedure if exists gen_sigue;
go 

create procedure gen_sigue
as
declare @cuantos int, @usu1 int, @usu2 int, @cont int, @cantidad int;

select @cuantos = count(*) from usuario;
set @cantidad = @cuantos;
set @cont = 0;

while (@cont < @cantidad)
	begin
	set @usu1=1;
	set @usu2=1;
	while (@usu1 = @usu2)
		begin
			select @usu1=floor(rand()*@cuantos)+1;
			select @usu2=floor(rand()*@cuantos)+1;
		end

	if((select count(*) from sigue where usuId = @usu1 and siguea = @usu2) = 0)
	insert into sigue (usuId,siguea) values(@usu1,@usu2);
		
	set @cont = @cont+1;
	end
go

-----------------------------------------------------------------
----------------------- Generar comentarios ---------------------
-----------------------------------------------------------------

drop procedure if exists gen_comenta;
go 

create procedure gen_comenta @cantusu int, @maxPorUso int
as
declare @i int, @usuar int, @cuantos int, @cont int;
declare cursor_usuId cursor for select top(@cantusu) usuId from usuario order by newid();
open cursor_usuId 

fetch next from cursor_usuId into @usuar;
while @@FETCH_STATUS = 0
	begin 
		set @cuantos = floor(rand()*@maxPorUso)+1
		set @cont = 1;
		while @cuantos >= @cont
		begin
			if((select count(*) from comentario where usuId = @usuar and numcom = @cont) = 0)
				insert into comentario(usuId, numcom, comenta, cuando) values 
							(@usuar, cast(@cont as smallint), 'Esto es un comentario', 
							dbo.getRandomDate('2017-01-01', '2019-10-10'))
							
				set @cont = @cont + 1;
		end
		fetch next from cursor_usuId into @usuar;
	end
close cursor_usuId;
DEALLOCATE  cursor_usuId;

go 

-----------------------------------------------------------------
----------------------- Modificar comentarios -------------------
-----------------------------------------------------------------

drop procedure if exists modificarComentarios;
go 

create procedure modificarComentarios 
as
declare @c int;

IF OBJECT_ID('t1') IS NOT NULL
	DROP TABLE t1;

drop table if EXISTS t1;

IF OBJECT_ID('t2') IS NOT NULL
	DROP TABLE t2;

drop table if EXISTS t2;

select @c=count(*)*0.3 from comentario;

select usuId,numcom,row_number() over (order by usuId) rn into t1
from (select top(@c) usuId,numcom from comentario order by newid()) t;

select usuId,numcom,row_number() over (order by usuId) rn into t2
from (select top(@c) usuId,numcom from comentario order by newid()) t;

UPDATE comentario set respondea=t2.usuId, respondeanum=t2.numcom
from comentario c
--comentario que es respuesta
join t1 on (c.usuId=t1.usuId and c.numcom=t1.numcom)
--comentario al que responde
join t2 on (t1.rn=t2.rn)
where t1.usuId<>t2.usuId or t1.numcom<>t2.numcom;--que no sean el mismo

go

-----------------------------------------------------------------
----------------------- Crear valoraciones ----------------------
-----------------------------------------------------------------

drop procedure if exists crearValoraciones
go

create procedure crearValoraciones @nusu int, @ncom int
as
declare @usuId int, @numcom int, @valoracion int,  @elusuario int, @valora_a_suario int 

IF OBJECT_ID('t1') IS NOT NULL
	DROP TABLE t1;

drop table if EXISTS t1;

IF OBJECT_ID('t2') IS NOT NULL
	DROP TABLE t2;

drop table if EXISTS t2;


select top(cast((@ncom*0.25) as int )) usuId, c.numcom into t1 from comentario c order by newid();
select top(cast((@nusu*0.05) as int )) usuId into t2 from usuario order by newid();

declare cursor_valoraciones cursor for select top(cast((select count(*)*0.5 from t1, t2) as int )) t2.usuId elusuario, t1.usuId valora_a_suario,  t1.numcom from t1, t2 order by newid();
open cursor_valoraciones
fetch next from cursor_valoraciones into @elusuario, @valora_a_suario, @numcom;
while @@FETCH_STATUS = 0
	begin 
		set @valoracion = floor(rand()*5)+1;
		insert into valora(usuId, valorado, valora.numcom, estrellas) values 
							(@elusuario, @valora_a_suario, cast(@numcom as smallint), @valoracion)
							
		fetch next from cursor_valoraciones into @elusuario, @valora_a_suario, @numcom;
	end
close cursor_valoraciones;
DEALLOCATE  cursor_valoraciones;

go

-----------------------------------------------------------------
----------------------- Asignar palabras clave ------------------
-----------------------------------------------------------------

drop procedure if exists asignarPalabraClave
go 

create procedure asignarPalabraClave @maxpals int
as 
declare @usuid int, @numcom int, @cont int, @palclave varchar(20);
declare comentario_max cursor for select usuid, numcom from comentario;
open comentario_max

fetch next from comentario_max  into @usuid, @numcom;
while @@FETCH_STATUS = 0
	begin 
		set @cont = floor(rand()*@maxpals)+1;
		while @cont > 0
		begin
			set @palclave = (select top(1) keyw from PALABRASCLAVE ORDER BY newid());
			if((select count(*) from COMKEYW where keyw = @palclave) = 0)
				insert into COMKEYW (keyw, usuId, numcom) values 
								(@palclave, @usuid, @numcom);
			
			set @cont = @cont - 1;

		end					
		fetch next from comentario_max into @usuid, @numcom;
	end
close comentario_max;
DEALLOCATE  comentario_max;
go

-----------------------------------------------------------------
----------------------- Crear conexiones ------------------------
-----------------------------------------------------------------

drop procedure if exists crearConxiones;
go

create procedure crearConexiones
as 

declare @usuid int, @numcom int, @cont int, @hoy datetime;
declare usuarios cursor for select usuid from usuario;
open usuarios

fetch next from usuarios  into @usuid;
while @@FETCH_STATUS = 0
	begin 
		set @cont = floor(rand()*3)+1;
		while @cont > 0
		begin
			set @hoy = dbo.getRandomDate('20150101','20190930');
			insert into conexion(usuId, entra) values (@usuid, @hoy);
			
			set @cont = @cont - 1;

		end					
		fetch next from usuarios  into @usuid;
	end
close  usuarios;
DEALLOCATE   usuarios;


-----------------------------------------------------------------
----------------- Combinar todo en un único PA ------------------
-----------------------------------------------------------------

drop procedure if exists generar_bd
go
create procedure generar_bd @cant int
as 
exec generar_usuarios @cant;
exec gen_sigue;
exec gen_comenta @cant, @cant;
exec modificarComentarios; 
exec crearValoraciones @cant, @cant;
exec asignarPalabraClave 4;
exec crearConexiones;

go

exec generar_bd 100

select
(select count(*) from usuario) usuarios,
(select count(*) from sigue) sigue,
(select count(*) from comentario) comentarios,
(select count(*) from comentario where respondea is not null) respuestas,
(select count(*) from valora) valoraciones,
(select count(*) from comkeyw) palabras_clave,
(select count(*) from conexion) conexiones;
go






select * from conexion;
select * from usuario;
select * from sigue;
select*from comentario;
select*from valora;
select * from COMKEYW;