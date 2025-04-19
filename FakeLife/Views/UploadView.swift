import SwiftUI
import PhotosUI

struct UploadView: View {
    @EnvironmentObject var contentViewModel: ContentViewModel
    
    @State private var showPhotosPicker = false
    @State private var showPriceHelp = false
    @State private var showingConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text("Upload Content")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                // Content type selector
                VStack(alignment: .leading) {
                    Text("Content Type")
                        .font(.headline)
                    
                    Picker("Content Type", selection: $contentViewModel.selectedContentType) {
                        Text("Photo").tag(ContentType.photo)
                        Text("Video").tag(ContentType.video)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)
                
                // Media selection
                VStack(alignment: .leading) {
                    Text("Select Media")
                        .font(.headline)
                    
                    if contentViewModel.thumbnailImage != nil {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: contentViewModel.thumbnailImage!)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(10)
                                .frame(height: 200)
                            
                            Button(action: {
                                contentViewModel.selectedPhotoItem = nil
                                contentViewModel.selectedVideoItem = nil
                                contentViewModel.thumbnailImage = nil
                                contentViewModel.contentData = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Circle())
                                    .padding(8)
                            }
                        }
                    } else {
                        Button(action: {
                            showPhotosPicker = true
                        }) {
                            VStack {
                                Image(systemName: contentViewModel.selectedContentType == .photo ? "photo" : "video")
                                    .font(.system(size: 30))
                                    .padding()
                                Text("Tap to select \(contentViewModel.selectedContentType == .photo ? "photo" : "video")")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Content info
                VStack(alignment: .leading, spacing: 15) {
                    Text("Content Information")
                        .font(.headline)
                    
                    TextField("Title", text: $contentViewModel.title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Description", text: $contentViewModel.description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                    
                    HStack {
                        Text("Price")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Button(action: {
                            showPriceHelp = true
                        }) {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                        }
                        .alert("Pricing Guidelines", isPresented: $showPriceHelp) {
                            Button("OK", role: .cancel) { }
                        } message: {
                            Text("Set a price between $0.99 and $49.99. FakeLife takes a 15% fee from each sale.")
                        }
                    }
                    
                    HStack {
                        Text("$")
                            .font(.headline)
                        
                        TextField("0.00", value: $contentViewModel.price, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    Text("Tags (comma separated)")
                        .font(.subheadline)
                    
                    TextField("art, design, tutorial", text: $contentViewModel.tags)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                }
                .padding(.horizontal)
                
                // Submit button
                Button(action: {
                    submitContent()
                }) {
                    if contentViewModel.isUploading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    } else {
                        Text("Upload Content")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(contentViewModel.isUploading || !isFormValid())
                .padding(.horizontal)
                .padding(.top, 20)
                
                if let errorMessage = contentViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Upload")
        .photosPicker(
            isPresented: $showPhotosPicker,
            selection: contentViewModel.selectedContentType == .photo ? $contentViewModel.selectedPhotoItem : $contentViewModel.selectedVideoItem,
            matching: contentViewModel.selectedContentType == .photo ? .images : .videos
        )
        .onChange(of: contentViewModel.selectedPhotoItem) { newValue in
            if let item = newValue {
                Task {
                    await contentViewModel.loadThumbnail(from: item)
                }
            }
        }
        .onChange(of: contentViewModel.selectedVideoItem) { newValue in
            if let item = newValue {
                Task {
                    await contentViewModel.loadVideo(from: item)
                }
            }
        }
        .alert("Upload Successful", isPresented: $showingConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your content has been uploaded and is now available in the marketplace.")
        }
    }
    
    private func isFormValid() -> Bool {
        return contentViewModel.thumbnailImage != nil &&
               contentViewModel.contentData != nil &&
               !contentViewModel.title.isEmpty &&
               contentViewModel.price > 0
    }
    
    private func submitContent() {
        Task {
            let success = await contentViewModel.uploadContent()
            if success {
                showingConfirmation = true
            }
        }
    }
}

#Preview {
    NavigationView {
        UploadView()
            .environmentObject(ContentViewModel())
    }
} 