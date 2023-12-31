DROP TABLE IF EXISTS client CASCADE;
DROP TABLE IF EXISTS phone_number_client CASCADE;
DROP TABLE IF EXISTS employee CASCADE;
DROP TABLE IF EXISTS phone_number_employee CASCADE;
DROP TABLE IF EXISTS receptionist CASCADE;
DROP TABLE IF EXISTS nurse CASCADE;
DROP TABLE IF EXISTS doctor CASCADE;
DROP TABLE IF EXISTS permanent_doctor CASCADE;
DROP TABLE IF EXISTS trainee_doctor CASCADE;
DROP TABLE IF EXISTS supervision_report CASCADE;
DROP TABLE IF EXISTS appointment CASCADE;
DROP TABLE IF EXISTS consultation CASCADE;
DROP TABLE IF EXISTS consultation_assistant CASCADE;
DROP TABLE IF EXISTS diagnostic_code CASCADE;
DROP TABLE IF EXISTS diagnostic_code_relation CASCADE;
DROP TABLE IF EXISTS consultation_diagnostic CASCADE;
DROP TABLE IF EXISTS medication CASCADE;
DROP TABLE IF EXISTS prescription CASCADE;
DROP TABLE IF EXISTS procedure_ CASCADE;
DROP TABLE IF EXISTS procedure_in_consultation CASCADE;
DROP TABLE IF EXISTS teeth CASCADE;
DROP TABLE IF EXISTS procedure_charting CASCADE;
DROP TABLE IF EXISTS procedure_imaging CASCADE;

----------------------------------------
-- Table Creation
----------------------------------------
CREATE TABLE client (
  VAT_ID VARCHAR(20),
  name VARCHAR(80),
  birth_date DATE,
  street VARCHAR(255),
  city VARCHAR(30),
  zip_code VARCHAR(12),
  gender CHAR(1),
  PRIMARY KEY (VAT_ID),
  CHECK (gender in ('M', 'F')) 
);

CREATE TABLE phone_number_client (
  VAT_ID VARCHAR(20),
  phone VARCHAR(15),
  PRIMARY KEY (VAT_ID, phone),
  FOREIGN KEY(VAT_ID) REFERENCES client(VAT_ID)
);

CREATE TABLE employee (
  VAT_ID VARCHAR(20),
  name VARCHAR(80),
  birth_date DATE,
  street VARCHAR(255),
  city VARCHAR(30),
  zip_code VARCHAR(12),
  IBAN VARCHAR(30) NOT NULL,
  salary NUMERIC(12,4),
  UNIQUE(IBAN),
  PRIMARY KEY (VAT_ID),
  CHECK (salary > 0)

  -- Every employee must exist either in the table 'receptionist' or in the table 'nurse' or in the table 'doctor'
  -- No employee can exist at the same time in the both the table 'receptionist' or in the table 'nurse' or in the table 'doctor'
);

CREATE TABLE phone_number_employee (
  VAT_ID VARCHAR(20),
  phone VARCHAR(15),
  PRIMARY KEY (VAT_ID, phone),
  FOREIGN KEY(VAT_ID) REFERENCES employee(VAT_ID)
);

CREATE TABLE receptionist (
  VAT_ID VARCHAR(20),
  PRIMARY KEY (VAT_ID),
  FOREIGN KEY(VAT_ID) REFERENCES employee(VAT_ID)
);

CREATE TABLE nurse (
  VAT_ID VARCHAR(20),
  PRIMARY KEY (VAT_ID),
  FOREIGN KEY(VAT_ID) REFERENCES employee(VAT_ID)
);

CREATE TABLE doctor (
  VAT_ID VARCHAR(20),
  specialization VARCHAR(254),
  biography VARCHAR(512),
  email_address VARCHAR(254) NOT NULL,
  UNIQUE(email_address),
  PRIMARY KEY (VAT_ID),
  FOREIGN KEY(VAT_ID) REFERENCES employee(VAT_ID)

  -- Every doctor must exist either in the table 'Trainee' or in the table 'Permanent'
  -- No doctor can exist at the same time in the both the table 'Trainee' or in the table 'Permanent'  
);

CREATE TABLE permanent_doctor (
  VAT_ID VARCHAR(20),
  years DATE,
  PRIMARY KEY (VAT_ID),
  FOREIGN KEY(VAT_ID) REFERENCES doctor(VAT_ID)
);

CREATE TABLE trainee_doctor (
  VAT_ID VARCHAR(20),
  supervisor VARCHAR(20) NOT NULL,
  PRIMARY KEY (VAT_ID),
  FOREIGN KEY(VAT_ID) REFERENCES doctor(VAT_ID),
  FOREIGN KEY(supervisor) REFERENCES permanent_doctor(VAT_ID)
);

CREATE TABLE supervision_report(
  VAT_ID VARCHAR(20),
  date_timestamp TIMESTAMP,
  description VARCHAR(512),
  evaluation NUMERIC(3,1),
  PRIMARY KEY(VAT_ID, date_timestamp),
  FOREIGN KEY(VAT_ID) REFERENCES trainee_doctor(VAT_ID),
  CHECK (evaluation >= 1 AND evaluation <= 5)
);

CREATE TABLE appointment (
  VAT_doctor VARCHAR(20),
  date_timestamp TIMESTAMP,
  VAT_client VARCHAR(20),
  description VARCHAR(512),
  PRIMARY KEY (VAT_doctor, date_timestamp),
  FOREIGN KEY(VAT_doctor) REFERENCES doctor(VAT_ID),
  FOREIGN KEY(VAT_client) REFERENCES client(VAT_ID)
);

CREATE TABLE consultation(
  VAT_doctor VARCHAR(20),
  date_timestamp TIMESTAMP,
  SOAP_S TEXT,  
  SOAP_O TEXT,
  SOAP_A TEXT,
  SOAP_P TEXT,
  PRIMARY KEY (VAT_doctor, date_timestamp),
  FOREIGN KEY(VAT_doctor, date_timestamp) REFERENCES appointment(VAT_doctor, date_timestamp)
    
  -- consultations are always assigned to at least one assistant nurse
);

CREATE TABLE consultation_assistant(
  VAT_doctor VARCHAR(20),
  date_timestamp TIMESTAMP,
  VAT_nurse VARCHAR(20),  
  PRIMARY KEY (VAT_doctor, date_timestamp),
  FOREIGN KEY(VAT_doctor, date_timestamp) REFERENCES appointment(VAT_doctor, date_timestamp),
  FOREIGN KEY(VAT_nurse) REFERENCES nurse(VAT_ID)
);

CREATE TABLE diagnostic_code(
  ID INTEGER,
  description VARCHAR(255),  
  PRIMARY KEY (ID)
);

CREATE TABLE diagnostic_code_relation(
  ID1 INTEGER,
  ID2 INTEGER,
  type VARCHAR(255),
  PRIMARY KEY (ID1, ID2),
  FOREIGN KEY(ID1) REFERENCES diagnostic_code(ID),
  FOREIGN KEY(ID2) REFERENCES diagnostic_code(ID)
);

CREATE TABLE consultation_diagnostic(
  VAT_doctor VARCHAR(20),
  date_timestamp TIMESTAMP,
  ID INTEGER,
  UNIQUE(VAT_doctor, date_timestamp, ID),
  PRIMARY KEY(VAT_doctor, date_timestamp),
  FOREIGN KEY (VAT_doctor, date_timestamp) REFERENCES consultation(VAT_doctor, date_timestamp),
  FOREIGN KEY (ID) REFERENCES diagnostic_code(ID)
);

CREATE TABLE medication(
  name VARCHAR(64),
  lab VARCHAR(255),
  PRIMARY KEY(name, lab)
);

CREATE TABLE prescription(
  VAT_doctor VARCHAR(20),
  date_timestamp TIMESTAMP,
  ID INTEGER,
  name VARCHAR(64),
  lab VARCHAR(255),
  dosage VARCHAR(20),
  description VARCHAR(512),
  PRIMARY KEY(VAT_doctor, date_timestamp, ID, name, lab),
  FOREIGN KEY (VAT_doctor, date_timestamp, ID) REFERENCES consultation_diagnostic(VAT_doctor, date_timestamp, ID),
  FOREIGN KEY (name, lab) REFERENCES medication(name, lab)
);

CREATE TABLE procedure_(
  name VARCHAR(255),
  type VARCHAR(255),
  PRIMARY KEY(name)
);

CREATE TABLE procedure_in_consultation(
  name VARCHAR(255),
  VAT_doctor VARCHAR(20),
  date_timestamp TIMESTAMP,
  description VARCHAR(512),
  PRIMARY KEY(name, VAT_doctor, date_timestamp),
  FOREIGN KEY(name) REFERENCES procedure_(name),
  FOREIGN KEY(VAT_doctor, date_timestamp) REFERENCES consultation(VAT_doctor, date_timestamp)
);

CREATE TABLE teeth(
  quadrant VARCHAR(64),
  number CHAR(1),
  name VARCHAR(255),
  PRIMARY KEY(quadrant, number)
);

CREATE TABLE procedure_charting(
  name VARCHAR(255),
  VAT_doctor VARCHAR(20),
  date_timestamp TIMESTAMP,
  quadrant VARCHAR(64),
  number CHAR(1),
  desc_ VARCHAR(512),
  measure NUMERIC(6,3),
  PRIMARY KEY(name, VAT_doctor, date_timestamp, quadrant, number),
  FOREIGN KEY(name, VAT_doctor, date_timestamp) REFERENCES procedure_in_consultation(name, VAT_doctor, date_timestamp),
  FOREIGN KEY(quadrant, number) REFERENCES teeth(quadrant, number)
);

CREATE TABLE procedure_imaging(
  name VARCHAR(255),
  VAT_doctor VARCHAR(20),
  date_timestamp TIMESTAMP,
  file VARCHAR(512),
  PRIMARY KEY(name, VAT_doctor, date_timestamp, file),
  FOREIGN KEY(name, VAT_doctor, date_timestamp) REFERENCES procedure_in_consultation(name, VAT_doctor, date_timestamp)
);

----------------------------------------
-- Populate Relations
----------------------------------------

-- Insert into client
INSERT INTO client VALUES('123456789', 'John Doe', '1955-03-12', 'Rua Principal 16', 'Lisbon', '1000-000', 'M');
INSERT INTO client VALUES('983654320', 'Laura Appleton', '1960-06-25', 'Avenida Liberdade 25', 'Lisbon', '1030-500', 'F');
INSERT INTO client VALUES('223456789', 'Mia White', '1972-01-30', 'Travessa dos Salgueiros 35', 'Sintra', '2710-000', 'F');
INSERT INTO client VALUES('323456789', 'Noah Black', '1980-11-15', 'Largo das Oliveiras 45', 'Oeiras', '2780-000', 'M');
INSERT INTO client VALUES('423456789', 'Sophia Hill', '1996-08-09', 'Rua dos Cedros 37', 'Coimbra', '3000-000', 'F');
INSERT INTO client VALUES('523456789', 'Liam Pine', '1988-09-23', 'Rua do Carvalho 15', 'Faro', '8000-000', 'M');
INSERT INTO client VALUES('823456789', 'Ivy Rose', '2003-02-17', 'Rua dos Pinheiros 46', 'Funchal', '9000-000', 'F');
INSERT INTO client VALUES('923456789', 'Jack Frost', '1950-12-05', 'Estrada do Carvalhal 32', 'Viseu', '3500-000', 'M');

INSERT INTO client VALUES('624456789', 'Alice Waters', '1983-07-07', 'Rua do Rio 3', 'Guimarães', '4800-000', 'F');
INSERT INTO client VALUES('724456789', 'Maxwell Bright', '1992-12-14', 'Rua da Encosta 5', 'Santarém', '2000-000', 'M');
INSERT INTO client VALUES('824456789', 'Iris Bloom', '1979-04-22', 'Rua do Jardim 8', 'Bragança', '5300-000', 'F');


-- Insert into phone_number_client
INSERT INTO phone_number_client VALUES('123456789', '912345678');
INSERT INTO phone_number_client VALUES('223456789', '913345678');
INSERT INTO phone_number_client VALUES('323456789', '914456789');
INSERT INTO phone_number_client VALUES('423456789', '915678901');
INSERT INTO phone_number_client VALUES('523456789', '916789012');
INSERT INTO phone_number_client VALUES('823456789', '919876543');
INSERT INTO phone_number_client VALUES('923456789', '920987654');

INSERT INTO phone_number_client VALUES('624456789', '917654321');
INSERT INTO phone_number_client VALUES('724456789', '918765432');
INSERT INTO phone_number_client VALUES('824456789', '919876543');

-- Insert into employee
INSERT INTO employee VALUES('987654321', 'Robin Smith', '1980-05-15', 'Rua das Ameixas 45', 'Lisboa', '4000-123', '0002 0123 1234 5678 9015 4', 900.00);
INSERT INTO employee VALUES('987654320', 'Jane Sweettooth', '1968-04-16', 'Avenida da Liberdade 36', 'Lisboa', '1050-153', '0002 0223 1234 5678 9015 4', 3000.00);
INSERT INTO employee VALUES('987654319', 'Jonh Red', '1991-10-26', 'Largo das Camélias 6', 'Lisboa', '1100-026', '0002 0123 1234 5678 1015 4', 1200.00);
INSERT INTO employee VALUES('983654320', 'Bob Sweden', '1991-02-17', 'Rua dos Cravos 82', 'Lisboa', '1150-103', '0002 0223 1244 5678 9015 4', 1600.00);
INSERT INTO employee VALUES('876543210', 'Emma Green', '1985-07-20', 'Praceta das Rosas 1', 'Lisboa', '4001-123', '0002 0333 1234 5678 9015 4', 1200.00);
INSERT INTO employee VALUES('876543211', 'Olivia Brown', '1990-08-22', 'Rua das Margaridas 4', 'Lisboa', '1051-153', '0002 0444 1234 5678 9015 4', 1800.00);
INSERT INTO employee VALUES('876543212', 'Sarah Clark', '1980-12-05', 'Avenida das Tulipas 22', 'Lisboa', '4050-000', '0002 0555 1234 5678 9015 4', 3200.00);
INSERT INTO employee VALUES('876543213', 'Luke Grayson', '1978-07-19', 'Rua Azul 33', 'Lisbon', '1100-000', '0002 0666 1234 5678 9015 4', 3400.00);
INSERT INTO employee VALUES('876543214', 'Ethan Storm', '1989-08-15', 'Rua do Vento 45', 'Setúbal', '4700-000', '0002 0777 1234 5678 9015 4', 1300.00);
INSERT INTO employee VALUES('876543215', 'Chloe Brooks', '1993-05-20', 'Rua do Sol 67', 'Setúbal', '3810-000', '0002 0888 1234 5678 9015 4', 1350.00);
INSERT INTO employee VALUES('876543216', 'Ava Taylor', '1995-10-11', 'Avenida da Chuva 12', 'Setúbal', '2900-000', '0002 0999 1234 5678 9015 4', 1280.00);
INSERT INTO employee VALUES('876543217', 'Ryan Leaf', '1976-03-30', 'Rua das Flores 90', 'Setúbal', '8001-000', '0002 1010 1234 5678 9015 4', 950.00);


-- Insert into phone_number_employee
INSERT INTO phone_number_employee VALUES('987654321', '931234567');
INSERT INTO phone_number_employee VALUES('987654320', '931254567');
INSERT INTO phone_number_employee VALUES('987654319', '931214567');
INSERT INTO phone_number_employee VALUES('983654320', '911214567');
INSERT INTO phone_number_employee VALUES('876543210', '932334567');
INSERT INTO phone_number_employee VALUES('876543211', '932445678');
INSERT INTO phone_number_employee VALUES('876543212', '933556677');
INSERT INTO phone_number_employee VALUES('876543213', '944667788');
INSERT INTO phone_number_employee VALUES('876543214', '935556677');
INSERT INTO phone_number_employee VALUES('876543215', '936667788');
INSERT INTO phone_number_employee VALUES('876543216', '937778899');
INSERT INTO phone_number_employee VALUES('876543217', '938889910');


-- Insert into receptionist
-- Note: A receptionist is also an employee, so make sure the VAT_ID exists in the employee table.
INSERT INTO receptionist VALUES('987654321');
INSERT INTO receptionist VALUES('876543217');

-- Insert into nurse
-- Note: A nurse is also an employee, so make sure the VAT_ID exists in the employee table.
-- Example with a different employee for the nurse role
INSERT INTO nurse VALUES('987654319');
INSERT INTO nurse VALUES('876543214');
INSERT INTO nurse VALUES('876543215');
INSERT INTO nurse VALUES('876543216');

-- Insert into doctor
INSERT INTO doctor VALUES('987654320', 'Dentistry', 'Experienced dentist', 'jane.sweettooth@email.com');
INSERT INTO doctor VALUES('983654320', 'Dentistry', 'Trainee dentist', 'bob.sweden@email.com');
INSERT INTO doctor VALUES('876543210', 'General Medicine', 'Experienced GP', 'emma.green@email.com');
INSERT INTO doctor VALUES('876543211', 'Pediatrics', 'Pediatric specialist', 'olivia.brown@email.com');
INSERT INTO doctor VALUES('876543212', 'Orthodontics', 'Orthodontic specialist', 'sarah.ortho@email.com');
INSERT INTO doctor VALUES('876543213', 'Oral Surgery', 'Experienced oral surgeon', 'luke.surgeon@email.com');


-- Insert into permanent_doctor
INSERT INTO permanent_doctor VALUES('987654320', '2000-01-10');
INSERT INTO permanent_doctor VALUES('876543210', '2010-02-15');
INSERT INTO permanent_doctor VALUES('876543212', '2008-08-20');
INSERT INTO permanent_doctor VALUES('876543213', '2010-10-25');

-- Insert into trainee_doctor
-- Note: Ensure the supervisor exists in the permanent_doctor table.
INSERT INTO trainee_doctor VALUES('983654320', '876543210');  -- Bob Sweden supervised by Emma Green
INSERT INTO trainee_doctor VALUES('876543211', '987654320');  -- Olivia Brown supervised by Jane Sweettooth

-- Insert into supervision_report
INSERT INTO supervision_report VALUES('983654320', '2023-12-10 09:00:00', 'Good progress in training.', 4.0);
INSERT INTO supervision_report VALUES('983654320', '2023-11-05 14:00:00', 'Needs improvement in patient communication.', 2.5);
INSERT INTO supervision_report VALUES('983654320', '2023-10-20 10:00:00', 'Insufficient knowledge in dental procedures.', 2.0);
INSERT INTO supervision_report VALUES('876543211', '2023-09-15 11:30:00', 'Excellent in pediatric care.', 4.5);


-- Insert into appointment
INSERT INTO appointment VALUES('876543213', '2019-06-10 11:00:00', '923456789', 'Oral surgery consultation');
INSERT INTO appointment VALUES('876543212', '2019-06-20 15:00:00', '823456789', 'Orthodontic check-up');
INSERT INTO appointment VALUES('983654320', '2022-11-01 14:00:00', '223456789', 'Routine dental check-up');
INSERT INTO appointment VALUES('987654320', '2023-01-10 10:00:00', '123456789', 'Routine dental check-up');
INSERT INTO appointment VALUES('987654320', '2023-01-11 11:00:00', '123456789', 'Pain management consultation');
INSERT INTO appointment VALUES('987654320', '2023-01-12 09:30:00', '223456789', 'Regular dental check-up');
INSERT INTO appointment VALUES('987654320', '2023-01-12 12:00:00', '123456789', 'Follow-up dental check-up');
INSERT INTO appointment VALUES('987654320', '2023-01-15 10:00:00', '323456789', 'Regular dental check-up');
INSERT INTO appointment VALUES('987654320', '2023-01-16 11:00:00', '423456789', 'Dental check-up');
INSERT INTO appointment VALUES('987654320', '2023-01-17 12:00:00', '523456789', 'Dental check-up');
INSERT INTO appointment VALUES('876543212', '2023-01-20 14:30:00', '323456789', 'Cavity check-up');
INSERT INTO appointment VALUES('876543213', '2023-01-21 16:00:00', '423456789', 'Infection check-up');

INSERT INTO appointment (VAT_doctor, date_timestamp, VAT_client, description) VALUES
('987654320', '2019-01-02 15:00:00', '123456789', 'Routine dental check-up'),
('987654320', '2019-01-04 15:00:00', '983654320', 'Dental cleaning'),
('987654320', '2019-01-06 15:00:00', '223456789', 'Cavity consultation'),
('987654320', '2019-01-08 15:00:00', '323456789', 'Tooth extraction consultation'),
('987654320', '2019-01-10 15:00:00', '423456789', 'Routine dental check-up'),
('987654320', '2019-01-12 15:00:00', '523456789', 'Dental cleaning'),
('987654320', '2019-01-14 15:00:00', '823456789', 'Cavity filling'),
('987654320', '2019-01-16 15:00:00', '923456789', 'Teeth whitening consultation'),
('987654320', '2019-01-18 15:00:00', '123456789', 'Dental implant consultation'),
('987654320', '2019-01-20 15:00:00', '983654320', 'Routine dental check-up'),
('987654320', '2019-02-02 15:00:00', '123456789', 'Routine dental check-up'),
('987654320', '2019-02-04 15:00:00', '983654320', 'Dental cleaning'),
('987654320', '2019-02-06 15:00:00', '223456789', 'Cavity consultation'),
('987654320', '2019-02-08 15:00:00', '323456789', 'Tooth extraction consultation'),
('987654320', '2019-02-10 15:00:00', '423456789', 'Routine dental check-up'),
('987654320', '2019-02-12 15:00:00', '523456789', 'Dental cleaning'),
('987654320', '2019-02-14 15:00:00', '823456789', 'Cavity filling'),
('987654320', '2019-02-16 15:00:00', '923456789', 'Teeth whitening consultation'),
('987654320', '2019-02-18 15:00:00', '123456789', 'Dental implant consultation'),
('987654320', '2019-02-20 15:00:00', '983654320', 'Routine dental check-up'),    
('987654320', '2019-03-02 15:00:00', '123456789', 'Routine dental check-up'),
('987654320', '2019-03-04 15:00:00', '983654320', 'Dental cleaning'),
('987654320', '2019-03-06 15:00:00', '223456789', 'Cavity consultation'),
('987654320', '2019-03-08 15:00:00', '323456789', 'Tooth extraction consultation'),
('987654320', '2019-03-10 15:00:00', '423456789', 'Routine dental check-up'),
('987654320', '2019-03-12 15:00:00', '523456789', 'Dental cleaning'),
('987654320', '2019-03-14 15:00:00', '823456789', 'Cavity filling'),
('987654320', '2019-03-16 15:00:00', '923456789', 'Teeth whitening consultation'),
('987654320', '2019-03-18 15:00:00', '123456789', 'Dental implant consultation'),
('987654320', '2019-03-20 15:00:00', '983654320', 'Routine dental check-up'),        
('987654320', '2019-04-02 15:00:00', '123456789', 'Routine dental check-up'),
('987654320', '2019-04-04 15:00:00', '983654320', 'Dental cleaning'),
('987654320', '2019-04-06 15:00:00', '223456789', 'Cavity consultation'),
('987654320', '2019-04-08 15:00:00', '323456789', 'Tooth extraction consultation'),
('987654320', '2019-04-10 15:00:00', '423456789', 'Routine dental check-up'),
('987654320', '2019-04-12 15:00:00', '523456789', 'Dental cleaning'),
('987654320', '2019-04-14 15:00:00', '823456789', 'Cavity filling'),
('987654320', '2019-04-16 15:00:00', '923456789', 'Teeth whitening consultation'),
('987654320', '2019-04-18 15:00:00', '123456789', 'Dental implant consultation'),
('987654320', '2019-04-20 15:00:00', '983654320', 'Routine dental check-up'), 
('987654320', '2019-05-02 15:00:00', '123456789', 'Routine dental check-up'),
('987654320', '2019-05-04 15:00:00', '983654320', 'Dental cleaning'),
('987654320', '2019-05-06 15:00:00', '223456789', 'Cavity consultation'),
('987654320', '2019-05-08 15:00:00', '323456789', 'Tooth extraction consultation'),
('987654320', '2019-05-10 15:00:00', '423456789', 'Routine dental check-up'),
('987654320', '2019-05-12 15:00:00', '523456789', 'Dental cleaning'),
('987654320', '2019-05-14 15:00:00', '823456789', 'Cavity filling'),
('987654320', '2019-05-16 15:00:00', '923456789', 'Teeth whitening consultation'),
('987654320', '2019-05-18 15:00:00', '123456789', 'Dental implant consultation'),
('987654320', '2019-05-20 15:00:00', '983654320', 'Routine dental check-up'), 
('987654320', '2019-06-02 15:00:00', '123456789', 'Routine dental check-up'),
('987654320', '2019-06-04 15:00:00', '983654320', 'Dental cleaning'),
('987654320', '2019-06-06 15:00:00', '223456789', 'Cavity consultation'),
('987654320', '2019-06-08 15:00:00', '323456789', 'Tooth extraction consultation'),
('987654320', '2019-06-10 15:00:00', '423456789', 'Routine dental check-up'),
('987654320', '2019-06-12 15:00:00', '523456789', 'Dental cleaning'),
('987654320', '2019-06-14 15:00:00', '823456789', 'Cavity filling'),
('987654320', '2019-06-16 15:00:00', '923456789', 'Teeth whitening consultation'),
('987654320', '2019-06-18 15:00:00', '123456789', 'Dental implant consultation'),
('987654320', '2019-06-20 15:00:00', '983654320', 'Routine dental check-up'),    
('987654320', '2019-07-02 15:00:00', '123456789', 'Routine dental check-up'),
('987654320', '2019-07-04 15:00:00', '983654320', 'Dental cleaning'),
('987654320', '2019-07-06 15:00:00', '223456789', 'Cavity consultation'),
('987654320', '2019-07-08 15:00:00', '323456789', 'Tooth extraction consultation'),
('987654320', '2019-07-10 15:00:00', '423456789', 'Routine dental check-up'),
('987654320', '2019-07-12 15:00:00', '523456789', 'Dental cleaning'),
('987654320', '2019-07-14 15:00:00', '823456789', 'Cavity filling'),
('987654320', '2019-07-16 15:00:00', '923456789', 'Teeth whitening consultation'),
('987654320', '2019-07-18 15:00:00', '123456789', 'Dental implant consultation'),
('987654320', '2019-07-20 15:00:00', '983654320', 'Routine dental check-up'), 
('987654320', '2019-08-02 15:00:00', '123456789', 'Routine dental check-up'),
('987654320', '2019-08-04 15:00:00', '983654320', 'Dental cleaning'),
('987654320', '2019-08-06 15:00:00', '223456789', 'Cavity consultation'),
('987654320', '2019-08-08 15:00:00', '323456789', 'Tooth extraction consultation'),
('987654320', '2019-08-10 15:00:00', '423456789', 'Routine dental check-up'),
('987654320', '2019-08-12 15:00:00', '523456789', 'Dental cleaning'),
('987654320', '2019-08-14 15:00:00', '823456789', 'Cavity filling'),
('987654320', '2019-08-16 15:00:00', '923456789', 'Teeth whitening consultation'),
('987654320', '2019-08-18 15:00:00', '123456789', 'Dental implant consultation'),
('987654320', '2019-08-20 15:00:00', '983654320', 'Routine dental check-up'),    
('987654320', '2019-10-02 15:00:00', '123456789', 'Routine dental check-up'),
('987654320', '2019-10-04 15:00:00', '983654320', 'Dental cleaning'),
('987654320', '2019-10-06 15:00:00', '223456789', 'Cavity consultation'),
('987654320', '2019-10-08 15:00:00', '323456789', 'Tooth extraction consultation'),
('987654320', '2019-10-10 15:00:00', '423456789', 'Routine dental check-up'),
('987654320', '2019-10-12 15:00:00', '523456789', 'Dental cleaning'),
('987654320', '2019-10-14 15:00:00', '823456789', 'Cavity filling'),
('987654320', '2019-10-16 15:00:00', '923456789', 'Teeth whitening consultation'),
('987654320', '2019-10-18 15:00:00', '123456789', 'Dental implant consultation'),
('987654320', '2019-10-20 15:00:00', '983654320', 'Routine dental check-up'),   
('987654320', '2019-11-02 15:00:00', '123456789', 'Routine dental check-up'),
('987654320', '2019-11-04 15:00:00', '983654320', 'Dental cleaning'),
('987654320', '2019-11-06 15:00:00', '223456789', 'Cavity consultation'),
('987654320', '2019-11-08 15:00:00', '624456789', 'Tooth extraction consultation'),
('987654320', '2019-11-10 15:00:00', '724456789', 'Routine dental check-up'),
('987654320', '2019-11-12 15:00:00', '523456789', 'Dental cleaning'),
('987654320', '2019-11-14 15:00:00', '823456789', 'Cavity filling'),
('987654320', '2019-11-16 15:00:00', '923456789', 'Teeth whitening consultation'),
('987654320', '2019-11-18 15:00:00', '123456789', 'Dental implant consultation'),
('987654320', '2019-11-20 15:00:00', '824456789', 'Routine dental check-up');


-- Insert into consultation
INSERT INTO consultation VALUES('876543213', '2019-06-10 11:00:00', 'Oral examination', 'Wisdom tooth extraction needed', 'Surgery scheduled', 'Post-operative care discussion');
INSERT INTO consultation VALUES('876543212', '2019-06-20 15:00:00', 'Orthodontic check', 'Braces adjustment needed', 'Next visit in 2 months', 'Follow-up for brace adjustment');
INSERT INTO consultation VALUES('983654320', '2022-11-01 14:00:00', 'Patient reports discomfort', 'Mild pain observed', 'Prescription of Paracetamol', 'Recommendation to monitor and follow-up if pain persists');
INSERT INTO consultation VALUES('987654320', '2023-01-10 10:00:00', 'Patient reports toothache', 'Cavity in molar tooth', 'Cavity filling required', 'Schedule follow-up after procedure');
INSERT INTO consultation VALUES('987654320', '2023-01-11 11:00:00', 'Discussion about pain', 'Pain management strategies', 'Prescription of Ibuprofen', 'Follow-up if pain persists');
INSERT INTO consultation VALUES('987654320', '2023-01-12 09:30:00', 'Regular check-up', 'Signs of gingivitis observed', 'Advice on better dental hygiene', 'Schedule follow-up in 3 months');
INSERT INTO consultation VALUES('987654320', '2023-01-12 12:00:00', 'Follow-up check-up notes', 'Maintaining oral health', 'Continue current hygiene practices', 'Next check-up in 6 months');
INSERT INTO consultation VALUES('987654320', '2023-01-15 10:00:00', 'Regular check-up', 'Early signs of periodontitis', 'Recommendation for treatment', 'Immediate treatment required');
INSERT INTO consultation VALUES('876543212', '2023-01-20 14:30:00', 'Cavity check', 'Cavity detected in molar tooth', 'Treatment plan discussed', 'Follow-up in 3 weeks');
INSERT INTO consultation VALUES('876543213', '2023-01-21 16:00:00', 'Infection check', 'Patient reports symptoms of infection', 'Prescription provided', 'Follow-up in 1 week');

INSERT INTO consultation VALUES('987654320', '2019-11-08 15:00:00', 'Patient reports discomfort', 'Mild gum recession observed, potential signs of gingivitis', 'Extraction needed', 'Schedule for extraction');
INSERT INTO consultation VALUES('987654320', '2019-11-10 15:00:00', 'Regular check-up', 'Signs of gum inflammation, suggestive of gingivitis', 'Good oral health', 'Continue current hygiene practices');
INSERT INTO consultation VALUES('987654320', '2019-11-20 15:00:00', 'Routine check-up', 'Early signs of gingival recession, indicative of gingivitis', 'Maintain hygiene', 'Next check-up in 6 months');

-- Insert into consultation_assistant
-- Ensure that there is always on assistant per consultation
INSERT INTO consultation_assistant VALUES('876543213', '2019-06-10 11:00:00', '987654319'); 
INSERT INTO consultation_assistant VALUES('876543212', '2019-06-20 15:00:00', '876543214'); 
INSERT INTO consultation_assistant VALUES('983654320', '2022-11-01 14:00:00', '876543215'); 
INSERT INTO consultation_assistant VALUES('987654320', '2023-01-10 10:00:00', '987654319'); 
INSERT INTO consultation_assistant VALUES('987654320', '2023-01-11 11:00:00', '876543216'); 
INSERT INTO consultation_assistant VALUES('987654320', '2023-01-12 09:30:00', '876543214'); 
INSERT INTO consultation_assistant VALUES('987654320', '2023-01-12 12:00:00', '876543215'); 
INSERT INTO consultation_assistant VALUES('987654320', '2023-01-15 10:00:00', '876543216'); 
INSERT INTO consultation_assistant VALUES('876543212', '2023-01-20 14:30:00', '876543214'); 
INSERT INTO consultation_assistant VALUES('876543213', '2023-01-21 16:00:00', '876543215'); 
INSERT INTO consultation_assistant VALUES('987654320', '2019-11-08 15:00:00', '987654319');
INSERT INTO consultation_assistant VALUES('987654320', '2019-11-10 15:00:00', '987654319');
INSERT INTO consultation_assistant VALUES('987654320', '2019-11-20 15:00:00', '987654319');


-- Insert into diagnostic_code
INSERT INTO diagnostic_code VALUES(1, 'Cavity');
INSERT INTO diagnostic_code VALUES(2, 'Infection');
INSERT INTO diagnostic_code VALUES(3, 'Toothache');
INSERT INTO diagnostic_code VALUES(4, 'Bruxism');
INSERT INTO diagnostic_code VALUES(5, 'Gingivitis');


-- Insert into diagnostic_code_relation
INSERT INTO diagnostic_code_relation VALUES(1, 2, 'Related');
INSERT INTO diagnostic_code_relation VALUES(1, 3, 'Related');
INSERT INTO diagnostic_code_relation VALUES(2, 3, 'Related');

-- Insert into consultation_diagnostic
INSERT INTO consultation_diagnostic VALUES('876543212', '2019-06-20 15:00:00', 1);
INSERT INTO consultation_diagnostic VALUES('876543213', '2019-06-10 11:00:00', 2);
INSERT INTO consultation_diagnostic VALUES('983654320', '2022-11-01 14:00:00', 3);

INSERT INTO consultation_diagnostic VALUES('987654320', '2023-01-10 10:00:00', 1);
INSERT INTO consultation_diagnostic VALUES('987654320', '2023-01-11 11:00:00', 4);

INSERT INTO consultation_diagnostic VALUES('987654320', '2023-01-12 09:30:00', 1);
INSERT INTO consultation_diagnostic VALUES('987654320', '2023-01-12 12:00:00', 2);
INSERT INTO consultation_diagnostic VALUES('987654320', '2023-01-15 10:00:00', 2);
INSERT INTO consultation_diagnostic VALUES('876543212', '2023-01-20 14:30:00', 1); 
INSERT INTO consultation_diagnostic VALUES('876543213', '2023-01-21 16:00:00', 2);
INSERT INTO consultation_diagnostic VALUES('987654320', '2019-11-08 15:00:00', 5);
INSERT INTO consultation_diagnostic VALUES('987654320', '2019-11-10 15:00:00', 5);
INSERT INTO consultation_diagnostic VALUES('987654320', '2019-11-20 15:00:00', 5);

-- Insert into medication
INSERT INTO medication VALUES('Amoxicillin', 'MedLab');
INSERT INTO medication VALUES('Ibuprofen', 'PainAwayLab');
INSERT INTO medication VALUES('Paracetamol', 'FeverGoneLab');
INSERT INTO medication VALUES('Mouthwash', 'OralHealthLab');
INSERT INTO medication VALUES('CavityMed', 'CavityLab');
INSERT INTO medication VALUES('GeneralAntibiotic', 'GeneralLab');

-- Insert into prescription
INSERT INTO prescription VALUES('876543212', '2019-06-20 15:00:00', 1, 'CavityMed', 'CavityLab', '1 pill', 'Daily for cavity treatment');
INSERT INTO prescription VALUES('876543213', '2019-06-10 11:00:00', 2, 'GeneralAntibiotic', 'GeneralLab', '1 pill', 'Daily for infection treatment');
INSERT INTO prescription VALUES('983654320', '2022-11-01 14:00:00', 3, 'Paracetamol', 'FeverGoneLab', '500mg', 'Take one tablet every 8 hours');
INSERT INTO prescription VALUES('987654320', '2023-01-10 10:00:00', 1, 'Amoxicillin', 'MedLab', '500mg', 'Take twice daily');
INSERT INTO prescription VALUES('987654320', '2023-01-11 11:00:00', 4, 'Ibuprofen', 'PainAwayLab', '400mg', 'Take one tablet every 6 hours');
INSERT INTO prescription VALUES('987654320', '2023-01-12 09:30:00', 1, 'Amoxicillin', 'MedLab', '500mg', 'Take three times a day');
INSERT INTO prescription VALUES('987654320', '2023-01-12 12:00:00', 2, 'Mouthwash', 'OralHealthLab', 'Use twice daily', 'For oral hygiene');
INSERT INTO prescription VALUES('987654320', '2023-01-15 10:00:00', 2, 'Mouthwash', 'OralHealthLab', 'Use twice daily', 'For oral hygiene');
INSERT INTO prescription VALUES('876543212', '2023-01-20 14:30:00', 1, 'CavityMed', 'CavityLab', '1 pill', 'Daily for cavity treatment');
INSERT INTO prescription VALUES('876543213', '2023-01-21 16:00:00', 2, 'GeneralAntibiotic', 'GeneralLab', '1 pill', 'Daily for infection treatment');


-- Insert into procedure_
INSERT INTO procedure_ VALUES('Tooth Filling', 'Restorative');
INSERT INTO procedure_ VALUES('Dental X-Ray', 'Diagnostic');
INSERT INTO procedure_ VALUES ('Gum Measurement', 'Diagnostic');


-- Insert into procedure_in_consultation
INSERT INTO procedure_in_consultation VALUES('Tooth Filling', '987654320', '2023-01-10 10:00:00', 'Filling of molar tooth');
INSERT INTO procedure_in_consultation VALUES('Dental X-Ray', '987654320', '2023-01-10 10:00:00', 'Dental X-ray imaging');
INSERT INTO Procedure_in_consultation VALUES ('Gum Measurement', '987654320', '2019-11-08 15:00:00', 'Gum measurement for tooth 3 in the Lower Left quadrant');
INSERT INTO Procedure_in_consultation VALUES ('Gum Measurement', '987654320', '2019-11-10 15:00:00', 'Gum measurement for tooth 1 in the Upper Right quadrant');
INSERT INTO Procedure_in_consultation VALUES ('Gum Measurement', '987654320', '2019-11-20 15:00:00', 'Gum measurement for tooth 2 in the Lower Right quadrant');

-- Insert into teeth
INSERT INTO teeth VALUES('Upper Right', '2', 'Second Molar');
INSERT INTO teeth VALUES ('Lower Left', '3', 'Third Molar');
INSERT INTO teeth VALUES ('Upper Right', '1', 'First Molar');
INSERT INTO teeth VALUES('Lower Right', '2', 'Second Molar');


-- Insert into procedure_charting
INSERT INTO procedure_charting VALUES('Tooth Filling', '987654320', '2023-01-10 10:00:00', 'Upper Right', '2', 'Filling completed', 2.0);
INSERT INTO procedure_charting VALUES('Gum Measurement', '987654320', '2019-11-08 15:00:00', 'Lower Left', '3', 'Mild gum recession', 4.2);
INSERT INTO procedure_charting VALUES('Gum Measurement', '987654320', '2019-11-10 15:00:00', 'Upper Right', '1', 'Signs of gum inflammation', 4.1);
INSERT INTO procedure_charting VALUES('Gum Measurement', '987654320', '2019-11-20 15:00:00', 'Lower Right', '2', 'Early signs of gingival recession', 4.3);

-- Insert into procedure_imaging
INSERT INTO procedure_imaging VALUES('Dental X-Ray', '987654320', '2023-01-10 10:00:00', '/path/to/dental_xray.png');

