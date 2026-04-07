#!/bin/bash
# Gemini CLI Wrapper for ContractorLens
# Integrates with Pydantic orchestration system

# Configuration
GEMINI_BIN="${GEMINI_BIN:-gemini}"
PROJECT_ROOT="/Users/mirzakhan/Projects/ContractorLens"
GEMINI_CONFIG="$PROJECT_ROOT/.gemini"

# Function to execute task with Gemini CLI
execute_task() {
    local task_id=$1
    local agent_role=$2
    local prompt_file=$3
    local output_dir=$4
    
    echo "🚀 Executing task $task_id with $agent_role"
    
    # Create context from existing code
    context=""
    case $agent_role in
        "backend-engineer")
            context="$PROJECT_ROOT/database/schemas/schema.sql $PROJECT_ROOT/backend/src/services/assemblyEngine.js"
            ;;
        "ios-developer")
            context="$PROJECT_ROOT/scanning-user-flow-explanation"
            ;;
        "integration-engineer")
            context="$PROJECT_ROOT/backend $PROJECT_ROOT/ml-services/gemini-service"
            ;;
    esac
    
    # Execute with Gemini CLI
    $GEMINI_BIN chat \
        --system-prompt "You are a $agent_role for ContractorLens. Generate production-ready code." \
        --context-files $context \
        --prompt "$(cat $prompt_file)" \
        --output-handler "$GEMINI_CONFIG/handlers/save_code.py" \
        --output-dir "$output_dir" \
        --validate
        
    return $?
}

# Function to check task completion
check_completion() {
    local task_id=$1
    local deliverables=$2
    
    for file in $deliverables; do
        if [ ! -f "$PROJECT_ROOT/$file" ]; then
            echo "❌ Missing deliverable: $file"
            return 1
        fi
    done
    
    echo "✅ All deliverables created for $task_id"
    return 0
}

# Function to update progress
update_progress() {
    local task_id=$1
    local status=$2
    local percentage=$3
    
    python3 -c "
import json
from pathlib import Path

progress_file = Path('$GEMINI_CONFIG/progress.json')
if progress_file.exists():
    progress = json.loads(progress_file.read_text())
else:
    progress = {}

progress['$task_id'] = {
    'status': '$status',
    'percentage': $percentage,
    'timestamp': '$(date -Iseconds)'
}

progress_file.write_text(json.dumps(progress, indent=2))
"
}

# Main execution based on command
case "$1" in
    "execute")
        execute_task "$2" "$3" "$4" "$5"
        ;;
    "check")
        check_completion "$2" "$3"
        ;;
    "update")
        update_progress "$2" "$3" "$4"
        ;;
    "orchestrate")
        # Run the Pydantic orchestrator
        python3 "$PROJECT_ROOT/gemini_orchestrator.py"
        ;;
    *)
        echo "Usage: $0 {execute|check|update|orchestrate} [args...]"
        exit 1
        ;;
esac
