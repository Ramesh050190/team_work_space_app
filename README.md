# Flutter Task Management App

Team Workspace is a Flutter task management application built to demonstrate how a real-world mobile application can be structured using Clean Architecture. The project focuses on writing clean, maintainable code while supporting features like offline access, authentication, localization, and scalable state management.

The application allows authenticated users to create, update, organize, and track tasks even when the device is offline. Changes made without an internet connection are stored locally and synchronized automatically once connectivity is restored.

Rather than being a simple CRUD application, the project is designed around production-ready practices such as feature-based organization, dependency injection, repository pattern, offline-first data handling, automated testing, and continuous integration.

## Features

### Authentication

* Sign up and log in using Firebase Authentication
* Automatic session persistence
* Logout from the profile screen
* Input validation with localized error messages

### Task Management

* Browse tasks with pagination
* Create new tasks
* Edit existing tasks
* View detailed task information
* Mark tasks as completed or reopen them
* Search tasks by title
* Filter tasks by status and priority
* Pull-to-refresh and infinite scrolling

> Task deletion has been planned as part of the offline synchronization workflow but is not yet exposed through the UI.

### Offline Support

The application follows an offline-first approach.

Task data is cached locally using Hive so users can continue working without an internet connection. Any changes made while offline are applied immediately in the UI and stored as pending operations. Once connectivity returns, these operations are synchronized with the server in the order they were created.

To handle conflicts, the application uses a simple last-modified-wins strategy based on the latest timestamp.

### Preferences

Users can customize the application by choosing:

* Light, Dark, or System theme
* English or Hindi language

All preferences are stored locally and restored automatically on startup.

## Technology Stack

* Flutter & Dart
* flutter_bloc
* GetIt
* Dio
* Firebase Authentication
* Hive
* GoRouter
* connectivity_plus
* dartz
* flutter_localizations
* bloc_test & mocktail

## Architecture

The project follows Clean Architecture with a feature-first folder structure.

Presentation is responsible for the UI and state management.

Domain contains business logic, entities, and use cases.

Data handles communication with remote APIs, local storage, and repository implementations.

This separation keeps each layer independent, easier to test, and easier to maintain as the application grows.
