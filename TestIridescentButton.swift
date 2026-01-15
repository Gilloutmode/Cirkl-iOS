import SwiftUI

struct TestIridescentView: View {
    var body: some View {
        ZStack {
            // Dark background to see the effects better
            Color.black
                .ignoresSafeArea()
            
            VStack {
                Text("Test Iridescent Button")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                
                Spacer()
                
                // The iridescent button
                IridescentAIButton()
                
                Spacer()
                
                Text("The button should have:")
                    .foregroundColor(.white)
                    .padding()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("✓ Rotating gradient ring")
                    Text("✓ Breathing scale effect")
                    Text("✓ Morphing organic shape")
                    Text("✓ Shimmer animation")
                    Text("✓ Liquid distortion")
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .padding()
            }
        }
    }
}

#Preview {
    TestIridescentView()
}