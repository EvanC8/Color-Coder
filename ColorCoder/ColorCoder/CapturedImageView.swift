//
//  CapturedImageView.swift
//  ColorCoder
//
//  Created by Evan Cedeno on 12/29/24.
//

import SwiftUI
import UIKit

struct CaptureImageView: View {
    // Camera Adjustments
    @Binding var torch: Bool
    
    // Image Capturing
    let cameraService: CameraService
    @Binding var capturedImage: UIImage?
    @Binding var croppedImage: UIImage?
    
    @Binding var showImageView: Bool
    
    // Animations
    @Binding var animatePointer: Bool
    
    // PRIVATE ANIMATORS
    @State var whiteFade = false
    @State var showCroppedImage = false
    @State var showStats = false
    @State var showExit = false
    
    @State var pickerPosition: CGSize = .zero
    @State var pickerOffset: CGSize = .zero
    @State var pickerColor: UIColor = .clear
    
    @State var statColor: UIColor = .clear
    
    
    var body: some View {
        //MARK: CAPTURED IMAGE
        ZStack {
            if showImageView {
                Image(uiImage: capturedImage!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .ignoresSafeArea()
                    .onAppear {
                        withAnimation {
                            whiteFade = true
                        } completion: {
                            withAnimation {
                                showCroppedImage = true
                            } completion: {
                                withAnimation {
                                    showStats = true
                                } completion: {
                                    withAnimation {
                                        showExit = true
                                    }
                                }
                            }
                        }
                    }
            }
            
            if whiteFade {
                Color.white.opacity(0.5)
                    .transition(.opacity)
            }
            
            VStack {
                if showCroppedImage {
                    ZStack {
                        Rectangle()
                            .fill(.white)
                            .aspectRatio(1.0, contentMode: .fit)
                            .padding(15)
                            .padding(.top, (UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0) + 10)
                        
                        Image(uiImage: croppedImage!)
                            .resizable()
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay {
                                GeometryReader { geometry in
                                    ZStack {
                                        Circle()
                                            .fill(Color(uiColor: pickerColor))
                                        Circle()
                                            .stroke(Color.white, style: StrokeStyle(lineWidth: 5))
                                            .shadow(color: Color.gray.opacity(0.5), radius: 1)
                                    }
                                    .frame(width: 50, height: 50)
                                    .position(x: pickerPosition.width + pickerOffset.width, y: pickerPosition.height + pickerOffset.height - 5 - 25 - 10)
                                    Circle()
                                        .fill(Color.white)
                                        .shadow(color: Color.gray.opacity(0.5), radius: 1)
                                        .frame(width: 10, height: 10)
                                        .position(x: pickerPosition.width + pickerOffset.width, y: pickerPosition.height + pickerOffset.height)
                                        .onAppear {
                                            pickerPosition = CGSize(width: geometry.size.width / 2, height: geometry.size.height / 2)
                                            pickerColor = getColor(from: croppedImage!, at: CGPoint(x: pickerPosition.width, y: pickerPosition.height))
                                            statColor = pickerColor
                                        }
                                }
                            }
                            .gesture(
                                DragGesture()
                                    .onChanged({ gesture in
                                        pickerOffset = gesture.translation
                                        
                                        let x = pickerPosition.width + pickerOffset.width
                                        let y = pickerPosition.height + pickerOffset.height
                                        let length = UIScreen.main.bounds.width - 40
                                        
                                        if x < 0 {
                                            pickerOffset.width = -pickerPosition.width
                                        }
                                        else if x > length {
                                            pickerOffset.width = length - pickerPosition.width
                                        }
                                        
                                        if y < 0 {
                                            pickerOffset.height = -pickerPosition.height
                                        }
                                        else if y > length {
                                            pickerOffset.height = length - pickerPosition.height
                                        }
                                        
                                        let coord = CGPoint(x: pickerPosition.width + pickerOffset.width, y: pickerPosition.height + pickerOffset.height)
                                        pickerColor = getColor(from: croppedImage!, at: coord)
                                    })
                                    .onEnded({ gesture in
                                        withAnimation {
                                            pickerPosition.width += pickerOffset.width
                                            pickerPosition.height += pickerOffset.height
                                            pickerOffset = .zero
                                        } completion: {
                                            pickerColor = getColor(from: croppedImage!, at: CGPoint(x: pickerPosition.width, y: pickerPosition.height))
                                            
                                            withAnimation {
                                                showStats = false
                                            } completion: {
                                                statColor = pickerColor
                                                withAnimation {
                                                    showStats = true
                                                }
                                            }
                                        }
                                    })
                            )
                            .padding(20)
                            .padding(.top, (UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0) + 10)
                        
                    }
                    .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
                }
                
                if showStats {
                    ColorStatView(statColor: statColor)
                        .padding(.horizontal, 15)
                }
                
                Spacer()
                
                if showExit {
                    ZStack {
                        Circle()
                            .frame(width: 75, height: 75)
                            .foregroundColor(Color.white)
                        
                        Image(systemName: "camera")
                            .foregroundStyle(.white)
                            .font(.system(size: 38, weight: .medium))
                            .blendMode(.destinationOut)
                            .frame(width: 75, height: 75)
                    }
                    .compositingGroup()
                    .frame(width: 75, height: 75)
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showExit = false
                            showStats = false
                            showCroppedImage = false
                        } completion: {
                            whiteFade = false
                            showImageView = false
                        }
                    }
                    .safeAreaPadding(.bottom)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    func getColor(from uiImage: UIImage, at loc: CGPoint) -> UIColor {
        guard let image = uiImage.cgImage else { return .black }

        guard let context = createBitmapContext() else { return .black }

        guard let pixelData = extractPixelData(at: loc, from: image, with: context) else { return .black }

        return colorFromPixelData(pixelData)
    }

    private func createBitmapContext() -> CGContext? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerRow = 4
        let bitsPerComponent = 8
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        // Allocate memory for the pixel data
        let pixelData = UnsafeMutablePointer<UInt8>.allocate(capacity: 4)
        pixelData.initialize(repeating: 0, count: 4)

        return CGContext(
            data: pixelData,
            width: 1,
            height: 1,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        )
    }

    private func extractPixelData(at loc: CGPoint, from image: CGImage, with context: CGContext) -> [UInt8]? {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)

        let screenWidth = UIScreen.main.bounds.width
        let scaledWidth = screenWidth - 40
        let multiplier = height / scaledWidth

        let pixelY = loc.x * multiplier
        let pixelX = loc.y * multiplier

        // Ensure the point is within bounds
        guard pixelX >= 0 && pixelX < width && pixelY >= 0 && pixelY < height else {
            return nil
        }

        // Draw the image in the context
        context.translateBy(x: -pixelX, y: -pixelY)
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Copy pixel data from the context
        guard let data = context.data else { return nil }

        // Access the data safely and extract pixel values
        let buffer = data.assumingMemoryBound(to: UInt8.self)
        let red = buffer[0]
        let green = buffer[1]
        let blue = buffer[2]
        let alpha = buffer[3]

        return [red, green, blue, alpha]
    }

    private func colorFromPixelData(_ pixelData: [UInt8]) -> UIColor {
        let red = CGFloat(pixelData[0]) / 255.0
        let green = CGFloat(pixelData[1]) / 255.0
        let blue = CGFloat(pixelData[2]) / 255.0
        let alpha = CGFloat(pixelData[3]) / 255.0

        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

}
