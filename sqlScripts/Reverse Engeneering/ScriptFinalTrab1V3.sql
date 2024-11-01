use smart_buildingsdb;
SET FOREIGN_KEY_CHECKS = 0; 

DELETE FROM Clients;
DELETE FROM Contract;
DELETE FROM DevicesInput;
DELETE FROM DevicesOutput;
DELETE FROM DeviceStateDesc;
DELETE FROM DeviceTypeDesc;
DELETE FROM DeviceDesc;
DELETE FROM Installation;
DELETE FROM InstallationTypeDesc;
DELETE FROM ServiceDesc;
DELETE FROM Invoice;
DELETE FROM InvoiceStateDesc;
DELETE FROM Suppliers;

ALTER TABLE `Clients`               AUTO_INCREMENT = 0;
ALTER TABLE `Contract`              AUTO_INCREMENT = 0;
ALTER TABLE `DevicesInput`          AUTO_INCREMENT = 0;
ALTER TABLE `DevicesOutput`         AUTO_INCREMENT = 0;
ALTER TABLE `DeviceStateDesc`       AUTO_INCREMENT = 0;
ALTER TABLE `DeviceTypeDesc`        AUTO_INCREMENT = 0;
ALTER TABLE `DeviceDesc`            AUTO_INCREMENT = 0;
ALTER TABLE `Installation`          AUTO_INCREMENT = 0;
ALTER TABLE `InstallationTypeDesc`  AUTO_INCREMENT = 0;
ALTER TABLE `ServiceDesc`           AUTO_INCREMENT = 0;
ALTER TABLE `Invoice`               AUTO_INCREMENT = 0;
ALTER TABLE `InvoiceStateDesc`      AUTO_INCREMENT = 0;
ALTER TABLE `Suppliers`             AUTO_INCREMENT = 0;

CREATE OR REPLACE VIEW DevicesAll AS 
	SELECT InstallationDate, InstallationID, ModelID, StateID, Description
		FROM DevicesOutput 
	UNION ALL 
		SELECT InstallationDate, InstallationID, ModelID, StateID, Description
		FROM DevicesInput d;
	
INSERT IGNORE INTO 
ServiceDesc (name			, Cost	, MaxDevices)
	VALUES	("Lowcost"		, 10	, 2			),
			("Normal"		, 20	, 4			),
			("Professional"	, 30	, NULL		);

INSERT IGNORE INTO 
InvoiceStateDesc (StateID, Description)
		  VALUES (0		 , "Pending"  ),
				 (1		 , "Paid" 	  );
                 
INSERT IGNORE INTO 
InstallationTypeDesc (TypeID, Name)
			  VALUES ( 1	, "House" 		),
					 ( 2	, "Office" 		),
					 ( 3	, "Apartment" 	),
                     ( 4	, "Store"	 	);
                     
INSERT INTO Suppliers (name , main_address,contact)
VALUES
("BOBOTECH", "38043 My Wells, North Celinaburgh, OH 35513-7729","+14028867850"),
("StayFreshINC", "5708 O'Keefe Vista, Port Israelmouth, AL 31806","+18175445111"),
("SAMSUNG","Everland-ro, Pogok-eup, Cheoin-gu, Yongin-si, Gyeonggi-do, Korea","82-31-320-5000");

INSERT IGNORE INTO 
DeviceTypeDesc 	( Description 	 )
		Values 	( "Input"  		 ),
				( "Output" 		 ),
                ( "Input/Output" );
INSERT INTO 
DeviceDesc 	( Model 			, SupplierID 	, TypeID)
	Values 	( "Bleu"			, 1 			, 2		),
			( "Fridge"			, 1 			, 2		),
			( "Smart Plug"		, 3 			, 3		),
            ( "Washing Machine"	, 2				, 2		),
            ( "Termomo"			, 2				, 1		),
			( "AC"				, 2 			, 2		);
            
INSERT IGNORE INTO 
DeviceStateDesc ( Description )
		 Values ( "Active" 	  ),
				( "Inactive"  );
                
DROP PROCEDURE IF EXISTS clients_by_installation_type;
DROP PROCEDURE IF EXISTS clients_by_package_type;
DROP PROCEDURE IF EXISTS installation_devices;
DROP PROCEDURE IF EXISTS client_invoice_average;
DROP PROCEDURE IF EXISTS installations_with_automations;
DROP PROCEDURE IF EXISTS total_clients_InvoiceState;
DROP PROCEDURE IF EXISTS total_Invoice_value_all_clients;
DROP FUNCTION  IF EXISTS get_num_client_installations;

DELIMITER $$$
CREATE PROCEDURE clients_by_installation_type(IN installation_type VARCHAR(15))
BEGIN	
	SELECT c.name, c.Main_Address, i.code as "Installation Code", i.address as Installation_Address
	FROM Clients c
	INNER JOIN installation i on c.idClient = i.Client_idClient 
    INNER JOIN InstallationTypeDesc TD on TD.TypeID = i.TypeID
	WHERE
	TD.Name = installation_type
	ORDER BY
	 name ASC;
END; $$$

-- RF5 Visualizar os clientes que tenham contratado um determinado pacote/serviço.

DELIMITER $$$
CREATE  PROCEDURE clients_by_package_type(IN ServiceType INT)
BEGIN	
	SELECT cl.name, cl.main_address, i.address as Installation_Address, s.name
	FROM installation i
	INNER JOIN Clients 		cl ON cl.idClient = i.Client_idClient
	INNER JOIN Contract 	co ON i.code	  = co.Installation_code
	INNER JOIN ServiceDesc 	s  ON s.Type 	  = co.ServiceDesc_Type 
	WHERE
		co.ServiceDesc_Type = ServiceType;
	-- 1 lowcost , 2 normal, 3 professional
END; $$$


-- RF6 Visualizar todos os dispositivos instalados numa dada instalação dentro de um intervalo de tempo.
DELIMITER $$$
CREATE  PROCEDURE 
	installation_devices(
						IN startDate 		date,
                        IN endDate 			date, 
                        IN installationCode INT )
BEGIN	

	SELECT i.address as Installation_address , dd.Model , d.InstallationDate, d.Description
		FROM DevicesAll d
        INNER JOIN Installation i  ON i.code 			= d.InstallationID 
		INNER JOIN DeviceDesc 	dd ON dd.idDevice_desc 	= d.ModelID
        WHERE
			 i.code = installationCode
			 and (d.InstallationDate >= startDate and d.InstallationDate <= endDate);
        
END; $$$

-- RF7 Visualizar o valor médio de faturação (fatura paga) de um cliente num intervalo de tempo
DELIMITER $$$
CREATE  PROCEDURE 
	client_invoice_average(
					IN startDate 	date,
                    IN endDate 		date,
                    IN clientId 	INT	)
BEGIN	

	SELECT cl.name, AVG(s.cost) as Average_Invoice_Value
		FROM Invoice inv
		INNER JOIN Contract 	co 	ON co.idContract = inv.ContractID
		INNER JOIN ServiceDesc 	s	ON s.Type 		 = co.ServiceDesc_Type 
		INNER JOIN Installation i 	ON i.code 		 = co.Installation_code
		INNER JOIN Clients 		cl 	ON cl.idClient 	 = i.Client_idClient
		WHERE
			cl.idClient = clientId and
			 (inv.Date >= startDate and inv.Date <= endDate);
END; $$$ 
 
-- RF8 Visualizar as instalações com automações, dentro de um intervalo de tempo.   
-- Acho que isto n\ao esta bem  
DELIMITER $$$
CREATE PROCEDURE 
	installations_with_automations(
								IN startDate date,
                                IN endDate 	 date)
BEGIN	

	SELECT i.address as addresses_with_automations, InstallationID
		FROM Installation i
		RIGHT JOIN DevicesALL d ON I.code = d.InstallationID -- Aqui não é igual fazer Inner??
		WHERE
		(d.InstallationDate >= startDate and d.InstallationDate <= endDate) 
		GROUP BY
		i.address;
     
END; $$$

 -- RF10 Proponha um requisito relevante ainda por identificar e que requeira uma query simples para o satisfazer (Query ou View usada numa Query). Implemente.
 -- Todos os clientes que ainda não pagaram o invoice
DELIMITER $$$
CREATE  PROCEDURE total_clients_InvoiceState(IN state VARCHAR(10))
BEGIN

	SELECT cl.name, cl.main_address, i.address as Installation_Address, idesc.Description
		FROM installation i
		INNER JOIN Clients 			cl 		ON cl.idClient	 	= i.Client_idClient
		INNER JOIN Contract 		co  	ON i.code		 	= co.Installation_code
		INNER JOIN Invoice 			inv 	ON co.idContract 	= inv.ContractID
		INNER JOIN InvoiceStateDesc idesc 	ON idesc.StateID 	= inv.State
		WHERE
			idesc.Description = state
		ORDER BY
			cl.name ASC;
END; $$$
    
-- RF 11 Proponha um requisito relevante ainda por identificar e que requeira uma query com funções de agregação (sum, max, min, avg, etc) para o satisfazer. Implemente.
-- total pago ou por pagar por cada cliente
DELIMITER $$$
CREATE  PROCEDURE total_Invoice_value_all_clients()
BEGIN

	SELECT cl.name, idesc.Description as State , SUM(s.cost) as Invoice_Total
		FROM Invoice inv
		INNER JOIN Contract 		co 		ON idContract 	= inv.ContractID
		INNER JOIN ServiceDesc 		s 		ON s.Type 		= co.ServiceDesc_Type 
		INNER JOIN Installation 	i 		ON i.code 		= co.Installation_code
		INNER JOIN Clients 			cl 		ON cl.idClient 	= i.Client_idClient
        INNER JOIN InvoiceStateDesc idesc 	ON inv.State 	= idesc.StateID
		GROUP BY
		cl.name
		ORDER BY
			cl.name ASC;
        
END; $$$

-- RF 12 Proponha um requisito relevante ainda por identificar e que requeira o desenvolvimento de functions / procedures para o satisfazer. Implemente.
DELIMITER $$$
CREATE FUNCTION get_num_client_installations(ClientId int)
RETURNS int
BEGIN 
	DECLARE total int;
	SELECT COUNT(i.code) INTO total
	FROM installation i
	INNER JOIN Clients cl ON cl.idClient = i.Client_idClient
	WHERE
		cl.idClient = ClientId;
        
	RETURN total;
END;
$$$

-- Rf4
call clients_by_installation_type("House");
-- RF5
call clients_by_package_type(1); -- digit service package type (-- 1 lowcost , 2 normal, 3 professional)
-- RF6
call installation_devices('2000-01-01','2029-3-31',6); -- last digit installation code
-- RF7 
 call client_invoice_average('2000-01-01','2029-3-31',6); -- last digit is clientId
-- RF8 
 call installations_with_automations('2020-01-01','2024-03-31');
-- RF10
call total_clients_InvoiceState("Pending"); -- or "Paid"
-- RF 11
call total_Invoice_value_all_clients();
-- RF12
select get_num_client_installations(2); -- digit is clientId

Select * from Clients;
Select * from Contract;
Select * from DevicesInput;
Select * from DevicesOutput;
Select * from DeviceStateDesc;
Select * from DeviceTypeDesc;
Select * from DeviceDesc;
Select * from Installation;
Select * from InstallationTypeDesc;
Select * from ServiceDesc;
Select * from Invoice;
Select * from InvoiceStateDesc;
Select * from Suppliers;