import SwiftUI

struct SplashScreen: View {
    @State private var isAnimating = false
    @Binding var isFinished: Bool
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                HStack(spacing: 0) {
                    Text("ALPHA")
                        .font(.system(size: 40, weight: .bold))
                    Text("flow")
                        .font(.system(size: 40))
                        .italic()
                }
                .opacity(isAnimating ? 1 : 0)
            }
        }
        .onAppear {
            print("Splash screen appeared")
            isAnimating = true
            
            // Force dismiss after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                print("Attempting to dismiss splash screen")
                isFinished = false
                
                // Double-check dismissal
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFinished = false
                }
            }
        }
        .onChange(of: isFinished) { newValue in
            print("Splash screen isFinished changed to: \(newValue)")
        }
    }
}

#Preview {
    SplashScreen(isFinished: .constant(false))
} 