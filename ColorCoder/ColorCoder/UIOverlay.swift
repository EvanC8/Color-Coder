//
//  UIOverlay.swift
//  ColorCoder
//
//  Created by Evan Cedeno on 12/29/24.
//

import SwiftUI

struct UIOverlay: View {
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
    
    // PRIVATE ANIMATORS
    @State var fadeOutView: Bool = false
    
    var body: some View {
        VStack {
            let color = Color(UIColor(red: 215/255, green: 0/255, blue: 64/255, alpha: 1))
            
            if !fadeOutView {
                //MARK: POINTER
                ZStack {
                    Image(systemName: "chevron.up.chevron.right.chevron.down.chevron.left")
                        .rotationEffect(Angle(degrees: 45))
                        .foregroundStyle(.white.opacity(animatePointer ? 1 : 0.75))
                        .font(.system(size: 75, weight: .thin))
                        .frame(width: 60, height: 60)
                        .scaleEffect(animatePointer ? 1.2 : 1)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.7).delay(0.5)) {
                                animatePointer = true
                            } completion: {
                                withAnimation(.bouncy(duration: 0.6, extraBounce: 0.25).delay(0.25)) {
                                    animatePointer = false
                                }
                            }
                        }
                    
                    Image(systemName: "plus")
                        .foregroundStyle(.white)
                        .font(.system(size: 23, weight: .thin))
                }
                .frame(height: 60)
                .transition(.opacity)
                .padding(.top, 200)
            }
            
            Spacer()
            
            //MARK: FOOTER CONTROLS
            if !fadeOutView {
                ZStack {
                    HStack(spacing: 100) {
                        HStack {
                            Spacer()
                            // Select library image button
//                            Image(systemName: "paintpalette.fill")
//                                .foregroundStyle(.white)
//                                .font(.system(size: 28, weight: .regular))
//                                .frame(width: 70, height: 70)
//                                .contentShape(Rectangle())
//                                .onTapGesture {
//                                    
//                                }
                            Spacer()
                        }
                        HStack {
                            Spacer()
                            // Toggle torch button
                            Image(systemName: "bolt.\(torch ? "slash." : "")fill")
                                .foregroundStyle(.white)
                                .font(.system(size: 28, weight: .regular))
                                .frame(width: 70, height: 70)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    torch.toggle()
                                    cameraService.toggleTorch(torch)
                                }
                            Spacer()
                        }
                    }
                    
                    // Capture photo button
                    ZStack {
                        Circle()
                            .stroke(color.opacity(0.5), lineWidth: 4)
    //                            .stroke(color.opacity(0.5), style: StrokeStyle(lineWidth: 4, dash: [1.5], dashPhase: 4))
                        Circle()
                            .fill(color.opacity(0.97))
                            .padding(4.5)
                    }
                    .frame(width: 75, height: 75)
                    .contentShape(Circle())
                    .onTapGesture {
                        cameraService.capturePhoto()
                    }
                }
                .frame(height: 100)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 50)
            }
        }
        .safeAreaPadding(.bottom)
        .onChange(of: showImageView) { oldValue, newValue in
            withAnimation {
                fadeOutView = newValue
            }
        }
    }
}

