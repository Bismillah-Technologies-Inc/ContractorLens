import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @State private var showingCreateProject = false
    @State private var newProjectName = ""
    @State private var newClientName = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(projects) { project in
                    NavigationLink(destination: ProjectDetailView(project: project)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(project.name)
                                .font(.headline)
                            if let client = project.clientName {
                                Text(client)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Text("\(project.rooms.count) room(s)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteProjects)
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateProject = true }) {
                        Label("New Project", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateProject) {
                CreateProjectView(isPresented: $showingCreateProject) { name, client in
                    createProject(name: name, client: client)
                }
            }
            .overlay {
                if projects.isEmpty {
                    ContentUnavailableView(
                        "No Projects",
                        systemImage: "folder.badge.plus",
                        description: Text("Create a new project to start scanning rooms.")
                    )
                }
            }
        }
    }
    
    private func createProject(name: String, client: String?) {
        let project = Project(name: name, clientName: client)
        modelContext.insert(project)
    }
    
    private func deleteProjects(at offsets: IndexSet) {
        for index in offsets {
            let project = projects[index]
            modelContext.delete(project)
        }
    }
}

struct CreateProjectView: View {
    @Binding var isPresented: Bool
    @State private var projectName = ""
    @State private var clientName = ""
    var onCreate: (String, String?) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Project Details")) {
                    TextField("Project Name", text: $projectName)
                    TextField("Client Name (Optional)", text: $clientName)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(projectName, clientName.isEmpty ? nil : clientName)
                        isPresented = false
                    }
                    .disabled(projectName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ProjectListView()
        .modelContainer(for: Project.self, inMemory: true)
}