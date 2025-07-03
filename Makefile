# Isar Database Makefile
#
# Simple Makefile with test and help commands

.PHONY: help test

# Default target - show help when just running 'make'
.DEFAULT_GOAL := help

help: ## Display available commands
	@echo "Isar Database - Available Commands"
	@echo "=================================="
	@echo ""
	@echo "Usage:"
	@echo "  make <command>"
	@echo ""
	@echo "Commands:"
	@echo "  help    Display this help message"
	@echo "  test    Run tests for the web compilation fix"
	@echo ""

test: ## Run tests for the web compilation fix
	@echo "🧪 Running web compilation fix tests..."
	@echo ""
	@echo "📦 Testing isar_generator package..."
	@cd packages/isar_generator && dart test test/web_safe_hash_test.dart test/object_info_test.dart
	@echo ""
	@echo "📦 Testing isar package..."
	@cd packages/isar && dart test test/schema_test.dart test/web_fix_regression_test.dart
	@echo ""
	@echo "✅ All web compilation fix tests completed successfully!"
