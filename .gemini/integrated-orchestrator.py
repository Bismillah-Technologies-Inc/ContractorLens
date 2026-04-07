#!/usr/bin/env python3
"""
ContractorLens Integrated Orchestration System
Combines Pydantic task management with intelligent code analysis
Works with Gemini CLI configuration system
"""

import os
import ast
import json
import re
import subprocess
import asyncio
from pathlib import Path
from typing import Dict, List, Optional, Any, Set
from datetime import datetime
from pydantic import BaseModel, Field
from enum import Enum
import hashlib
import yaml

# ============================================================================ 
# PYDANTIC MODELS (from earlier system)
# ============================================================================ 

class TaskStatus(str, Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETE = "complete"
    BLOCKED = "blocked"
    DETECTED = "detected"  # New: for dynamically discovered tasks

class AgentRole(str, Enum):
    DATABASE = "database-engineer"
    BACKEND = "backend-engineer"
    IOS = "ios-developer"
    ML = "ml-engineer"
    INTEGRATION = "integration-engineer"
    GENERAL = "general"

class Task(BaseModel):
    """Task model with both predefined and dynamic support"""
    task_id: str
    title: str
    description: str
    agent: AgentRole
    status: TaskStatus = TaskStatus.PENDING
    priority: str = "medium"
    dependencies: List[str] = []
    deliverables: List[str] = []
    context_files: List[str] = []
    source: str = "manual"  # "manual", "detected", "todo"
    detected_in_file: Optional[str] = None

# ============================================================================ 
# CODE INTELLIGENCE (from smart orchestrator)
# ============================================================================ 

class CodeIntelligence(BaseModel):
    """Analyzes code to understand implementation state by parsing it"""
    project_root: Path = Path("/Users/mirzakhan/Projects/ContractorLens")

    def analyze_javascript_file(self, filepath: Path) -> Dict[str, Any]:
        """Parse JavaScript file to understand what's implemented"""
        content = filepath.read_text()
        analysis = {
            "classes": [],
            "functions": [],
            "exports": [],
            "imports": [],
            "todos": [],
            "unimplemented": []
        }
        class_pattern = r'class\s+(\w+)'
        analysis["classes"] = re.findall(class_pattern, content)
        func_patterns = [
            r'function\s+(\w+)\s*\(',
            r'const\s+(\w+)\s*=\s*(?:async\s+)?\(',
            r'(\w+)\s*:\s*(?:async\s+)?function'
        ]
        for pattern in func_patterns:
            analysis["functions"].extend(re.findall(pattern, content))
        export_pattern = r'(?:module\.)?exports\.([\w]+)|export\s+(?:default\s+)?([\w]+)'
        matches = re.findall(export_pattern, content)
        analysis["exports"] = [m[0] or m[1] for m in matches if m[0] or m[1]]
        todo_pattern = r'(?://|/\*)\s*(TODO|FIXME|HACK|XXX|NOTE):\s*(.+?)(?:\*/|\n)'
        analysis["todos"] = re.findall(todo_pattern, content, re.IGNORECASE)
        if 'throw new Error("Not implemented")' in content:
            analysis["unimplemented"].append("Has unimplemented methods")
        func_body_pattern = r'(function\s+\w+\s*\([^)]*\)\s*{[^}]{0,50}}|=>\s*{[^}]{0,50}})'
        short_funcs = re.findall(func_body_pattern, content)
        if short_funcs:
            analysis["unimplemented"].append(f"{len(short_funcs)} possible stub functions")
        return analysis

    def analyze_swift_file(self, filepath: Path) -> Dict[str, Any]:
        """Parse Swift file to understand what's implemented"""
        content = filepath.read_text()
        analysis = {
            "classes": [], "structs": [], "functions": [], "protocols": [],
            "todos": [], "unimplemented": []
        }
        analysis["classes"] = re.findall(r'class\s+(\w+)', content)
        analysis["structs"] = re.findall(r'struct\s+(\w+)', content)
        analysis["functions"] = re.findall(r'func\s+(\w+)\s*\(', content)
        analysis["protocols"] = re.findall(r'protocol\s+(\w+)', content)
        analysis["todos"] = re.findall(r'//\s*(TODO|FIXME):\s*(.+)', content, re.IGNORECASE)
        if 'fatalError("' in content or 'preconditionFailure' in content:
            analysis["unimplemented"].append("Has unimplemented methods")
        return analysis

    def analyze_sql_file(self, filepath: Path) -> Dict[str, Any]:
        """Parse SQL file to understand schema"""
        content = filepath.read_text()
        analysis = {
            "tables": [], "views": [], "functions": [], "indexes": [], "has_seed_data": False
        }
        table_pattern = r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(\w+)'
        analysis["tables"] = re.findall(table_pattern, content, re.IGNORECASE)
        view_pattern = r'CREATE\s+(?:OR\s+REPLACE\s+)?VIEW\s+(\w+)'
        analysis["views"] = re.findall(view_pattern, content, re.IGNORECASE)
        func_pattern = r'CREATE\s+(?:OR\s+REPLACE\s+)?FUNCTION\s+(\w+)'
        analysis["functions"] = re.findall(func_pattern, content, re.IGNORECASE)
        index_pattern = r'CREATE\s+(?:UNIQUE\s+)?INDEX\s+(\w+)'
        analysis["indexes"] = re.findall(index_pattern, content, re.IGNORECASE)
        if 'INSERT INTO' in content.upper():
            analysis["has_seed_data"] = True
        return analysis

    def find_missing_features(self) -> Dict[str, List[str]]:
        """Intelligently find what features are missing"""
        missing = {"backend": [], "ios": [], "database": [], "tests": []}
        
        # Backend checks
        backend_path = self.project_root / "backend"
        if backend_path.exists():
            assembly_file = backend_path / "src/services/assemblyEngine.js"
            if assembly_file.exists():
                analysis = self.analyze_javascript_file(assembly_file)
                required = {"calculateEstimate", "getLocalizedCost", "applyFinishLevels"}
                implemented = set(analysis["functions"])
                for method in required - implemented:
                    missing["backend"].append(f"Implement {method} in Assembly Engine")
            else:
                missing["backend"].append("Create Assembly Engine service")
        
        # iOS checks
        ios_path = self.project_root / "ios-app"
        if ios_path.exists():
            scanner_path = ios_path / "ContractorLens/AR/RoomScanner.swift"
            if scanner_path.exists():
                analysis = self.analyze_swift_file(scanner_path)
                if "startScanning" not in analysis["functions"]:
                    missing["ios"].append("Implement startScanning method")
            else:
                missing["ios"].append("Implement AR scanning with RoomPlan")

        return missing

    def discover_tasks(self) -> List[Task]:
        """Discover tasks from code analysis by converting missing features to Task objects."""
        tasks = []
        task_counter = 0
        missing_features = self.find_missing_features()
        for component, issues in missing_features.items():
            agent = self._get_agent_for_component(component)
            if not agent: continue
            for issue in issues:
                task_counter += 1
                tasks.append(Task(
                    task_id=f"DETECTED_{task_counter:03d}",
                    title=issue,
                    description=f"Address the following detected issue: {issue}",
                    agent=agent, status=TaskStatus.DETECTED,
                    priority="high", source="detected",
                ))
        return tasks

    def _get_agent_for_component(self, component: str) -> Optional[AgentRole]:
        """Map component to agent role"""
        mapping = {
            "backend": AgentRole.BACKEND, "database": AgentRole.DATABASE,
            "ios": AgentRole.IOS, "ml-services": AgentRole.ML,
            "ios-app": AgentRole.IOS,
        }
        return mapping.get(component.lower())

# ============================================================================ 
# GEMINI CLI INTEGRATION
# ============================================================================ 

class GeminiCLIInterface(BaseModel):
    """Interface to Gemini CLI"""
    project_root: Path = Path("/Users/mirzakhan/Projects/ContractorLens")
    
    async def execute_prompt(self, prompt: str) -> (bool, str):
        """Executes a raw prompt using the Gemini CLI via a temporary file."""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        prompt_file = self.project_root / f".gemini/prompts/temp_{timestamp}.md"
        prompt_file.parent.mkdir(exist_ok=True, parents=True)
        prompt_file.write_text(prompt)
        
        cmd = ["gemini", f"@{prompt_file}"]
        
        try:
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE,
                cwd=str(self.project_root)
            )
            stdout, stderr = await process.communicate()
            prompt_file.unlink()
            
            if process.returncode == 0:
                print("✅ Gemini execution successful.")
                return True, stdout.decode()
            else:
                # The CLI often prints help to stdout on error, so combine them.
                error_output = stderr.decode() + stdout.decode()
                print(f"❌ Gemini execution failed:\n{error_output}")
                return False, error_output
                
        except Exception as e:
            print(f"❌ Error executing Gemini CLI: {e}")
            if prompt_file.exists(): prompt_file.unlink()
            return False, str(e)

# ============================================================================ 
# INTEGRATED ORCHESTRATOR
# ============================================================================ 

class IntegratedOrchestrator(BaseModel):
    """Orchestrator combining all systems"""
    intelligence: CodeIntelligence = Field(default_factory=CodeIntelligence)
    gemini: GeminiCLIInterface = Field(default_factory=GeminiCLIInterface)
    active_tasks: Dict[str, Task] = {}
    discovered_tasks: List[Task] = []
    project_direction: Optional[str] = None
    last_doc_analysis: Optional[datetime] = None

    def load_or_create_context(self):
        """Load existing context or create new one."""
        context_path = self.gemini.project_root / ".gemini/context.json"
        if context_path.exists():
            with open(context_path, 'r') as f:
                context = json.load(f)
            self.project_direction = context.get('project_direction')
            self.last_doc_analysis = datetime.fromisoformat(context.get('last_doc_analysis', '2000-01-01'))
            last_code_analysis = datetime.fromisoformat(context.get('last_code_analysis', '2000-01-01'))
            if (datetime.now() - last_code_analysis).seconds < 3600:
                print("Using cached code analysis (< 1 hour old)")
                if 'discovered_tasks' in context:
                    self.discovered_tasks = [Task(**d) for d in context['discovered_tasks']]
                return
        self.analyze_codebase()
        self.save_context()

    def save_context(self):
        """Save current context."""
        context_path = self.gemini.project_root / ".gemini/context.json"
        context_path.parent.mkdir(exist_ok=True)
        context = {
            'last_code_analysis': datetime.now().isoformat(),
            'last_doc_analysis': self.last_doc_analysis.isoformat() if self.last_doc_analysis else None,
            'project_direction': self.project_direction,
            'discovered_tasks': [task.model_dump() for task in self.discovered_tasks],
            'active_tasks': {k: v.model_dump() for k, v in self.active_tasks.items()}
        }
        with open(context_path, 'w') as f:
            json.dump(context, f, indent=2, default=str)

    def analyze_codebase(self):
        """Analyze codebase and discover tasks."""
        print("\n🔍 Analyzing codebase...")
        self.discovered_tasks = self.intelligence.discover_tasks()
        print(f"Found {len(self.discovered_tasks)} potential tasks from code analysis.")

    async def analyze_documentation(self):
        """Read docs and use Gemini to determine strategic direction."""
        print("\n📚 Analyzing documentation to determine project direction...")
        doc_path = self.gemini.project_root / "docs"
        doc_files = list(doc_path.rglob("*.md"))
        if not doc_files:
            print("⚠️ No markdown files found in docs directory.")
            return

        content = ""
        for doc in doc_files:
            content += f"\n\n--- CONTENT FROM {doc.name} ---\n\n{doc.read_text()}"

        prompt = f"""
        Based on the provided documentation, act as a senior project manager. 
        Synthesize the information to provide a concise, high-level summary of the project's current strategic direction. 
        Focus on key features, technical roadmap, and stated priorities. This summary will guide the AI development team.
        DOCUMENTATION CONTENT:
        {content}
        """
        success, summary = await self.gemini.execute_prompt(prompt)
        if success:
            self.project_direction = summary
            self.last_doc_analysis = datetime.now()
            self.save_context()
            print("\n✅ Successfully analyzed documentation. Project direction has been updated.")
            print(f"\nNew Direction:\n{summary}")
        else:
            print("\n❌ Failed to analyze documentation.")

    async def execute_task(self, task: Task) -> bool:
        """Constructs a full prompt and executes a task."""
        prompt = f"# Task: {task.title}\n\n## Description\n{task.description}\n\n## Agent Role\nYou are a {task.agent.value} for the ContractorLens project."
        if self.project_direction:
            prompt += f"\n\n## Current Project Direction (IMPORTANT CONTEXT)\n{self.project_direction}"
        if task.context_files:
            prompt += "\n\n## Relevant Code Context\n"
            for file_str in task.context_files:
                file_path = self.gemini.project_root / file_str
                if file_path.exists():
                    prompt += f"\n--- START OF {file_str} ---\n{file_path.read_text()}\n--- END OF {file_str}---\n"
        prompt += "\n\n## Instructions\nGenerate production-ready code to complete the task. Align with the project's stated direction. Provide only the code to be written to the file."
        success, result = await self.gemini.execute_prompt(prompt)
        return success

    async def start(self):
        """Start integrated orchestration."""
        print("\n🚀 ContractorLens Integrated Orchestrator\n" + "=" * 50)
        self.load_or_create_context()
        while True:
            await self.display_menu_and_get_choice()

    async def display_menu_and_get_choice(self):
        """Display menu and handle user choice."""
        print("\n" + "=" * 50 + "\n📊 Current Status:")
        detected = len([t for t in self.discovered_tasks if t.status == TaskStatus.DETECTED])
        print(f"Discovered Tasks: {detected} | Active Tasks: {len(self.active_tasks)}")
        if self.project_direction:
            print(f"\n🎯 Project Direction: {self.project_direction[:150]}...")
        else:
            print("\n🎯 Project direction not yet analyzed.")
        
        print("\nWhat would you like to do?")
        options = ["Analyze project direction from docs"]
        if self.discovered_tasks: options.append("Work on discovered tasks")
        if self.active_tasks: options.append("Continue active tasks")
        options.extend(["Describe a custom task", "Re-analyze codebase", "Exit"])
        
        for i, option in enumerate(options, 1): print(f"{i}) {option}")
        choice = input(f"\nChoice [1-{len(options)}]: ").strip()
        
        try:
            selected = options[int(choice) - 1]
            if "Analyze project" in selected: await self.analyze_documentation()
            elif "discovered tasks" in selected: await self.work_on_discovered()
            elif "active tasks" in selected: await self.continue_active()
            elif "custom task" in selected: await self.custom_task()
            elif "Re-analyze" in selected: self.analyze_codebase(); self.save_context()
            elif "Exit" in selected: print("\n👋 Goodbye!"); exit(0)
        except (ValueError, IndexError): print("Invalid choice")

    async def work_on_discovered(self):
        """Work on discovered tasks."""
        print("\n🔍 Discovered tasks:")
        for i, task in enumerate(self.discovered_tasks[:10], 1):
            print(f"{i}) [{task.agent.value}] {task.title}")
        choice = input("\nSelect task [number]: ").strip()
        try:
            task = self.discovered_tasks[int(choice) - 1]
            await self.run_and_update_task(task)
            if task.status == TaskStatus.COMPLETE:
                self.discovered_tasks.remove(task)
        except (ValueError, IndexError): print("Invalid choice")

    async def custom_task(self):
        """Create and execute custom task."""
        print("\n✏️ Describe your task:")
        description = input("> ").strip()
        keywords = {
            AgentRole.BACKEND: ["api", "server", "backend", "node"],
            AgentRole.IOS: ["ios", "swift", "ar", "swiftui"],
            AgentRole.DATABASE: ["sql", "database", "schema", "postgres"],
            AgentRole.ML: ["ml", "gemini", "ai", "vision", "model"],
        }
        agent = AgentRole.GENERAL
        for role, keys in keywords.items():
            if any(k in description.lower() for k in keys):
                agent = role; break
        task = Task(
            task_id=f"CUSTOM_{datetime.now().strftime('%H%M%S')}",
            title=description[:50], description=description,
            agent=agent, source="manual"
        )
        print(f"\n🎯 Assigned to: {agent.value}")
        await self.run_and_update_task(task)

    async def continue_active(self):
        """Continue active tasks."""
        print("\n📋 Active tasks:")
        tasks_list = list(self.active_tasks.values())
        for i, task in enumerate(tasks_list, 1):
            s = {TaskStatus.COMPLETE: "✅", TaskStatus.IN_PROGRESS: "🔄"}.get(task.status, "❌")
            print(f"{i}) {s} [{task.agent.value}] {task.title}")
        choice = input("\nSelect task to re-try [number]: ").strip()
        try:
            task = tasks_list[int(choice) - 1]
            if task.status == TaskStatus.COMPLETE: print("Task already complete!"); return
            await self.run_and_update_task(task)
        except (ValueError, IndexError): print("Invalid choice")

    async def run_and_update_task(self, task: Task):
        """A helper to run a task and update its status."""
        self.active_tasks[task.task_id] = task
        task.status = TaskStatus.IN_PROGRESS
        print(f"\n🚀 Executing: {task.title}")
        success = await self.execute_task(task)
        task.status = TaskStatus.COMPLETE if success else TaskStatus.BLOCKED
        self.save_context()

async def main():
    """Main entry point"""
    orchestrator = IntegratedOrchestrator()
    try:
        await orchestrator.start()
    except KeyboardInterrupt:
        print("\n\n👋 Goodbye!")
        exit(0)

if __name__ == "__main__":
    asyncio.run(main())