//
//  AIFeatures.swift
//  ADG2025
//
//  Created by Rachit Tibrewal on 16/09/25.
//

import SwiftUI
import CoreML
import Vision
import UIKit

struct AIFeatures: View {
    @State private var showCamera = false
    @State private var showGallery = false
    @State private var selectedImage: UIImage?
    @State private var prediction: String = "Take or upload a photo to identify the monument"
    
    var body: some View {
        VStack(spacing: 20) {
            // Show captured/selected photo
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .overlay(Text("No image selected"))
                    .cornerRadius(12)
            }
            
            // Show prediction
            Text(prediction)
                .font(.headline)
                .padding()
                .multilineTextAlignment(.center)
            
            // Buttons for Camera and Gallery
            HStack {
                // Camera Button
                Button(action: { showCamera = true }) {
                    Label("Open Camera", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                // Gallery Button
                Button(action: { showGallery = true }) {
                    Label("Choose Photo", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            
            // 🔹 Sample Image Button (from Assets.xcassets)
            Button("Use Sample Image") {
                if let sample = UIImage(named: "tajmahal") { // make sure "tajmahal" exists in Assets
                    selectedImage = sample
                    classifyImage(sample)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding()
        .navigationTitle("AI Monument Scanner")
        // Camera picker
        .sheet(isPresented: $showCamera) {
            CameraPicker(selectedImage: $selectedImage, onImagePicked: classifyImage)
        }
        // Gallery picker
        .sheet(isPresented: $showGallery) {
            GalleryPicker(selectedImage: $selectedImage, onImagePicked: classifyImage)
        }
    }
    
    // 🔹 ML Part: Run Core ML model on captured/selected image
    private func classifyImage(_ image: UIImage) {
        guard let ciImage = CIImage(image: image) else { return }
        
        do {
            let model = try VNCoreMLModel(for: MonumentClassifier(configuration: MLModelConfiguration()).model)
            let request = VNCoreMLRequest(model: model) { request, _ in
                if let results = request.results as? [VNClassificationObservation],
                   let topResult = results.first {
                    DispatchQueue.main.async {
                        self.prediction = "This looks like \(topResult.identifier)\nConfidence: \(Int(topResult.confidence * 100))%"
                    }
                }
            }
            let handler = VNImageRequestHandler(ciImage: ciImage)
            try handler.perform([request])
        } catch {
            print("Error running model: \(error.localizedDescription)")
        }
    }
}

// MARK: - Camera Picker
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var onImagePicked: (UIImage) -> Void
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onImagePicked(image)   // 🔹 ML call here
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// MARK: - Gallery Picker
struct GalleryPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var onImagePicked: (UIImage) -> Void
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: GalleryPicker
        init(_ parent: GalleryPicker) { self.parent = parent }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onImagePicked(image)   // 🔹 ML call here
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
