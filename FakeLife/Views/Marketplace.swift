import SwiftUI

struct MarketplaceView: View {
    @EnvironmentObject var contentViewModel: ContentViewModel
    @State private var searchText = ""
    
    var filteredContents: [Content] {
        if searchText.isEmpty {
            return contentViewModel.contents
        } else {
            return contentViewModel.contents.filter { content in
                content.title.lowercased().contains(searchText.lowercased()) ||
                content.description.lowercased().contains(searchText.lowercased()) ||
                content.tags.contains { $0.lowercased().contains(searchText.lowercased()) }
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search content", text: $searchText)
                        .autocapitalization(.none)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 5)
                
                if contentViewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if contentViewModel.contents.isEmpty {
                    Spacer()
                    VStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No content available")
                            .font(.headline)
                            .padding(.top, 10)
                        Text("Be the first to upload and sell content!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else if filteredContents.isEmpty {
                    Spacer()
                    Text("No matches found for '\(searchText)'")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    // Content grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 15),
                            GridItem(.flexible(), spacing: 15)
                        ], spacing: 15) {
                            ForEach(filteredContents) { content in
                                NavigationLink(destination: ContentDetailView(content: content)
                                    .environmentObject(contentViewModel)) {
                                    ContentCell(content: content)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            
            if let errorMessage = contentViewModel.errorMessage {
                VStack {
                    Spacer()
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.bottom)
                }
            }
        }
        .navigationTitle("Marketplace")
        .onAppear {
            Task {
                await contentViewModel.fetchAllContent()
            }
        }
        .refreshable {
            await contentViewModel.fetchAllContent()
        }
    }
}

struct ContentCell: View {
    let content: Content
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .topTrailing) {
                // Thumbnail image
                AsyncImage(url: URL(string: content.thumbnailURL)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        Color.gray
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.white)
                            )
                    } else {
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.3))
                    }
                }
                .frame(height: 140)
                .clipped()
                .cornerRadius(10)
                
                // Content type indicator
                HStack(spacing: 4) {
                    if content.contentType == .video {
                        Image(systemName: "video.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "photo.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                .padding(6)
                .background(Color.black.opacity(0.6))
                .cornerRadius(5)
                .padding(8)
            }
            
            Text(content.title)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            HStack {
                Text("$\(String(format: "%.2f", content.price))")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Spacer()
                
                if content.isPurchased == true {
                    Text("Purchased")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Text("@\(content.username)")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    NavigationView {
        MarketplaceView()
            .environmentObject(ContentViewModel())
    }
} 