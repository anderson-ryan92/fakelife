import SwiftUI
import AVKit

struct ContentDetailView: View {
    @EnvironmentObject var contentViewModel: ContentViewModel
    @State var content: Content
    @State private var showingPaymentSheet = false
    @State private var showShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Content Preview
                ZStack {
                    if content.contentType == .video {
                        if content.isPurchased == true {
                            VideoPlayerView(url: URL(string: content.contentURL)!)
                                .aspectRatio(16/9, contentMode: .fit)
                                .cornerRadius(12)
                        } else {
                            AsyncImage(url: URL(string: content.thumbnailURL)) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(16/9, contentMode: .fit)
                                        .cornerRadius(12)
                                        .overlay(
                                            Image(systemName: "play.circle")
                                                .font(.system(size: 50))
                                                .foregroundColor(.white)
                                        )
                                        .overlay(
                                            VStack {
                                                Spacer()
                                                Text("Purchase to watch full video")
                                                    .foregroundColor(.white)
                                                    .font(.callout)
                                                    .padding(8)
                                                    .background(Color.black.opacity(0.7))
                                                    .cornerRadius(5)
                                                    .padding(.bottom, 10)
                                            }
                                        )
                                } else {
                                    Rectangle()
                                        .foregroundColor(.gray.opacity(0.3))
                                        .aspectRatio(16/9, contentMode: .fit)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    } else {
                        // Photo content
                        if content.isPurchased == true {
                            AsyncImage(url: URL(string: content.contentURL)) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .cornerRadius(12)
                                } else {
                                    Rectangle()
                                        .foregroundColor(.gray.opacity(0.3))
                                        .aspectRatio(16/9, contentMode: .fit)
                                        .cornerRadius(12)
                                }
                            }
                        } else {
                            AsyncImage(url: URL(string: content.thumbnailURL)) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(16/9, contentMode: .fit)
                                        .cornerRadius(12)
                                        .blur(radius: 15)
                                        .overlay(
                                            VStack {
                                                Text("Purchase to view full image")
                                                    .foregroundColor(.white)
                                                    .font(.callout)
                                                    .padding(8)
                                                    .background(Color.black.opacity(0.7))
                                                    .cornerRadius(5)
                                            }
                                        )
                                } else {
                                    Rectangle()
                                        .foregroundColor(.gray.opacity(0.3))
                                        .aspectRatio(16/9, contentMode: .fit)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Content Info
                VStack(alignment: .leading, spacing: 12) {
                    Text(content.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text("@\(content.username)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("\(content.downloadCount) downloads")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Divider()
                    
                    Text(content.description)
                        .font(.body)
                        .padding(.vertical, 5)
                    
                    HStack {
                        ForEach(content.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(5)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(5)
                        }
                    }
                    .padding(.vertical, 5)
                    
                    Divider()
                    
                    // Price and Purchase Section
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Price")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("$\(String(format: "%.2f", content.price))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        if content.isPurchased == true {
                            // Download button
                            Button(action: {
                                downloadContent()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text("Download")
                                }
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(contentViewModel.isDownloading)
                            
                            if contentViewModel.isDownloading {
                                ProgressView()
                                    .padding(.leading, 8)
                            }
                        } else {
                            // Purchase button
                            Button(action: {
                                purchaseContent()
                            }) {
                                HStack {
                                    Image(systemName: "cart.fill.badge.plus")
                                    Text("Purchase")
                                }
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(contentViewModel.isPurchasing)
                            
                            if contentViewModel.isPurchasing {
                                ProgressView()
                                    .padding(.leading, 8)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Content Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: 
            Button(action: {
                showShareSheet = true
            }) {
                Image(systemName: "square.and.arrow.up")
            }
        )
        .sheet(isPresented: $showShareSheet) {
            if let id = content.id {
                let url = URL(string: "cloutmarket://content/\(id)")!
                ShareSheet(items: [url])
            }
        }
        .onAppear {
            if let id = content.id {
                Task {
                    await contentViewModel.fetchContentDetail(contentId: id)
                    if let updatedContent = contentViewModel.selectedContent {
                        self.content = updatedContent
                    }
                }
            }
        }
        .alert(item: Binding(
            get: { contentViewModel.errorMessage.map { ErrorMessage(message: $0) } },
            set: { _ in contentViewModel.errorMessage = nil }
        )) { errorMessage in
            Alert(
                title: Text("Error"),
                message: Text(errorMessage.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func purchaseContent() {
        Task {
            let success = await contentViewModel.purchaseContent(content: content)
            if success {
                self.content.isPurchased = true
            }
        }
    }
    
    private func downloadContent() {
        Task {
            let _ = await contentViewModel.downloadContent(content: content)
        }
    }
}

struct VideoPlayerView: View {
    let url: URL
    
    var body: some View {
        VideoPlayer(player: AVPlayer(url: url))
            .cornerRadius(12)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

#Preview {
    NavigationView {
        ContentDetailView(content: Content(
            id: "123",
            userId: "user1",
            username: "creator",
            title: "Amazing Sunset",
            description: "A beautiful sunset photo taken at the beach",
            price: 2.99,
            contentType: .photo,
            thumbnailURL: "",
            contentURL: "",
            tags: ["sunset", "beach", "photography"],
            createdAt: Date()
        ))
        .environmentObject(ContentViewModel())
    }
} 