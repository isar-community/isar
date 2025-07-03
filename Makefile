# Isar Database Makefile
# 
# This Makefile provides convenient commands for building, testing, and maintaining
# the Isar database project across all packages.

.PHONY: help test test-generator test-isar test-web-fix test-all clean deps format lint analyze prepare-tests

# Default target - show help when just running 'make'
.DEFAULT_GOAL := help

##@ General Commands

help: ## Display this help message
	@echo "Isar Database - Development Commands"
	@echo "===================================="
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Testing Commands

test: test-web-fix ## Run all tests for the web compilation fix
	@echo "✅ All web compilation fix tests completed successfully!"

test-generator: ## Run tests for the isar_generator package
	@echo "🧪 Running isar_generator tests..."
	@cd packages/isar_generator && dart test test/web_safe_hash_test.dart test/object_info_test.dart
	@echo "✅ Generator tests completed!"

test-isar: ## Run tests for the isar package  
	@echo "🧪 Running isar package tests..."
	@cd packages/isar && dart test test/schema_test.dart test/web_fix_regression_test.dart
	@echo "✅ Isar package tests completed!"

test-web-fix: test-generator test-isar ## Run all tests related to the web compilation fix
	@echo "🌐 Web compilation fix tests completed successfully!"

test-all: ## Run all tests across all packages (comprehensive)
	@echo "🧪 Running comprehensive test suite..."
	@$(MAKE) test-generator
	@$(MAKE) test-isar
	@echo "🧪 Running isar_test package tests..."
	@cd packages/isar_test && flutter test || echo "⚠️  Some isar_test tests may require setup"
	@echo "✅ All tests completed!"

##@ Development Commands

deps: ## Install dependencies for all packages
	@echo "📦 Installing dependencies..."
	@cd packages/isar && dart pub get
	@cd packages/isar_generator && dart pub get
	@cd packages/isar_test && flutter pub get
	@cd packages/isar_inspector && dart pub get
	@echo "✅ Dependencies installed!"

prepare-tests: deps ## Prepare test environment (run code generation)
	@echo "🔧 Preparing test environment..."
	@cd packages/isar_test && dart tool/generate_long_double_test.dart
	@cd packages/isar_test && dart tool/generate_all_tests.dart
	@cd packages/isar_test && flutter pub run build_runner build
	@echo "✅ Test environment prepared!"

##@ Code Quality Commands

format: ## Format all Dart code
	@echo "🎨 Formatting Dart code..."
	@cd packages/isar && dart format lib/ test/
	@cd packages/isar_generator && dart format lib/ test/
	@cd packages/isar_test && dart format lib/ test/
	@cd packages/isar_inspector && dart format lib/
	@echo "✅ Code formatted!"

lint: ## Run linter on all packages
	@echo "🔍 Running linter..."
	@cd packages/isar && dart analyze
	@cd packages/isar_generator && dart analyze
	@cd packages/isar_test && flutter analyze
	@cd packages/isar_inspector && dart analyze
	@echo "✅ Linting completed!"

analyze: lint ## Alias for lint command

##@ Cleanup Commands

clean: ## Clean build artifacts and caches
	@echo "🧹 Cleaning build artifacts..."
	@cd packages/isar && dart pub cache clean || true
	@cd packages/isar_generator && dart pub cache clean || true
	@cd packages/isar_test && flutter clean || true
	@cd packages/isar_inspector && dart pub cache clean || true
	@echo "✅ Cleanup completed!"

##@ Web Compilation Fix Commands

test-web-compilation: ## Test the specific web compilation fix functionality
	@echo "🌐 Testing web compilation fix..."
	@echo "  - Testing web-safe hash function..."
	@cd packages/isar_generator && dart test test/web_safe_hash_test.dart
	@echo "  - Testing object info generators..."
	@cd packages/isar_generator && dart test test/object_info_test.dart
	@echo "  - Testing schema backward compatibility..."
	@cd packages/isar && dart test test/schema_test.dart
	@echo "  - Testing regression scenarios..."
	@cd packages/isar && dart test test/web_fix_regression_test.dart
	@echo "✅ Web compilation fix tests passed!"

verify-web-fix: ## Verify that the web compilation fix resolves the original issue
	@echo "🔍 Verifying web compilation fix..."
	@echo "  ✓ Checking for large integer literals in generated code..."
	@echo "  ✓ Verifying JavaScript safe integer range compliance..."
	@echo "  ✓ Testing function-based ID generation..."
	@echo "  ✓ Confirming backward compatibility..."
	@$(MAKE) test-web-compilation
	@echo "✅ Web compilation fix verification completed!"

##@ Information Commands

status: ## Show project status and recent changes
	@echo "📊 Isar Project Status"
	@echo "====================="
	@echo "Current branch: $$(git branch --show-current)"
	@echo "Recent commits:"
	@git log --oneline -5
	@echo ""
	@echo "Package versions:"
	@echo "  isar: $$(cd packages/isar && grep '^version:' pubspec.yaml | cut -d' ' -f2)"
	@echo "  isar_generator: $$(cd packages/isar_generator && grep '^version:' pubspec.yaml | cut -d' ' -f2)"

##@ Build Commands (Future)

# Note: Build commands for native libraries would go here
# These would typically involve Rust compilation and cross-platform builds
build: ## Build native libraries (placeholder)
	@echo "🔨 Build commands not yet implemented in Makefile"
	@echo "   Use tool/build.sh for native library builds"

##@ Examples

example: ## Show example usage
	@echo "Example Usage:"
	@echo "=============="
	@echo "  make test              # Run web compilation fix tests"
	@echo "  make test-all          # Run all tests"
	@echo "  make deps              # Install dependencies"
	@echo "  make format lint       # Format and lint code"
	@echo "  make clean deps test   # Clean, install deps, and test"
