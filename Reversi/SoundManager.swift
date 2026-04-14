import AVFoundation

class SoundManager: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = SoundManager()

    private let synthesizer = AVSpeechSynthesizer()
    private var onFinish: (() -> Void)?

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish?()
        onFinish = nil
    }
    
    /// Speaks the emoji name when tapped in picker
    func speakEmoji(_ piece: PieceOption) {
        guard GameSettings.shared.soundEnabled else { return }
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let name = piece.unicodeName
        guard !name.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: name)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.8
        utterance.pitchMultiplier = 1.2
        utterance.volume = 0.8
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
    
    /// Speaks the piece name when placed
    func speakPiece(_ piece: PieceOption) {
        guard GameSettings.shared.soundEnabled else { return }
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let name = piece.unicodeName
        guard !name.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: name)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.8
        utterance.pitchMultiplier = 1.3
        utterance.volume = 0.8
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
    
    /// Speaks the winner announcement
    func speakWinner(_ piece: PieceOption) {
        guard GameSettings.shared.soundEnabled else { return }
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: "\(piece.emoji) wins!")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.7
        utterance.pitchMultiplier = 1.2
        utterance.volume = 1.0
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
    
    /// Speaks arbitrary text with a completion callback
    func speakText(_ text: String, completion: (() -> Void)? = nil) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        onFinish = completion
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.7
        utterance.pitchMultiplier = 1.1
        utterance.volume = 0.9
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }

    /// Stop any current speech
    func stop() {
        onFinish = nil
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
