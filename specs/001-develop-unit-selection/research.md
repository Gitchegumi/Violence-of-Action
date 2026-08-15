# Phase 0 Research: Testing and Logging

This document outlines the research and decisions made to resolve the `NEEDS CLARIFICATION` markers identified in the `plan.md` file, specifically regarding testing and logging frameworks for the project.

## 1. Testing Framework

### Research Task
"Research a suitable testing framework for Godot 4.x GDScript projects."

### Findings
The two most prominent and well-regarded unit testing frameworks for Godot 4 are **GUT (Godot Unit Test)** and **GdUnit4**.

*   **GUT**: Praised for its ease of use, clear documentation, and simple installation directly from the Godot Asset Library. It provides a comprehensive set of assertions and supports running tests from the command line, which is crucial for future CI/CD integration.
*   **GdUnit4**: Also a very powerful framework with strong support for TDD workflows, scene testing, and mocking. It has a slightly steeper learning curve but offers very advanced features.

### Decision
**GUT (Godot Unit Test)** is selected as the official testing framework for this project.

### Rationale
As the project currently has no testing infrastructure (per issue #28), starting with the framework that is easier to install and learn is the most pragmatic choice. GUT's direct availability from the Asset Library and strong community support will allow for a faster ramp-up time. It provides all the necessary features for writing unit and integration tests for the 'Develop Unit Selection Logic' feature and future development.

### Alternatives Considered
- **GdUnit4**: Rejected for now in favor of a simpler initial setup. It can be reconsidered in the future if the project's testing needs become more complex.
- **Manual Testing**: Rejected as it does not align with the constitutional principle of automated testing and is not scalable.

---

## 2. Logging Approach

### Research Task
"Research basic logging best practices for Godot 4.x."

### Findings
Simple `print()` statements are insufficient for robust debugging as they lack context and cannot be filtered. Godot's built-in `push_warning()` and `push_error()` methods are better as they provide stack traces. However, for a scalable project, a centralized logging system is the recommended best practice. This typically involves a singleton (Autoload) script that manages log levels (e.g., DEBUG, INFO, ERROR) and can write logs to an external file, which is invaluable for debugging release builds.

### Decision
A custom, lightweight logging singleton named `Logger.gd` will be implemented.

### Rationale
Creating a custom logger provides the exact level of control needed without adding the overhead of a large, external plugin. This approach is a common and recommended pattern in the Godot community. The `Logger.gd` singleton will be responsible for:
1.  Providing static methods for logging at different levels (e.g., `Logger.info("message")`, `Logger.error("message")`).
2.  Writing log output to a file in the `user://` directory for persistence.
3.  Allowing log levels to be configured to show more or less detail as needed.

This approach resolves the ambiguity around logging and provides a clear path forward for implementing observability in the project.

### Alternatives Considered
- **Using only `print()`**: Rejected as it is not a scalable or robust solution.
- **Using a pre-existing logging plugin**: Rejected for now to maintain simplicity. A custom solution is simple enough to create and will be perfectly tailored to the project's needs.
