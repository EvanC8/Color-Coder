//
//  CameraView.swift
//  ColorCoder
//
//  Created by Evan Cedeno on 12/29/24.
//

import SwiftUI

// MARK: Camera View
struct CameraView: View {
    // Camera Adjustments
    @Binding var torch: Bool
    
    // Image Capturing
    let cameraService: CameraService
    @Binding var capturedImage: UIImage?
    @Binding var croppedImage: UIImage?
    
    @Binding var showImageView: Bool
    @Binding var showImage: Bool
    
    // Animations
    @Binding var animatePointer: Bool
    
    var body: some View {
        //MARK: Camera Preview
        if !showImageView {
            CameraViewController(torch: $torch, cameraService: cameraService) { result in
                switch result {
                case .success(let photo):
                    if let data = photo.fileDataRepresentation() {
                        capturedImage = UIImage(data: data)
                        croppedImage = processCapturedImage(capturedImage!)
                        showImageView = true
                        torch = false
                        cameraService.toggleTorch(torch)
                    } else {
                        print("Error: No image data found")
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    
                }
            }
            .ignoresSafeArea()
            .onTapGesture {
                // Animate pointer
                if !animatePointer {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        animatePointer = true
                    } completion: {
                        withAnimation(.bouncy(duration: 0.5, extraBounce: 0.25).delay(0.25)) {
                            animatePointer = false
                        }
                    }
                }
            }
        }
            
    }
    
    //MARK: Process Captured Image
    func processCapturedImage(_ image: UIImage) -> UIImage? {
        let cgImage = image.cgImage!
        
        let unitToPixelMultiplier = CGFloat(cgImage.width) / CGFloat(UIScreen.main.bounds.height)
        
        let cursorCenterVertical: CGFloat = CGFloat(230)
        
        let croppedCenter = CGPoint(x: cursorCenterVertical * unitToPixelMultiplier, y: CGFloat(cgImage.height / 2))
        
        let boxLength = 50 * unitToPixelMultiplier
        let croppedRect = CGRect(x: croppedCenter.x - boxLength/2, y: croppedCenter.y - boxLength/2, width: boxLength, height: boxLength)
        
        if let croppedImage = cgImage.cropping(to: croppedRect) {            
            return UIImage(cgImage: croppedImage, scale: image.scale, orientation: image.imageOrientation)
        }
        else {
            return nil
        }
    }
}

