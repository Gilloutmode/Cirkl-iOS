import SwiftUI
import Foundation
import Observation

// MARK: - Models
enum OnboardingStepFixed: Int, CaseIterable {
  case welcome = 0
  case howItWorks = 1
  case authentication = 2
  
  var title: String {
    switch self {
    case .welcome: return "Welcome to Cirkl"
    case .howItWorks: return "How It Works"
    case .authentication: return "Choose Connection"
    }
  }
  
  var subtitle: String {
    switch self {
    case .welcome: return "Connecting Authentically, Growing Intelligently"
    case .howItWorks: return "Discover authentic connections through physical proximity"
    case .authentication: return "Verify your identity to join the network"
    }
  }
}

enum AuthenticationTypeFixed: String, CaseIterable {
  case nfc = "NFC"
  case qr = "QR Code"
  case bluetooth = "Bluetooth"
  
  var icon: String {
    switch self {
    case .nfc: return "wave.3.right.circle.fill"
    case .qr: return "qrcode.viewfinder"
    case .bluetooth: return "bluetooth.fill"
    }
  }
  
  var description: String {
    switch self {
    case .nfc: return "Tap devices together for instant connection"
    case .qr: return "Scan QR codes to verify authentic meetings"
    case .bluetooth: return "Connect through proximity detection"
    }
  }
  
  var primaryColor: Color {
    switch self {
    case .nfc: return Color(red: 0.42, green: 0.39, blue: 1.0)      // #6C63FF
    case .qr: return Color(red: 1.0, green: 0.42, blue: 0.42)       // #FF6B6B
    case .bluetooth: return Color(red: 0.30, green: 0.80, blue: 0.77) // #4ECDC4
    }
  }
}

// MARK: - ViewModel
@Observable
@MainActor
class OnboardingViewModelFixed {
  var currentStep: OnboardingStepFixed = .welcome
  var selectedAuthType: AuthenticationTypeFixed?
  var isAnimating = false
  var showOrbitalAnimation = false
  
  var canProceed: Bool {
    switch currentStep {
    case .welcome, .howItWorks: return true
    case .authentication: return selectedAuthType != nil
    }
  }
  
  func nextStep() {
    guard canProceed else { return }
    
    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
      if let nextStep = OnboardingStepFixed(rawValue: currentStep.rawValue + 1) {
        currentStep = nextStep
        
        if currentStep == .howItWorks {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 1.0)) {
              self.showOrbitalAnimation = true
            }
          }
        }
      }
    }
  }
  
  func previousStep() {
    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
      if let prevStep = OnboardingStepFixed(rawValue: currentStep.rawValue - 1) {
        currentStep = prevStep
        showOrbitalAnimation = false
      }
    }
  }
  
  func selectAuthType(_ type: AuthenticationTypeFixed) {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
      selectedAuthType = type
    }
  }
  
  func completeOnboarding() -> AuthenticationTypeFixed? {
    return selectedAuthType
  }
}

// MARK: - Colors
extension Color {
  static let cirklPrimaryFixed = Color(red: 0.42, green: 0.39, blue: 1.0)      // #6C63FF
  static let cirklSecondaryFixed = Color(red: 1.0, green: 0.42, blue: 0.42)    // #FF6B6B
  static let cirklAccentFixed = Color(red: 0.30, green: 0.80, blue: 0.77)      // #4ECDC4
  static let cirklBackgroundFixed = Color(red: 0.04, green: 0.05, blue: 0.15)  // #0A0E27
}

// MARK: - Components
struct GlassmorphicCardFixed<Content: View>: View {
  let content: Content
  
  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }
  
  var body: some View {
    content
      .padding(24)
      .background(
        RoundedRectangle(cornerRadius: 24)
          .fill(.ultraThinMaterial)
          .overlay(
            RoundedRectangle(cornerRadius: 24)
              .stroke(
                LinearGradient(
                  colors: [Color.white.opacity(0.6), Color.clear],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                ),
                lineWidth: 1
              )
          )
      )
      .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
  }
}

// MARK: - Main Onboarding Flow
struct OnboardingFlowFixed: View {
  @State private var viewModel = OnboardingViewModelFixed()
  @State private var showMainApp = false
  
  var body: some View {
    ZStack {
      Color.cirklBackgroundFixed
        .ignoresSafeArea()
      
      VStack {
        OnboardingProgressBarFixed(
          currentStep: viewModel.currentStep.rawValue,
          totalSteps: OnboardingStepFixed.allCases.count
        )
        .padding(.horizontal, 32)
        .padding(.top, 20)
        
        Spacer()
      }
      
      TabView(selection: Binding(
        get: { viewModel.currentStep },
        set: { newValue in
          withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            viewModel.currentStep = newValue
          }
        }
      )) {
        WelcomeScreenFixed()
          .tag(OnboardingStepFixed.welcome)
        
        HowItWorksScreenFixed()
          .tag(OnboardingStepFixed.howItWorks)
        
        AuthenticationScreenFixed()
          .tag(OnboardingStepFixed.authentication)
      }
      .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
      .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.currentStep)
    }
    .environment(viewModel)
  }
}

struct OnboardingProgressBarFixed: View {
  let currentStep: Int
  let totalSteps: Int
  
  var body: some View {
    HStack(spacing: 8) {
      ForEach(0..<totalSteps, id: \.self) { index in
        RoundedRectangle(cornerRadius: 4)
          .fill(
            index <= currentStep 
              ? LinearGradient(
                  colors: [Color.cirklPrimaryFixed, Color.cirklAccentFixed],
                  startPoint: .leading,
                  endPoint: .trailing
                )
              : LinearGradient(
                  colors: [Color.white.opacity(0.3), Color.white.opacity(0.3)],
                  startPoint: .leading,
                  endPoint: .trailing
                )
          )
          .frame(height: 4)
          .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
      }
    }
  }
}

// MARK: - Welcome Screen
struct WelcomeScreenFixed: View {
  @Environment(OnboardingViewModelFixed.self) private var viewModel
  @State private var logoScale: CGFloat = 0.8
  @State private var logoRotation: Double = 0
  @State private var textOpacity: Double = 0
  
  var body: some View {
    VStack(spacing: 40) {
      Spacer()
      
      VStack(spacing: 24) {
        ZStack {
          SwiftUI.Circle()
            .stroke(
              LinearGradient(
                colors: [Color.cirklPrimaryFixed.opacity(0.3), Color.cirklAccentFixed.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              ),
              lineWidth: 3
            )
            .frame(width: 140, height: 140)
            .scaleEffect(logoScale * 1.2)
            .opacity(0.6)
          
          ZStack {
            SwiftUI.Circle()
              .fill(
                LinearGradient(
                  colors: [Color.cirklPrimaryFixed, Color.cirklAccentFixed],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .frame(width: 120, height: 120)
            
            Image(systemName: "circle.grid.3x3.fill")
              .font(.system(size: 60, weight: .light))
              .foregroundColor(.white)
              .rotationEffect(.degrees(logoRotation))
          }
          .scaleEffect(logoScale)
          .shadow(color: Color.cirklPrimaryFixed.opacity(0.4), radius: 20, x: 0, y: 10)
        }
        
        VStack(spacing: 8) {
          Text("Cirkl")
            .font(.system(size: 42, weight: .bold, design: .rounded))
            .foregroundStyle(
              LinearGradient(
                colors: [Color.white, Color.white.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .opacity(textOpacity)
          
          Text("Connecting Authentically, Growing Intelligently")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white.opacity(0.7))
            .multilineTextAlignment(.center)
            .opacity(textOpacity)
            .padding(.horizontal, 40)
        }
      }
      
      Spacer()
      
      GlassmorphicCardFixed {
        HStack {
          Text("Get Started")
            .font(.headline)
            .foregroundColor(.white)
          
          Spacer()
          
          Image(systemName: "arrow.right.circle.fill")
            .font(.title2)
            .foregroundColor(.white)
        }
      }
      .opacity(textOpacity)
      .onTapGesture {
        viewModel.nextStep()
      }
      .padding(.horizontal, 32)
      .padding(.bottom, 50)
    }
    .onAppear {
      startAnimations()
    }
  }
  
  private func startAnimations() {
    withAnimation(.easeInOut(duration: 1.0)) {
      logoScale = 1.0
    }
    
    withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
      logoRotation = 360
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      withAnimation(.easeInOut(duration: 1.0)) {
        textOpacity = 1.0
      }
    }
  }
}

// MARK: - How It Works Screen
struct HowItWorksScreenFixed: View {
  @Environment(OnboardingViewModelFixed.self) private var viewModel
  
  var body: some View {
    VStack(spacing: 40) {
      VStack(spacing: 16) {
        Text("How Cirkl Works")
          .font(.system(size: 32, weight: .bold))
          .foregroundColor(.white)
        
        Text("Discover authentic connections through physical proximity")
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(.white.opacity(0.7))
          .multilineTextAlignment(.center)
          .padding(.horizontal, 40)
      }
      .padding(.top, 60)
      
      Spacer()
      
      VStack(spacing: 20) {
        FeatureRowFixed(
          icon: "checkmark.shield.fill",
          title: "100% Authentic",
          description: "Physical verification ensures zero fake profiles",
          color: Color.cirklPrimaryFixed
        )
        
        FeatureRowFixed(
          icon: "location.fill",
          title: "Proximity Based",
          description: "Connect only with people you actually meet",
          color: Color.cirklSecondaryFixed
        )
        
        FeatureRowFixed(
          icon: "brain.head.profile",
          title: "AI Powered",
          description: "Smart matching based on real interactions",
          color: Color.cirklAccentFixed
        )
      }
      .padding(.horizontal, 32)
      
      Spacer()
      
      HStack(spacing: 16) {
        Button(action: { viewModel.previousStep() }) {
          GlassmorphicCardFixed {
            HStack {
              Image(systemName: "arrow.left.circle.fill")
                .font(.title2)
                .foregroundColor(.white)
              Text("Back")
                .font(.headline)
                .foregroundColor(.white)
            }
          }
        }
        
        Button(action: { viewModel.nextStep() }) {
          GlassmorphicCardFixed {
            HStack {
              Text("Continue")
                .font(.headline)
                .foregroundColor(.white)
              Spacer()
              Image(systemName: "arrow.right.circle.fill")
                .font(.title2)
                .foregroundColor(.white)
            }
          }
        }
      }
      .padding(.horizontal, 32)
      .padding(.bottom, 50)
    }
  }
}

struct FeatureRowFixed: View {
  let icon: String
  let title: String
  let description: String
  let color: Color
  
  var body: some View {
    HStack(spacing: 16) {
      ZStack {
        SwiftUI.Circle()
          .fill(color.opacity(0.2))
          .frame(width: 44, height: 44)
        
        Image(systemName: icon)
          .font(.system(size: 20))
          .foregroundColor(color)
      }
      
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(.white)
        
        Text(description)
          .font(.system(size: 14))
          .foregroundColor(.white.opacity(0.7))
      }
      
      Spacer()
    }
  }
}

// MARK: - Authentication Screen
struct AuthenticationScreenFixed: View {
  @Environment(OnboardingViewModelFixed.self) private var viewModel
  
  var body: some View {
    VStack(spacing: 32) {
      VStack(spacing: 16) {
        Text("Choose Your Connection")
          .font(.system(size: 32, weight: .bold))
          .foregroundColor(.white)
        
        Text("Select how you'd like to verify authentic meetings")
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(.white.opacity(0.7))
          .multilineTextAlignment(.center)
          .padding(.horizontal, 40)
      }
      .padding(.top, 60)
      
      VStack(spacing: 20) {
        ForEach(AuthenticationTypeFixed.allCases, id: \.self) { authType in
          AuthenticationCardFixed(
            type: authType,
            isSelected: viewModel.selectedAuthType == authType
          ) {
            viewModel.selectAuthType(authType)
          }
        }
      }
      .padding(.horizontal, 24)
      
      Spacer()
      
      HStack(spacing: 16) {
        Button(action: { viewModel.previousStep() }) {
          GlassmorphicCardFixed {
            HStack {
              Image(systemName: "arrow.left.circle.fill")
                .font(.title2)
                .foregroundColor(.white)
              Text("Back")
                .font(.headline)
                .foregroundColor(.white)
            }
          }
        }
        
        Button(action: {
          if let _ = viewModel.completeOnboarding() {
            // Complete onboarding
            print("Onboarding completed!")
          }
        }) {
          GlassmorphicCardFixed {
            HStack {
              Text("Get Started")
                .font(.headline)
                .foregroundColor(.white)
              Spacer()
              Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.white)
            }
          }
        }
        .disabled(!viewModel.canProceed)
        .opacity(viewModel.canProceed ? 1.0 : 0.5)
      }
      .padding(.horizontal, 32)
      .padding(.bottom, 50)
    }
  }
}

struct AuthenticationCardFixed: View {
  let type: AuthenticationTypeFixed
  let isSelected: Bool
  let onTap: () -> Void
  
  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 20) {
        ZStack {
          SwiftUI.Circle()
            .fill(
              LinearGradient(
                colors: [
                  type.primaryColor.opacity(isSelected ? 1.0 : 0.3),
                  type.primaryColor.opacity(isSelected ? 0.8 : 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(width: 60, height: 60)
          
          Image(systemName: type.icon)
            .font(.system(size: 28))
            .foregroundColor(.white)
        }
        
        VStack(alignment: .leading, spacing: 6) {
          Text(type.rawValue)
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.white)
          
          Text(type.description)
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.7))
            .multilineTextAlignment(.leading)
        }
        
        Spacer()
        
        ZStack {
          SwiftUI.Circle()
            .stroke(Color.white.opacity(0.3), lineWidth: 2)
            .frame(width: 24, height: 24)
          
          if isSelected {
            SwiftUI.Circle()
              .fill(type.primaryColor)
              .frame(width: 16, height: 16)
              .overlay(
                Image(systemName: "checkmark")
                  .font(.system(size: 10, weight: .bold))
                  .foregroundColor(.white)
              )
          }
        }
      }
      .padding(24)
      .background(
        RoundedRectangle(cornerRadius: 24)
          .fill(.ultraThinMaterial)
          .overlay(
            RoundedRectangle(cornerRadius: 24)
              .stroke(
                LinearGradient(
                  colors: isSelected 
                    ? [type.primaryColor.opacity(0.8), type.primaryColor.opacity(0.4)]
                    : [Color.white.opacity(0.6), Color.clear],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                ),
                lineWidth: isSelected ? 2 : 1
              )
          )
      )
      .shadow(
        color: isSelected 
          ? type.primaryColor.opacity(0.3)
          : Color.black.opacity(0.15),
        radius: isSelected ? 25 : 20,
        x: 0,
        y: 10
      )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

#Preview {
  OnboardingFlowFixed()
}
