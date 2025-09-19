
import SwiftUI

struct ContentView: View {
    @State private var projects: [Project] = []
    @State private var showingCreateNewProject = false
    @State private var projectToScan: Project? // New state to trigger scanning view
    private let persistenceService = ProjectPersistenceService()

    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                if projects.isEmpty {
                    emptyStateView
                } else {
                    projectListView
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingCreateNewProject = true }) {
                        Label("New Project", systemImage: "plus")
                    }
                }
            }
            .onAppear(perform: loadProjects)
            .sheet(isPresented: $showingCreateNewProject) {
                CreateNewProjectView(isPresented: $showingCreateNewProject) { projectName in
                    let newProject = Project(name: projectName)
                    do {
                        try persistenceService.save(project: newProject)
                        loadProjects() // Refresh the list
                        // Immediately trigger the scanning view for the new project
                        projectToScan = newProject
                    } catch {
                        // Handle error appropriately
                        print("❌ ContentView: Failed to save new project: \(error.localizedDescription)")
                    }
                }
            }
            .fullScreenCover(item: $projectToScan, onDismiss: { 
                loadProjects()
            }) { project in
                // Provide a binding to the project for the scanning view
                if let index = projects.firstIndex(where: { $0.id == project.id }) {
                     ScanningView(projectName: projects[index].name) { scanPackage in
                        // This closure is called when the scan is complete, before dismissal.
                        var updatedProject = projects[index]
                        updatedProject.scans.insert(scanPackage, at: 0)
                        updatedProject.lastModified = Date()
                        if updatedProject.coverImage == nil, let firstFrame = scanPackage.capturedFrames.first {
                            updatedProject.coverImage = firstFrame
                        }
                        let persistence = ProjectPersistenceService()
                        try? persistence.save(project: updatedProject)
                    }
                } else {
                    // This case handles a new project which might not be in the main `projects` array yet.
                    ScanningView(projectName: project.name) { scanPackage in
                        // Find the project, update it with the new scan, and save it.
                        var projectToUpdate = project
                        projectToUpdate.scans.insert(scanPackage, at: 0)
                        projectToUpdate.lastModified = Date()
                        if projectToUpdate.coverImage == nil, let firstFrame = scanPackage.capturedFrames.first {
                            projectToUpdate.coverImage = firstFrame
                        }
                        let persistence = ProjectPersistenceService()
                        try? persistence.save(project: projectToUpdate)
                    }
                }
            }
            .navigationDestination(for: Project.self) { project in
                // Find the binding for the project to pass to the detail view
                if let index = projects.firstIndex(where: { $0.id == project.id }) {
                    ProjectDetailView(project: $projects[index])
                }
            }
        }
    }
    
    private var projectListView: some View {
        List {
            ForEach($projects) { $project in
                NavigationLink(destination: ProjectDetailView(project: $project)) {
                    ProjectRowView(project: project)
                }
            }
            .onDelete(perform: deleteProject)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            Text("No Projects Yet")
                .font(.title2).bold()
            Text("Tap the '+' button to create your first project and start scanning.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            Spacer()
        }
    }
    
    private func loadProjects() {
        self.projects = persistenceService.loadProjects()
    }
    
    private func deleteProject(at offsets: IndexSet) {
        offsets.forEach { index in
            let project = projects[index]
            do {
                try persistenceService.delete(project: project)
            } catch {
                print("❌ ContentView: Failed to delete project \(project.name): \(error.localizedDescription)")
            }
        }
        projects.remove(atOffsets: offsets)
    }
}

struct ProjectRowView: View {
    let project: Project
    
    var body: some View {
        HStack {
            if let imageData = project.coverImage, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipped()
                    .cornerRadius(8)
            } else {
                Image(systemName: "house.fill")
                    .frame(width: 60, height: 60)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading) {
                Text(project.name)
                    .font(.headline)
                Text("\(project.scans.count) scan(s)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Last modified: \(project.lastModified, style: .relative) ago")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
