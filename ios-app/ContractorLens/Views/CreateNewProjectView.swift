import SwiftUI

struct CreateNewProjectView: View {
    @Binding var isPresented: Bool
    let onProjectCreated: (String) -> Void

    @State private var projectName: String = ""
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                VStack(spacing: 16) {
                    Text("Create New Project")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Enter a name for your new room scanning project")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }

                VStack(spacing: 16) {
                    TextField("Project Name", text: $projectName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 40)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)

                    if showError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    Button(action: createProject) {
                        Text("Start Scanning")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal, 40)

                    Button(action: cancel) {
                        Text("Cancel")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 40)
            }
            .padding()
            .navigationBarHidden(true)
        }
    }

    private func createProject() {
        let trimmedName = projectName.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            showError = true
            errorMessage = "Please enter a project name"
            return
        }

        if trimmedName.count < 2 {
            showError = true
            errorMessage = "Project name must be at least 2 characters"
            return
        }

        // Valid project name
        onProjectCreated(trimmedName)
        isPresented = false
    }

    private func cancel() {
        isPresented = false
    }
}

struct CreateNewProjectView_Previews: PreviewProvider {
    static var previews: some View {
        CreateNewProjectView(isPresented: .constant(true)) { projectName in
            print("Project created: \(projectName)")
        }
    }
}