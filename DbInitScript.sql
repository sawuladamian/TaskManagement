CREATE DATABASE TaskManagement
GO;

USE [TaskManagement]
GO
/****** Object:  Table [dbo].[Comments]    Script Date: 26.06.2023 19:55:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Comments](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Content] [nvarchar](1000) NOT NULL,
	[TaskId] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Tasks]    Script Date: 26.06.2023 19:55:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tasks](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Description] [nvarchar](500) NOT NULL,
	[DueDate] [datetime] NOT NULL,
	[Priority] [int] NOT NULL,
	[UserId] [int] NOT NULL,
	[IsComplete] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Users]    Script Date: 26.06.2023 19:55:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Users](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
	[Email] [nvarchar](100) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Tasks] ADD  DEFAULT ((0)) FOR [IsComplete]
GO
ALTER TABLE [dbo].[Comments]  WITH CHECK ADD FOREIGN KEY([TaskId])
REFERENCES [dbo].[Tasks] ([Id])
GO
ALTER TABLE [dbo].[Tasks]  WITH CHECK ADD FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
/****** Object:  StoredProcedure [dbo].[sp_CompleteTask]    Script Date: 26.06.2023 19:55:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE [dbo].[sp_CompleteTask]
@taskId int, @returnJsonDocument nvarchar(MAX) OUTPUT
AS
BEGIN

	IF EXISTS(SELECT 1 FROM Tasks where Tasks.Id = @taskId)
		BEGIN
			UPDATE Tasks SET IsComplete = 1 WHERE Id = @taskId
		END
		ELSE
		BEGIN
		THROW 100404,'Task does not exist.',1;
		END   

    SET @returnJsonDocument = (SELECT * FROM Tasks where Id = @taskId FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER)
	
	 
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_CreateComment]    Script Date: 26.06.2023 19:55:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[sp_CreateComment]
    @json NVARCHAR(MAX), @returnJsonDocument nvarchar(MAX) OUTPUT
AS
BEGIN
    DECLARE @taskId int,
            @content NVARCHAR(1000)
            
    SELECT @taskId = JSON_VALUE(@json, '$.taskId'),
           @content = JSON_VALUE(@json, '$.content')
               FROM OPENJSON(@json);

    INSERT INTO Comments (TaskId,Content)
    VALUES (@taskId,@content);

    SET @returnJsonDocument = (SELECT Id, Content, TaskId
    FROM Comments
    WHERE Id = SCOPE_IDENTITY()
    FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER)
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_CreateTask]    Script Date: 26.06.2023 19:55:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_CreateTask]
    @json NVARCHAR(MAX), @returnJsonDocument nvarchar(MAX) OUTPUT
AS
BEGIN
    DECLARE @taskDescription NVARCHAR(500),
            @dueDate DATETIME,
            @priority int,
            @userId INT,
			@isComplete bit;

    SELECT @taskDescription = JSON_VALUE(@json, '$.description'),
           @dueDate = JSON_VALUE(@json, '$.dueDate'),
           @priority = JSON_VALUE(@json, '$.priority'),
           @userId = JSON_VALUE(@json, '$.userId'),
		   @isComplete = JSON_VALUE(@json, '$.isComplete')
    FROM OPENJSON(@json);

    INSERT INTO Tasks (Description, DueDate, Priority, UserId,IsComplete)
    VALUES (@taskDescription, @dueDate, @priority, @userId,@isComplete);

    SET @returnJsonDocument = (SELECT Id, Description, DueDate, Priority, UserId, IsComplete
    FROM Tasks
    WHERE Id = SCOPE_IDENTITY()
    FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER)
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_CreateUser]    Script Date: 26.06.2023 19:55:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_CreateUser]
    @json NVARCHAR(MAX), @returnJsonDocument nvarchar(MAX) OUTPUT
AS
BEGIN
    DECLARE @name NVARCHAR(100),
            @email NVARCHAR(100)
            
    SELECT @name = JSON_VALUE(@json, '$.name'),
           @email = JSON_VALUE(@json, '$.email')
               FROM OPENJSON(@json);

    INSERT INTO Users (Name,Email)
    VALUES (@name,@email);

    SET @returnJsonDocument = (SELECT Id, Name, Email
    FROM Users
    WHERE Id = SCOPE_IDENTITY()
    FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER)
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_DeleteTask]    Script Date: 26.06.2023 19:55:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_DeleteTask]
@taskId int, @returnJsonDocument nvarchar(MAX) OUTPUT
AS
BEGIN

	IF EXISTS(SELECT 1 FROM Tasks where Tasks.Id = @taskId)
		BEGIN
			IF EXISTS(SELECT 1 FROM Comments WHERE TaskId = @taskId)
			BEGIN
				DELETE FROM Comments WHERE TaskId = @taskId
			END

			DELETE FROM Tasks WHERE Id=@taskId
		END
		ELSE
		BEGIN
		THROW 100404,'Task does not exist.',1;
		END   

    SET @returnJsonDocument = CONCAT(N'{"taskId":',@taskId, '}');
	
	 
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_EditTask]    Script Date: 26.06.2023 19:55:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_EditTask]
    @taskId int, @json NVARCHAR(MAX), @returnJsonDocument nvarchar(MAX) OUTPUT
AS
BEGIN
    DECLARE @taskDescription NVARCHAR(500),
            @dueDate DATETIME,
            @priority int,
            @userId INT,
			@isComplete bit;

    SELECT @taskDescription = JSON_VALUE(@json, '$.description'),
           @dueDate = JSON_VALUE(@json, '$.dueDate'),
           @priority = JSON_VALUE(@json, '$.priority'),
           @userId = JSON_VALUE(@json, '$.userId'),
		   @isComplete = JSON_VALUE(@json, '$.isComplete')
    FROM OPENJSON(@json);

	IF EXISTS(SELECT 1 FROM Tasks where Tasks.Id = @taskId)
		BEGIN
			UPDATE Tasks 
			SET Description = @taskDescription,
			DueDate = @dueDate,
			Priority = @priority,
			UserId = @userId,
			isComplete = @isComplete WHERE Tasks.Id = @taskId
		END
		ELSE
		BEGIN

		THROW 100404,'Task does not exist.',1;
		END   

    SET @returnJsonDocument = (SELECT Id, Description, DueDate, Priority, UserId, IsComplete
    FROM Tasks
    WHERE Id =@taskId
    FOR JSON AUTO, WITHOUT_ARRAY_WRAPPER)
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_GetComments]    Script Date: 26.06.2023 19:55:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_GetComments]
@taskId int, @returnJsonDocument nvarchar(MAX) OUTPUT
AS
BEGIN

	IF EXISTS(SELECT 1 FROM Comments WHERE TaskId=@taskId)
	BEGIN
    SET @returnJsonDocument = (SELECT * FROM Comments WHERE TaskId=@taskId FOR JSON AUTO)
	END
	ELSE
	BEGIN

	SET @returnJsonDocument = 'Task does not exist.'
	END
	 
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_GetTask]    Script Date: 26.06.2023 19:55:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_GetTask]
@taskId int, @returnJsonDocument nvarchar(MAX) OUTPUT
AS
BEGIN

	IF EXISTS(SELECT 1 FROM Tasks WHERE Id=@taskId)
	BEGIN
		IF EXISTS(SELECT 1 FROM Comments WHERE TaskId = @taskId)
		BEGIN
		SET @returnJsonDocument = (SELECT * FROM Tasks
		INNER JOIN Comments ON Comments.TaskId = Tasks.Id
		WHERE Tasks.Id=@taskId FOR JSON AUTO,WITHOUT_ARRAY_WRAPPER)
		END

		ELSE
		BEGIN
			SET @returnJsonDocument = (SELECT * FROM Tasks
			
			WHERE Tasks.Id=@taskId FOR JSON AUTO,WITHOUT_ARRAY_WRAPPER)
		END
	END
	ELSE
	BEGIN
	SET @returnJsonDocument = 'Task does not exist.'
	END
	 
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_GetTasks]    Script Date: 26.06.2023 19:55:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_GetTasks]
@returnJsonDocument nvarchar(MAX) OUTPUT
AS
BEGIN

	
    SET @returnJsonDocument = (SELECT * FROM Tasks FOR JSON AUTO)
	
	 
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_GetUserTasks]    Script Date: 26.06.2023 19:55:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_GetUserTasks]
@userId int, @returnJsonDocument nvarchar(MAX) OUTPUT
AS
BEGIN

	
    SET @returnJsonDocument = (SELECT Tasks.Id,Description,DueDate,Priority,IsComplete FROM Tasks
	INNER JOIN Users ON UserId= Users.Id
	WHERE UserId=@userId FOR JSON AUTO)
	
	 
END;

GO
