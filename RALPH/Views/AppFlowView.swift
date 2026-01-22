import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct AppFlowView: View {
    @StateObject private var authService = AuthenticationService.shared
    @State private var currentFlow: AppFlow = .welcome

    enum AppFlow {
        case welcome
        case menuAnalysis
        case profileCreation
        case accountCreation
        case main
    }

    var body: some View {
        Group {
            switch currentFlow {
            case .welcome:
                WelcomeFlowView(onContinue: {
                    currentFlow = .menuAnalysis
                })

            case .menuAnalysis:
                MenuAnalysisFlowView(
                    onRecommendationsGenerated: { _ in
                        currentFlow = .profileCreation
                    }
                )

            case .profileCreation:
                ProfileCreationFlowView(
                    onProfileCreated: { profile in
                        // Store the profile temporarily
                        currentFlow = .accountCreation
                    },
                    onSkip: {
                        authService.skipAccountCreation()
                        currentFlow = .main
                    }
                )

            case .accountCreation:
                AccountCreationFlowView(
                    onAccountCreated: {
                        authService.completeOnboarding()
                        currentFlow = .main
                    },
                    onSkip: {
                        authService.skipAccountCreation()
                        currentFlow = .main
                    }
                )

            case .main:
                MainTabView()
            }
        }
        .onAppear {
            setupInitialFlow()
        }
    }

    private func setupInitialFlow() {
        if authService.hasCompletedOnboarding || authService.isAuthenticated {
            currentFlow = .main
        } else {
            currentFlow = .welcome
        }
    }
}

struct WelcomeFlowView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Text("RALPH")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)

                Text("Restaurant Analysis & Learning\nProtocol for Hospitality")
                    .font(.title2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 20) {
                FeatureRow(icon: "camera.fill", title: "Smart Menu Analysis", description: "Upload menu photos and get instant translations and insights")

                FeatureRow(icon: "person.fill", title: "Personalized Recommendations", description: "Get dish suggestions based on your unique taste profile")

                FeatureRow(icon: "chart.pie.fill", title: "Taste Mapping", description: "Discover your flavor preferences with our interactive chart")
            }

            Spacer()

            Button(action: onContinue) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

struct MenuAnalysisFlowView: View {
    let onRecommendationsGenerated: ([MenuItem]) -> Void
    @State private var showingMenuUpload = true
    @State private var showingRecommendations = false
    @State private var mockRecommendations: [MenuItem] = []
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingDocumentPicker = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var hasUploadedFile = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if !showingRecommendations {
                    VStack(spacing: 24) {
                        Text("Upload Your Menu")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Take a photo or select an image of the restaurant menu you'd like analyzed")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        VStack(spacing: 16) {
                            Button(action: {
                                print("Camera button tapped") // Debug log
                                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                    imagePickerSourceType = .camera
                                    showingCamera = true
                                } else {
                                    alertMessage = "Camera is not available on this device. Try using the photo library or PDF option instead."
                                    showingAlert = true
                                }
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 32))
                                    Text("Take Photo")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .background(Color.blue)
                                .cornerRadius(12)
                            }

                            Button(action: {
                                print("Photo library button tapped") // Debug log
                                if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                                    imagePickerSourceType = .photoLibrary
                                    showingImagePicker = true
                                } else {
                                    alertMessage = "Photo library is not available on this device."
                                    showingAlert = true
                                }
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 32))
                                    Text("Choose from Library")
                                        .font(.headline)
                                }
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }

                            Button(action: {
                                print("PDF button tapped") // Debug log
                                showingDocumentPicker = true
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "doc.fill")
                                        .font(.system(size: 32))
                                    Text("Select PDF")
                                        .font(.headline)
                                }
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }

                            Button(action: {
                                print("Demo menu button tapped") // Debug log
                                hasUploadedFile = true
                                generateMockRecommendations()
                            }) {
                                HStack {
                                    Image(systemName: "play.circle.fill")
                                    Text("Use Demo Menu")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                            }
                        }
                    }
                } else {
                    RecommendationsView(
                        recommendations: mockRecommendations,
                        onContinue: {
                            onRecommendationsGenerated(mockRecommendations)
                        }
                    )
                }

                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(
                    selectedImage: $selectedImage,
                    sourceType: imagePickerSourceType,
                    onImageSelected: { image in
                        selectedImage = image
                        hasUploadedFile = true
                        processUploadedImage(image)
                    }
                )
            }
            .fullScreenCover(isPresented: $showingCamera) {
                ImagePicker(
                    selectedImage: $selectedImage,
                    sourceType: .camera,
                    onImageSelected: { image in
                        selectedImage = image
                        hasUploadedFile = true
                        processUploadedImage(image)
                    }
                )
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(onDocumentSelected: { url in
                    hasUploadedFile = true
                    processUploadedDocument(url)
                })
            }
            .alert("Notice", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func processUploadedImage(_ image: UIImage) {
        // TODO: Process the uploaded image with AI
        // For now, generate mock recommendations after a delay to simulate processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            generateMockRecommendations()
        }
    }

    private func processUploadedDocument(_ url: URL) {
        // TODO: Process the uploaded PDF with AI
        // For now, generate mock recommendations after a delay to simulate processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            generateMockRecommendations()
        }
    }

    private func generateMockRecommendations() {
        // Only generate recommendations if a file has been uploaded or demo is used
        guard hasUploadedFile else { return }

        // Mock recommendations for demo
        mockRecommendations = [
            MenuItem(
                id: UUID(),
                name: "Margherita Pizza",
                description: "Fresh tomatoes, mozzarella, basil",
                price: "$18.00",
                category: "Pizza",
                dietaryTags: ["Vegetarian"],
                spiceLevel: 1,
                matchScore: 95
            ),
            MenuItem(
                id: UUID(),
                name: "Caesar Salad",
                description: "Romaine lettuce, parmesan, croutons",
                price: "$14.00",
                category: "Salads",
                dietaryTags: ["Vegetarian"],
                spiceLevel: 0,
                matchScore: 87
            ),
            MenuItem(
                id: UUID(),
                name: "Grilled Salmon",
                description: "Atlantic salmon, lemon herbs, seasonal vegetables",
                price: "$26.00",
                category: "Seafood",
                dietaryTags: ["Gluten-free"],
                spiceLevel: 2,
                matchScore: 82
            )
        ]

        withAnimation {
            showingRecommendations = true
        }
    }
}

struct RecommendationsView: View {
    let recommendations: [MenuItem]
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("Your Recommendations")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Based on general preferences, here are some dishes we think you'll enjoy:")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(recommendations) { item in
                        RecommendationCard(item: item)
                    }
                }
                .padding()
            }

            VStack(spacing: 12) {
                Text("Want better recommendations?")
                    .font(.headline)
                    .foregroundColor(.blue)

                Text("Create a taste profile to get personalized suggestions tailored just for you!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: onContinue) {
                    Text("Create Taste Profile")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
        }
        .padding()
    }
}

struct RecommendationCard: View {
    let item: MenuItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayName)
                        .font(.headline)

                    Text(item.displayDescription)
                        .font(.body)
                        .foregroundColor(.secondary)

                    HStack {
                        Text(item.formattedPrice)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)

                        Spacer()

                        Text("\(item.matchScore)% match")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(12)
                    }
                }

                Spacer()

                VStack(spacing: 4) {
                    ForEach(0..<5) { star in
                        Image(systemName: star < item.spiceLevel ? "flame.fill" : "flame")
                            .foregroundColor(star < item.spiceLevel ? .red : .gray.opacity(0.3))
                            .font(.caption)
                    }
                }
            }

            if !item.dietaryTags.isEmpty {
                HStack {
                    ForEach(item.dietaryTags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - File Picker Components

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let sourceType: UIImagePickerController.SourceType
    let onImageSelected: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        print("Creating ImagePicker with sourceType: \(sourceType)")
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onImageSelected(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let onDocumentSelected: (URL) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        print("Creating DocumentPicker")
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.onDocumentSelected(url)
            }
            parent.dismiss()
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}