# Contributing to Sora Video Generator

Thank you for your interest in contributing to the Sora Video Generator! We welcome contributions from the community and are excited to see what you can bring to the project.

## 🤝 How to Contribute

### Reporting Issues

If you find a bug or have a feature request:

1. **Search existing issues** first to avoid duplicates
2. **Create a new issue** with a clear title and description
3. **Include relevant details**:
   - Steps to reproduce (for bugs)
   - Expected vs. actual behavior
   - Environment details (OS, Java version, etc.)
   - Screenshots or logs if applicable

### Development Setup

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/sora-video-generator.git
   cd sora-video-generator
   ```

3. **Set up development environment**:
   ```bash
   # Copy environment template
   cp .env.example .env
   # Edit .env with your Azure OpenAI credentials
   ```

4. **Install dependencies and run tests**:
   ```bash
   ./mvnw clean test
   ```

5. **Run the application locally**:
   ```bash
   ./mvnw spring-boot:run
   ```

### Making Changes

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following our coding standards (see below)

3. **Add or update tests** for your changes

4. **Run tests** to ensure everything works:
   ```bash
   ./mvnw clean test
   ```

5. **Test locally** with Docker:
   ```bash
   docker build -t sora-video-generator .
   docker run -p 8080:8080 sora-video-generator
   ```

6. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

7. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

8. **Create a Pull Request** on GitHub

## 📋 Coding Standards

### Java Code Style

- Follow standard Java naming conventions
- Use meaningful variable and method names
- Write self-documenting code with minimal comments
- Keep methods focused and under 50 lines when possible
- Use dependency injection properly with Spring

### Code Organization

- Place related functionality in appropriate packages
- Keep controllers thin - business logic belongs in services
- Use DTOs for API requests/responses
- Implement proper error handling and logging

### Documentation

- Update README.md for significant feature additions
- Add JavaDoc for public methods and classes
- Include inline comments for complex logic
- Update API documentation for new endpoints

### Testing

- Write unit tests for new functionality
- Maintain or improve test coverage
- Test error scenarios and edge cases
- Include integration tests for API endpoints

## 🔧 Technical Guidelines

### Dependencies

- Minimize external dependencies
- Use Spring Boot starters when possible
- Keep dependency versions up to date
- Justify any new dependencies in PR description

### Security

- Never commit API keys or sensitive data
- Use environment variables for configuration
- Follow Azure security best practices
- Validate all user inputs

### Performance

- Use reactive programming patterns where appropriate
- Implement proper caching strategies
- Monitor memory usage and optimize if needed
- Use async processing for long-running operations

## 🚀 Pull Request Process

1. **Ensure your PR**:
   - Has a clear title and description
   - References related issues
   - Includes tests for new functionality
   - Passes all existing tests
   - Follows coding standards

2. **PR Review Process**:
   - Maintainers will review your PR
   - Address any feedback or requested changes
   - Keep your branch up to date with main
   - Be responsive to questions and suggestions

3. **Merge Requirements**:
   - All tests must pass
   - Code review approval required
   - No merge conflicts
   - Documentation updated if needed

## 🌟 Types of Contributions

We welcome various types of contributions:

### 🐛 Bug Fixes
- Fix existing functionality
- Improve error handling
- Resolve performance issues

### ✨ New Features
- Video generation enhancements
- New API endpoints
- UI/UX improvements
- Integration with other Azure services

### 📚 Documentation
- README improvements
- Code comments and JavaDoc
- API documentation
- Troubleshooting guides

### 🧪 Testing
- Unit test improvements
- Integration tests
- Load testing
- Security testing

### 🔧 Infrastructure
- Docker improvements
- Azure Bicep enhancements
- CI/CD pipeline improvements
- Monitoring and logging

## 📖 Resources

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Azure OpenAI Documentation](https://docs.microsoft.com/azure/cognitive-services/openai/)
- [Azure Container Apps Documentation](https://docs.microsoft.com/azure/container-apps/)
- [Project Issues](https://github.com/YOUR_USERNAME/sora-video-generator/issues)

## 💬 Getting Help

If you need help with contributing:

1. Check existing documentation
2. Search closed issues for similar questions
3. Create a new issue with the "question" label
4. Join community discussions

## 🎉 Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes for significant contributions
- GitHub contributor statistics

Thank you for helping make Sora Video Generator better! 🚀
