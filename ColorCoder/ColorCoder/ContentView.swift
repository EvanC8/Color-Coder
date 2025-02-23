//
//  ContentView.swift
//  ColorCoder
//
//  Created by Evan Cedeno on 12/2/24.
//

import SwiftUI
import CoreML

struct ContentView: View {
    
    // Camera Adjustments
    @State var torch: Bool = false
    
    // Image Capturing
    let cameraService = CameraService()
    @State var capturedImage: UIImage? = nil
    @State var croppedImage: UIImage? = nil
    
    @State var showImageView: Bool = false
    @State var showImage: Bool = false
    
    // Animations
    @State var animatePointer: Bool = false
    
    var body: some View {
        //MARK: MAIN VIEW
        // Z-Layered layout
        ZStack {
            CameraView(torch: $torch, cameraService: cameraService, capturedImage: $capturedImage, croppedImage: $croppedImage, showImageView: $showImageView, showImage: $showImage, animatePointer: $animatePointer)
            
            CaptureImageView(torch: $torch, cameraService: cameraService, capturedImage: $capturedImage, croppedImage: $croppedImage, showImageView: $showImageView, animatePointer: $animatePointer)
            

            UIOverlay(torch: $torch, cameraService: cameraService, capturedImage: $capturedImage, croppedImage: $croppedImage, showImageView: $showImageView, showImage: $showImage, animatePointer: $animatePointer)
        }
        .ignoresSafeArea()
        .onAppear {
            //MARK: On Appear            
        }
    }
    
}
