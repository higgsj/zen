import Foundation
import AVFoundation
import UIKit

class AudioHapticManager: ObservableObject {
    // MARK: - Properties
    @Published var isMeditationMusicEnabled = true
    @Published var isVoicePromptsEnabled = true
    @Published var isHapticsEnabled = true
    @Published var meditationTrack: MeditationTrack = .track1
    @Published var meditationVolume: Float = 0.7
    @Published var voicePromptVolume: Float = 1.0
    
    private var meditationPlayer: AVAudioPlayer?
    private var voicePromptPlayer: AVAudioPlayer?
    private var audioSession: AVAudioSession
    
    enum MeditationTrack: String, CaseIterable, Codable {
        case none = "None"
        case track1 = "meditative-texture-1"
        case track2 = "meditative-texture-2"
    }
    
    enum HapticStyle {
        case light
        case medium
        case heavy
        case success
        case error
        case selection
    }
    
    // MARK: - Initialization
    init() {
        self.audioSession = AVAudioSession.sharedInstance()
        setupAudioSession()
        loadSettings()
        
        // Add notification observers for audio interruptions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            // First deactivate the session
            try audioSession.setActive(false)
            
            // Then set the category and activate
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .allowAirPlay, .duckOthers]
            )
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
            // Print more detailed error information
            if let nsError = error as NSError? {
                print("Error domain: \(nsError.domain)")
                print("Error code: \(nsError.code)")
                print("User info: \(nsError.userInfo)")
            }
        }
    }
    
    // Add a method to ensure audio session is active before playing
    private func ensureAudioSessionActive() {
        do {
            if !audioSession.isOtherAudioPlaying {
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            } else {
                // If other audio is playing, we'll need to handle it appropriately
                setupAudioSession()
            }
        } catch {
            print("Failed to activate audio session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Meditation Music Control
    func startMeditationMusic() {
        guard isMeditationMusicEnabled, meditationTrack != .none else { return }
        
        // Ensure audio session is active before playing
        ensureAudioSessionActive()
        
        if let path = Bundle.main.path(forResource: meditationTrack.rawValue, ofType: "mp3") {
            do {
                meditationPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                meditationPlayer?.numberOfLoops = -1 // Loop indefinitely
                meditationPlayer?.volume = meditationVolume
                meditationPlayer?.play()
            } catch {
                print("Failed to play meditation music: \(error)")
            }
        }
    }
    
    func stopMeditationMusic() {
        meditationPlayer?.stop()
        meditationPlayer = nil
    }
    
    // MARK: - Voice Prompts
    func playVoicePrompt(_ prompt: String) {
        guard isVoicePromptsEnabled else { return }
        
        // Ensure audio session is active before playing
        ensureAudioSessionActive()
        
        // Map the phase names to voice prompt filenames
        let promptFileName: String
        switch prompt.lowercased() {
        case "inhale", "hold inhale":
            promptFileName = "inhale"
        case "exhale", "hold exhale":
            promptFileName = "exhale"
        case "hold":
            promptFileName = "hold"
        case "squeeze":
            promptFileName = "squeeze"
        case "relax":
            promptFileName = "relax"
        default:
            promptFileName = prompt.lowercased().replacingOccurrences(of: " ", with: "-")
        }
        
        if let path = Bundle.main.path(forResource: promptFileName, ofType: "mp3") {
            do {
                voicePromptPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                voicePromptPlayer?.volume = voicePromptVolume
                voicePromptPlayer?.play()
            } catch {
                print("Failed to play voice prompt: \(error)")
            }
        } else {
            print("Voice prompt file not found: \(promptFileName).mp3")
        }
    }
    
    // MARK: - Haptic Feedback
    func playHaptic(_ style: HapticStyle) {
        guard isHapticsEnabled else { return }
        
        switch style {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
    
    // MARK: - Audio Session Interruption Handling
    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Audio session interrupted (e.g., phone call)
            stopMeditationMusic()
            
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            
            // Check if we should resume playback
            if options.contains(.shouldResume) {
                // Wait a short moment before resuming
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.startMeditationMusic()
                }
            }
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Settings Management
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "audioHapticSettings"),
           let settings = try? JSONDecoder().decode(AudioHapticSettings.self, from: data) {
            self.isMeditationMusicEnabled = settings.isMeditationMusicEnabled
            self.isVoicePromptsEnabled = settings.isVoicePromptsEnabled
            self.isHapticsEnabled = settings.isHapticsEnabled
            self.meditationTrack = settings.meditationTrack
            self.meditationVolume = settings.meditationVolume
            self.voicePromptVolume = settings.voicePromptVolume
        }
    }
    
    func saveSettings() {
        let settings = AudioHapticSettings(
            isMeditationMusicEnabled: isMeditationMusicEnabled,
            isVoicePromptsEnabled: isVoicePromptsEnabled,
            isHapticsEnabled: isHapticsEnabled,
            meditationTrack: meditationTrack,
            meditationVolume: meditationVolume,
            voicePromptVolume: voicePromptVolume
        )
        
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "audioHapticSettings")
        }
    }
}

// MARK: - Supporting Types
struct AudioHapticSettings: Codable {
    var isMeditationMusicEnabled: Bool
    var isVoicePromptsEnabled: Bool
    var isHapticsEnabled: Bool
    var meditationTrack: AudioHapticManager.MeditationTrack
    var meditationVolume: Float
    var voicePromptVolume: Float
} 