"""
ContractorLens Gemini CLI Orchestration with Pydantic
Builds on existing codebase progress
"""

from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict, Literal, Any
from datetime import datetime
from pathlib import Path
import json
import subprocess
import asyncio
from enum import Enum

# Task Status Enumeration
class TaskStatus(str, Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETE = "complete"
    BLOCKED = "blocked"
    REVIEW = "review"

# Agent Roles
class AgentRole(str, Enum):
    DATABASE = "database-engineer"
    BACKEND = "backend-engineer"
    IOS = "ios-developer"
    ML = "ml-engineer"
    INTEGRATION = "integration-engineer"
    DEVOPS = "devops-engineer"

# Task Model
class Task(BaseModel):
    """Individual development task"""
    task_id: str
    title: str
    description: str
    agent: AgentRole
    status: TaskStatus = TaskStatus.PENDING
    priority: Literal["critical", "high", "medium", "low"]
    dependencies: List[str] = []
    deliverables: List[Path]
    context_files: List[Path] = []
    estimated_hours: float
    actual_hours: Optional[float] = None
    completion_percentage: int = Field(0, ge=0, le=100)
    
    @validator('deliverables')
    def validate_deliverables_exist(cls, v):
        """Check if deliverables have been created"""
        return [Path(p) for p in v]
    
    def is_ready(self, completed_tasks: List[str]) -> bool:
        """Check if all dependencies are met"""
        return all(dep in completed_tasks for dep in self.dependencies)
    
    def check_completion(self) -> bool:
        """Verify if deliverables exist"""
        return all(p.exists() for p in self.deliverables)

# Agent Model
class Agent(BaseModel):
    """Gemini CLI agent configuration"""
    role: AgentRole
    status: Literal["idle", "working", "blocked"]
    current_task: Optional[str] = None
    context: str
    expertise: List[str]
    gemini_config: Dict[str, Any] = Field(default_factory=dict)
    
    def generate_prompt(self, task: Task) -> str:
        """Generate Gemini CLI prompt for task"""
        return f"""
Role: {self.role.value}
Context: {self.context}

Task: {task.title}
Description: {task.description}

Deliverables to create:
{chr(10).join(f"- {d}" for d in task.deliverables)}

Based on existing code:
{chr(10).join(f"- {c}" for c in task.context_files if Path(c).exists())}

Generate production-ready code following the existing patterns.
"""

# Assembly Engine Task Model (specific to current needs)
class AssemblyEngineTask(Task):
    """Specialized task for Assembly Engine completion"""
    sql_queries: List[str] = []
    test_cases: List[Dict[str, Any]] = []
    
    def validate_implementation(self) -> bool:
        """Validate Assembly Engine implementation against requirements"""
        engine_path = Path("backend/src/services/assemblyEngine.js")
        if not engine_path.exists():
            return False
        
        code = engine_path.read_text()
        required_methods = [
            "calculateEstimate",
            "getLocalizedCost",
            "applyFinishLevels",
            "calculateProductionRates"
        ]
        return all(method in code for method in required_methods)

# Sprint Model
class Sprint(BaseModel):
    """Sprint containing multiple tasks"""
    sprint_id: str
    name: str
    start_date: datetime
    end_date: datetime
    tasks: List[Task]
    completed_tasks: List[str] = []
    
    def get_ready_tasks(self) -> List[Task]:
        """Get tasks ready for assignment"""
        return [
            task for task in self.tasks
            if task.status == TaskStatus.PENDING
            and task.is_ready(self.completed_tasks)
        ]
    
    def update_progress(self) -> Dict[str, Any]:
        """Calculate sprint progress"""
        total = len(self.tasks)
        complete = len([t for t in self.tasks if t.status == TaskStatus.COMPLETE])
        in_progress = len([t for t in self.tasks if t.status == TaskStatus.IN_PROGRESS])
        blocked = len([t for t in self.tasks if t.status == TaskStatus.BLOCKED])
        
        return {
            "total_tasks": total,
            "complete": complete,
            "in_progress": in_progress,
            "blocked": blocked,
            "completion_percentage": (complete / total * 100) if total > 0 else 0
        }

# Gemini CLI Executor
class GeminiCLIExecutor(BaseModel):
    """Executes tasks using Gemini CLI"""
    agent: Agent
    working_directory: Path
    gemini_binary: str = "gemini"
    
    async def execute_task(self, task: Task) -> bool:
        """Execute task using Gemini CLI"""
        prompt = self.agent.generate_prompt(task)
        
        # Save prompt to temporary file
        prompt_file = self.working_directory / f".prompts/{task.task_id}.md"
        prompt_file.parent.mkdir(exist_ok=True)
        prompt_file.write_text(prompt)
        
        # Execute with Gemini CLI
        cmd = [
            self.gemini_binary,
            "generate",
            "--prompt-file", str(prompt_file),
            "--output-dir", str(self.working_directory),
            "--context-aware",
            "--validate"
        ]
        
        try:
            result = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=str(self.working_directory)
            )
            stdout, stderr = await result.communicate()
            
            if result.returncode == 0:
                # Check if deliverables were created
                return task.check_completion()
            else:
                print(f"Error executing task {task.task_id}: {stderr.decode()}")
                return False
                
        except Exception as e:
            print(f"Failed to execute task {task.task_id}: {e}")
            return False

# Current Sprint Definition Based on Analysis
class ContractorLensSprint(BaseModel):
    """Current sprint based on codebase analysis"""
    
    @classmethod
    def create_current_sprint(cls) -> Sprint:
        """Create sprint based on current progress"""
        
        # Tasks based on what needs to be completed
        tasks = [
            # Backend completion tasks
            Task(
                task_id="BE002",
                title="Complete Assembly Engine Production Rate Calculations",
                description="Implement production rate calculations using quantity_per_unit from database",
                agent=AgentRole.BACKEND,
                status=TaskStatus.PENDING,
                priority="critical",
                dependencies=[],  # DB001 is complete
                deliverables=[
                    Path("backend/src/services/assemblyEngine.js"),
                    Path("backend/tests/assemblyEngine.test.js")
                ],
                context_files=[
                    Path("database/schemas/schema.sql"),
                    Path("backend/src/services/assemblyEngine.js")  # Existing partial implementation
                ],
                estimated_hours=4
            ),
            Task(
                task_id="BE003",
                title="Implement Cost Hierarchy Logic",
                description="Implement RetailPrices → national_average × modifier fallback",
                agent=AgentRole.BACKEND,
                status=TaskStatus.PENDING,
                priority="critical",
                dependencies=["BE002"],
                deliverables=[
                    Path("backend/src/services/costCalculator.js")
                ],
                context_files=[
                    Path("database/schemas/schema.sql")
                ],
                estimated_hours=3
            ),
            Task(
                task_id="API001",
                title="Complete /api/v1/estimates Endpoint",
                description="Implement estimates endpoint with full Assembly Engine integration",
                agent=AgentRole.BACKEND,
                status=TaskStatus.PENDING,
                priority="high",
                dependencies=["BE002", "BE003"],
                deliverables=[
                    Path("backend/src/routes/estimates.js")
                ],
                context_files=[
                    Path("docs/ContractorLens OpenAPI Specification v1.0.md")
                ],
                estimated_hours=3
            ),
            Task(
                task_id="IOS003",
                title="Implement AR Scanner with Frame Sampling",
                description="Create RoomPlan integration with 0.5s frame sampling",
                agent=AgentRole.IOS,
                status=TaskStatus.PENDING,
                priority="high",
                dependencies=[],
                deliverables=[
                    Path("ios-app/ContractorLens/AR/RoomScanner.swift"),
                    Path("ios-app/ContractorLens/Models/ScanResult.swift")
                ],
                context_files=[
                    Path("scanning-user-flow-explanation")
                ],
                estimated_hours=6
            ),
            Task(
                task_id="INT001",
                title="Integration Testing Suite",
                description="Create end-to-end tests for scan → analysis → estimate flow",
                agent=AgentRole.INTEGRATION,
                status=TaskStatus.BLOCKED,
                priority="high",
                dependencies=["BE002", "BE003", "API001"],
                deliverables=[
                    Path("testing/integration/e2e.test.js")
                ],
                context_files=[
                    Path("backend"),
                    Path("ml-services/gemini-service")
                ],
                estimated_hours=4
            )
        ]
        
        return Sprint(
            sprint_id="sprint-2",
            name="Complete Core Functionality",
            start_date=datetime.now(),
            end_date=datetime.now().replace(day=datetime.now().day + 7),
            tasks=tasks,
            completed_tasks=["DB001", "ML001"]  # Based on analysis
        )

# Orchestrator
class GeminiOrchestrator(BaseModel):
    """Main orchestrator for Gemini CLI agents"""
    sprint: Sprint
    agents: Dict[AgentRole, Agent]
    executors: Dict[AgentRole, GeminiCLIExecutor] = Field(default_factory=dict)
    
    def initialize_agents(self):
        """Initialize agents based on current needs"""
        self.agents = {
            AgentRole.BACKEND: Agent(
                role=AgentRole.BACKEND,
                status="idle",
                context="Building deterministic Assembly Engine with production rates",
                expertise=["Node.js", "PostgreSQL", "Cost calculations", "Production rates"]
            ),
            AgentRole.IOS: Agent(
                role=AgentRole.IOS,
                status="idle", 
                context="SwiftUI app with ARKit/RoomPlan for measurements-first workflow",
                expertise=["SwiftUI", "ARKit", "RoomPlan", "Frame sampling"]
            ),
            AgentRole.INTEGRATION: Agent(
                role=AgentRole.INTEGRATION,
                status="idle",
                context="End-to-end testing of complete flow",
                expertise=["Jest", "Integration testing", "API testing"]
            )
        }
        
        # Create executors
        for role, agent in self.agents.items():
            self.executors[role] = GeminiCLIExecutor(
                agent=agent,
                working_directory=Path("/Users/mirzakhan/Projects/ContractorLens")
            )
    
    async def run_sprint(self):
        """Execute sprint tasks"""
        while True:
            # Get ready tasks
            ready_tasks = self.sprint.get_ready_tasks()
            if not ready_tasks:
                if all(t.status == TaskStatus.COMPLETE for t in self.sprint.tasks):
                    print("Sprint complete!")
                    break
                else:
                    print("Waiting for dependencies...")
                    await asyncio.sleep(60)
                    continue
            
            # Assign tasks to available agents
            for task in ready_tasks:
                if self.agents[task.agent].status == "idle":
                    print(f"Assigning {task.task_id} to {task.agent.value}")
                    self.agents[task.agent].status = "working"
                    self.agents[task.agent].current_task = task.task_id
                    task.status = TaskStatus.IN_PROGRESS
                    
                    # Execute task
                    success = await self.executors[task.agent].execute_task(task)
                    
                    if success:
                        task.status = TaskStatus.COMPLETE
                        self.sprint.completed_tasks.append(task.task_id)
                        print(f"✅ Completed {task.task_id}")
                    else:
                        task.status = TaskStatus.BLOCKED
                        print(f"❌ Failed {task.task_id}")
                    
                    self.agents[task.agent].status = "idle"
                    self.agents[task.agent].current_task = None
            
            # Update progress
            progress = self.sprint.update_progress()
            print(f"Sprint Progress: {progress}")
            
            await asyncio.sleep(30)

# Main execution
async def main():
    """Main orchestration entry point"""
    # Create current sprint based on analysis
    sprint = ContractorLensSprint.create_current_sprint()
    
    # Initialize orchestrator
    orchestrator = GeminiOrchestrator(sprint=sprint)
    orchestrator.initialize_agents()
    
    # Save sprint configuration
    config_path = Path("/Users/mirzakhan/Projects/ContractorLens/.gemini/sprint.json")
    config_path.parent.mkdir(exist_ok=True)
    config_path.write_text(sprint.json(indent=2))
    
    print(f"Starting Sprint: {sprint.name}")
    print(f"Ready tasks: {[t.task_id for t in sprint.get_ready_tasks()]}")
    
    # Run sprint
    await orchestrator.run_sprint()

if __name__ == "__main__":
    asyncio.run(main())
