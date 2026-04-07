
import SwiftUI

struct ChatView: View {
    @StateObject var viewModel: ChatViewModel
    @State private var messageText: String = ""
    @Environment(\.dismiss) private var dismiss
    
    // Callback to pass the updated estimate back
    var onUpdate: (Estimate) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollViewReader { scrollViewProxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if viewModel.isTyping {
                                TypingIndicator()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) {
                        scrollToBottom(proxy: scrollViewProxy)
                    }
                }
                
                inputBar
            }
            .navigationTitle("Modify Estimate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Pass the potentially modified estimate back
                        onUpdate(viewModel.estimate)
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Describe your changes...", text: $messageText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(8)
            
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(messageText.isEmpty ? .gray : .blue)
            }
            .disabled(messageText.isEmpty)
        }
        .padding()
        .background(.thinMaterial)
    }
    
    private func sendMessage() {
        viewModel.sendMessage(messageText)
        messageText = ""
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastMessageId = viewModel.messages.last?.id else { return }
        withAnimation {
            proxy.scrollTo(lastMessageId, anchor: .bottom)
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }
            
            Text(message.text)
                .padding(12)
                .background(message.isFromUser ? Color.blue : Color(UIColor.systemGray5))
                .foregroundColor(message.isFromUser ? .white : .primary)
                .cornerRadius(16)
            
            if !message.isFromUser {
                Spacer()
            }
        }
    }
}

struct TypingIndicator: View {
    var body: some View {
        HStack {
            Text("ContractorLens is typing...")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

#Preview {
    // ChatView(viewModel: ChatViewModel(estimate: MockEstimateGenerator.generate())) { _ in }
}
