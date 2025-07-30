
-- Create the Departments table
CREATE TABLE Departments (
    DepartmentID INT PRIMARY KEY IDENTITY(1,1),
    DepartmentName VARCHAR(50)
);

-- Create the Students table
CREATE TABLE Students (
    StudentID INT PRIMARY KEY IDENTITY(1,1),
    StudentName VARCHAR(50),
    Age INT,
    PhoneNumber VARCHAR(20),
    DepartmentID INT FOREIGN KEY REFERENCES Departments(DepartmentID)
);

-- Create BankAccounts for Transactions
CREATE TABLE BankAccounts (
    AccountID INT PRIMARY KEY IDENTITY(1,1),
    AccountHolder VARCHAR(50),
    Balance DECIMAL(10,2)
);

-- Insert Departments
INSERT INTO Departments (DepartmentName) VALUES 
('Computer Science'),
('Information Technology'),
('Business Administration'),
('Electrical Engineering');

-- Insert Students
INSERT INTO Students (StudentName, Age, PhoneNumber, DepartmentID) VALUES 
('Ali Akbar', 22, '03001234567', 1),
('Muhammad Hasnain', 24, '03011234567', 1),
('Areeb Haider', 23, '03021234567', 2),
('Areeb Khan', 25, '03031234567', 2),
('Mustufa Rashid', 21, '03041234567', 2),
('Owais', 19, '03051234567', 3),
('Uzair', 27, '03061234567', 3),
('Hamza', 20, '03071234567', 3),
('Zain', 28, '03081234567', 4),
('Farzan', 26, '03091234567', 1);

-- Bank Accounts
INSERT INTO BankAccounts (AccountHolder, Balance) VALUES
('Ali Akbar', 1000),
('Muhammad Hasnain', 2000);

-- Subqueries
SELECT StudentName, Age FROM Students WHERE Age > (SELECT AVG(Age) FROM Students);
SELECT DepartmentID FROM Students GROUP BY DepartmentID HAVING COUNT(StudentID) > 5;
SELECT StudentName, Age FROM Students WHERE Age = (SELECT MAX(Age) FROM Students);

-- Views
CREATE VIEW v_StudentDetails AS SELECT StudentName, Age FROM Students;
CREATE VIEW v_StudentsOver21 AS SELECT * FROM Students WHERE Age > 21;
ALTER VIEW v_StudentDetails AS SELECT StudentName, Age, PhoneNumber FROM Students;

-- Stored Procedures
CREATE PROCEDURE sp_InsertStudent
    @StudentName VARCHAR(50),
    @Age INT,
    @PhoneNumber VARCHAR(20),
    @DepartmentID INT
AS BEGIN
    INSERT INTO Students (StudentName, Age, PhoneNumber, DepartmentID)
    VALUES (@StudentName, @Age, @PhoneNumber, @DepartmentID);
END;

CREATE PROCEDURE sp_GetStudentsByDepartment
    @DeptID INT
AS BEGIN
    SELECT * FROM Students WHERE DepartmentID = @DeptID;
END;

CREATE PROCEDURE sp_UpdateStudentAge
    @StudentID INT,
    @NewAge INT
AS BEGIN
    UPDATE Students SET Age = @NewAge WHERE StudentID = @StudentID;
END;

-- Transactions
BEGIN TRANSACTION;
    UPDATE BankAccounts SET Balance = Balance - 500 WHERE AccountID = 1;
    UPDATE BankAccounts SET Balance = Balance + 500 WHERE AccountID = 2;
IF @@ERROR <> 0 ROLLBACK; ELSE COMMIT;

CREATE TABLE StudentLogs (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    StudentID INT,
    LogMessage VARCHAR(100),
    LogTime DATETIME DEFAULT GETDATE()
);

BEGIN TRANSACTION;
    INSERT INTO Students (StudentName, Age, PhoneNumber, DepartmentID)
    VALUES ('Test Student', 20, '03121234567', 1);
    DECLARE @NewStudentID INT = SCOPE_IDENTITY();
    BEGIN TRY
        INSERT INTO StudentLogs (StudentID, LogMessage)
        VALUES (@NewStudentID, 'Student inserted');
        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
    END CATCH;

-- T-SQL WHILE Loop
DECLARE @i INT = 1;
DECLARE @count INT = (SELECT COUNT(*) FROM Students);
WHILE @i <= @count
BEGIN
    DECLARE @name VARCHAR(50) = 
        (SELECT StudentName FROM (
            SELECT StudentName, ROW_NUMBER() OVER (ORDER BY StudentID) AS rn FROM Students
        ) AS Temp WHERE rn = @i);
    PRINT @name;
    SET @i = @i + 1;
END;

-- Triggers
CREATE TABLE DeletedStudents (
    StudentID INT,
    StudentName VARCHAR(50),
    DeletedAt DATETIME DEFAULT GETDATE()
);

CREATE TRIGGER trg_StudentDelete
ON Students
AFTER DELETE
AS BEGIN
    INSERT INTO DeletedStudents (StudentID, StudentName)
    SELECT StudentID, StudentName FROM deleted;
END;

CREATE TRIGGER trg_PreventUnderageInsert
ON Students
INSTEAD OF INSERT
AS BEGIN
    IF EXISTS (SELECT * FROM inserted WHERE Age < 16)
    BEGIN
        RAISERROR('Student must be at least 16 years old.', 16, 1);
        ROLLBACK;
    END
    ELSE
    BEGIN
        INSERT INTO Students (StudentName, Age, PhoneNumber, DepartmentID)
        SELECT StudentName, Age, PhoneNumber, DepartmentID FROM inserted;
    END
END;
