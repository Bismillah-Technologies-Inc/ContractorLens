#!/bin/bash
# ContractorLens Gemini CLI Launcher
# Orchestrates development using Gemini CLI with Pydantic models

set -e

PROJECT_ROOT="/Users/mirzakhan/Projects/ContractorLens"
GEMINI_DIR="$PROJECT_ROOT/.gemini"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 ContractorLens Gemini CLI Orchestrator${NC}"
echo "================================================"

# Check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    # Check if Gemini CLI is installed
    if ! command -v gemini &> /dev/null; then
        echo -e "${RED}❌ Gemini CLI not found${NC}"
        echo "Install from: https://github.com/google-gemini/gemini-cli"
        exit 1
    fi
    
    # Check if Python 3 is installed
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}❌ Python 3 not found${NC}"
        exit 1
    fi
    
    # Check if Pydantic is installed
    python3 -c "import pydantic" 2>/dev/null || {
        echo -e "${YELLOW}Installing Pydantic...${NC}"
        pip3 install pydantic
    }
    
    echo -e "${GREEN}✅ All prerequisites met${NC}"
}

# Analyze current progress
analyze_progress() {
    echo ""
    echo "Analyzing current progress..."
    
    # Check what's complete
    if [ -f "$PROJECT_ROOT/database/schemas/schema.sql" ]; then
        echo -e "${GREEN}✅ Database schema (DB001) - COMPLETE${NC}"
    fi
    
    if [ -f "$PROJECT_ROOT/ml-services/gemini-service/analyzer.js" ]; then
        echo -e "${GREEN}✅ Gemini ML service (ML001) - COMPLETE${NC}"
    fi
    
    if [ -f "$PROJECT_ROOT/backend/src/services/assemblyEngine.js" ]; then
        echo -e "${YELLOW}🔄 Assembly Engine (BE001) - IN PROGRESS${NC}"
    else
        echo -e "${RED}❌ Assembly Engine (BE001) - NOT STARTED${NC}"
    fi
    
    if [ -f "$PROJECT_ROOT/ios-app/ContractorLens/AR/RoomScanner.swift" ]; then
        echo -e "${YELLOW}🔄 iOS AR Scanner (IOS002) - IN PROGRESS${NC}"
    else
        echo -e "${RED}❌ iOS AR Scanner (IOS002) - NOT STARTED${NC}"
    fi
}

# Run specific workflow
run_workflow() {
    local workflow=$1
    echo ""
    echo -e "${YELLOW}Running workflow: $workflow${NC}"
    
    case $workflow in
        "assembly-engine")
            echo "Completing Assembly Engine implementation..."
            gemini chat \
                --config "$GEMINI_DIR/config.yaml" \
                --workflow complete_assembly_engine \
                --execute
            ;;
        "ios-scanning")
            echo "Implementing iOS AR scanning..."
            gemini chat \
                --config "$GEMINI_DIR/config.yaml" \
                --workflow implement_ar_scanning \
                --execute
            ;;
        "integration")
            echo "Creating integration tests..."
            gemini chat \
                --config "$GEMINI_DIR/config.yaml" \
                --workflow integration_testing \
                --execute
            ;;
        "orchestrate")
            echo "Running full Pydantic orchestration..."
            python3 "$PROJECT_ROOT/gemini_orchestrator.py"
            ;;
        *)
            echo -e "${RED}Unknown workflow: $workflow${NC}"
            echo "Available workflows:"
            echo "  - assembly-engine: Complete the Assembly Engine"
            echo "  - ios-scanning: Implement AR scanning"
            echo "  - integration: Create integration tests"
            echo "  - orchestrate: Run full orchestration"
            ;;
    esac
}

# Monitor progress
monitor_progress() {
    echo ""
    echo "Monitoring progress..."
    
    if [ -f "$GEMINI_DIR/progress.json" ]; then
        echo "Current task progress:"
        python3 -c "
import json
from pathlib import Path

progress = json.loads(Path('$GEMINI_DIR/progress.json').read_text())
for task_id, info in progress.items():
    status = info.get('status', 'unknown')
    percentage = info.get('percentage', 0)
    print(f'  {task_id}: {status} ({percentage}%)')
"
    else
        echo "No progress file found yet"
    fi
}

# Main menu
show_menu() {
    echo ""
    echo "What would you like to do?"
    echo "1) Check prerequisites"
    echo "2) Analyze current progress"
    echo "3) Complete Assembly Engine (BE002, BE003)"
    echo "4) Implement iOS AR Scanner (IOS003)"
    echo "5) Create Integration Tests (INT001)"
    echo "6) Run full orchestration (all tasks)"
    echo "7) Monitor progress"
    echo "8) Exit"
    echo ""
    read -p "Enter choice [1-8]: " choice
    
    case $choice in
        1) check_prerequisites ;;
        2) analyze_progress ;;
        3) run_workflow "assembly-engine" ;;
        4) run_workflow "ios-scanning" ;;
        5) run_workflow "integration" ;;
        6) run_workflow "orchestrate" ;;
        7) monitor_progress ;;
        8) exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
}

# Main execution
main() {
    # Make scripts executable
    chmod +x "$GEMINI_DIR/gemini_cli_wrapper.sh" 2>/dev/null || true
    chmod +x "$GEMINI_DIR/handlers/save_code.py" 2>/dev/null || true
    
    # Check if running with arguments
    if [ $# -gt 0 ]; then
        case "$1" in
            "check") check_prerequisites ;;
            "analyze") analyze_progress ;;
            "run") run_workflow "$2" ;;
            "monitor") monitor_progress ;;
            "orchestrate") run_workflow "orchestrate" ;;
            *) echo "Usage: $0 [check|analyze|run <workflow>|monitor|orchestrate]" ;;
        esac
    else
        # Interactive mode
        while true; do
            show_menu
        done
    fi
}

# Run main
main "$@"
