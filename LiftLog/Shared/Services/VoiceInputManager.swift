//
//  VoiceInputManager.swift
//  LiftLog
//
//  Created by Claude on 2/20/26.
//

import Foundation
import Speech
import AVFoundation

/// Manages voice input using iOS Speech Recognition
class VoiceInputManager: ObservableObject {
    static let shared = VoiceInputManager()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    @Published var isRecording = false
    @Published var transcript = ""
    
    private var completion: ((Result<String, Error>) -> Void)?
    
    enum VoiceInputError: LocalizedError {
        case notAuthorized
        case notAvailable
        case audioSessionError
        case recognitionFailed
        
        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Speech recognition not authorized. Please enable in Settings."
            case .notAvailable:
                return "Speech recognition is not available on this device."
            case .audioSessionError:
                return "Could not set up audio session."
            case .recognitionFailed:
                return "Speech recognition failed. Please try again."
            }
        }
    }
    
    private init() {}
    
    // MARK: - Public API
    
    func startRecording(completion: @escaping (Result<String, Error>) -> Void) {
        self.completion = completion
        
        // Request authorization
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self?.startRecognition()
                case .denied, .restricted:
                    completion(.failure(VoiceInputError.notAuthorized))
                case .notDetermined:
                    completion(.failure(VoiceInputError.notAuthorized))
                @unknown default:
                    completion(.failure(VoiceInputError.notAuthorized))
                }
            }
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        isRecording = false
        
        // Return final transcript
        if !transcript.isEmpty {
            completion?(.success(transcript))
        }
        
        transcript = ""
        recognitionRequest = nil
        recognitionTask = nil
    }
    
    // MARK: - Private
    
    private func startRecognition() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            completion?(.failure(VoiceInputError.notAvailable))
            return
        }
        
        // Cancel any ongoing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            completion?(.failure(VoiceInputError.audioSessionError))
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            completion?(.failure(VoiceInputError.recognitionFailed))
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || result?.isFinal == true {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                
                DispatchQueue.main.async {
                    self.isRecording = false
                    
                    if let error = error {
                        // Only report error if we don't have a transcript
                        if self.transcript.isEmpty {
                            self.completion?(.failure(error))
                        } else {
                            self.completion?(.success(self.transcript))
                        }
                    } else if result?.isFinal == true {
                        self.completion?(.success(self.transcript))
                    }
                    
                    self.transcript = ""
                }
            }
        }
        
        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isRecording = true
            }
        } catch {
            completion?(.failure(VoiceInputError.audioSessionError))
        }
    }
}
