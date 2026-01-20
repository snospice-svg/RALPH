import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "camera")
                    Text("Home")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }

            HistoryView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("History")
                }
        }
    }
}

struct HomeView: View {
    @State private var showingMenuUpload = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Hero Section
                VStack(spacing: 16) {
                    Text("RALPH")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Restaurant Analysis & Learning Protocol for Hospitality")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button(action: {
                        showingMenuUpload = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Scan New Menu")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)

                // Recent Sessions
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)

                    Text("No menu sessions yet")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Scan your first menu to get personalized recommendations!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()

                Spacer()
            }
            .padding()
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingMenuUpload) {
            MenuUploadView()
        }
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Profile View")
                    .font(.headline)
                Text("Profile features coming soon")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct HistoryView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Image(systemName: "tray")
                    .font(.system(size: 48))
                    .foregroundColor(.gray)

                Text("No menu history")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text("Your analyzed menus will appear here")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct MenuUploadView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Text("Upload Menu")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 20) {
                    Button(action: {
                        // TODO: Implement camera capture
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
                        // TODO: Implement photo library picker
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
                        // TODO: Implement PDF picker
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
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MainTabView()
}