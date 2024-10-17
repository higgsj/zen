import SwiftUI

struct HomeView: View {
    @State private var showTutorial = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Welcome to AlphaFlow")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                HStack(spacing: 16) {
                    exerciseCard(title: "Kegel", icon: "leaf.fill", color: .green)
                    exerciseCard(title: "Box Breathing", icon: "lungs.fill", color: .orange)
                    exerciseCard(title: "Meditation", icon: "brain.head.profile", color: .purple)
                }
                .padding()
                
                Button(action: {
                    showTutorial = true
                }) {
                    Text("View Tutorial")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
        .sheet(isPresented: $showTutorial) {
            TutorialView(screens: TutorialContent.screens)
        }
    }
    
    private func exerciseCard(title: String, icon: String, color: Color) -> some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(10)
    }
}
