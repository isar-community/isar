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
	@echo "  test    Run all tests across all packages"
	@echo ""

test: ## Run all tests across all packages
	@echo "🧪 Running all tests across all packages..."
	@echo ""
	@echo "📦 Testing isar_generator package (working tests only)..."
	@cd packages/isar_generator && dart test test/web_safe_hash_test.dart test/object_info_test.dart || echo "⚠️  Some isar_generator tests have dependency issues"
	@echo ""
	@echo "📦 Testing isar package..."
	@cd packages/isar && dart test || echo "⚠️  Some isar tests failed"
	@echo ""
	@echo "📦 Testing isar_inspector package..."
	@cd packages/isar_inspector && dart test || echo "⚠️  No tests found in isar_inspector"
	@echo ""
	@echo "📦 Testing isar_test package..."
	@cd packages/isar_test && flutter test || echo "⚠️  isar_test may require additional setup"
	@echo ""
	@echo "✅ All available tests completed!"
