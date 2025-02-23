//
//  CameraViewController.swift
//  ColorCoder
//
//  Created by Evan Cedeno on 12/25/24.
//

import UIKit
import SwiftUI
import AVFoundation

class CameraService {
    
    var session: AVCaptureSession?
    var delegate: AVCapturePhotoCaptureDelegate?
    
    var output = AVCapturePhotoOutput()
    var videoDevice: AVCaptureDevice?
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    var sessionQueue = DispatchQueue(label: "videoQueue")
    
    func start(delegate: AVCapturePhotoCaptureDelegate, completion: @escaping (Error?) -> ()) {
        self.delegate = delegate
        checkPermissions(completion: completion)
    }
    
    private func checkPermissions(completion: @escaping (Error?) -> ()) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else { return }
                DispatchQueue.main.async {
                    self?.setupCamera(completion: completion)
                }
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            setupCamera(completion: completion)
        @unknown default:
            break
        }
    }
    
    private func setupCamera(completion: @escaping (Error?) -> ()) {
        let session = AVCaptureSession()
        if let device = AVCaptureDevice.default(for: .video) {
            do {
                self.videoDevice = device
                configureCamera()
                let input = try AVCaptureDeviceInput(device: device)
                
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                
                if !session.canAddOutput(output) {
                    session.removeOutput(output)
                    
                    output = AVCapturePhotoOutput()
                }
                
                if session.canAddOutput(output) {
                    session.addOutput(output)
                }
                
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session
                
                session.startRunning()
                self.session = session
            } catch {
                completion(error)
            }
        }
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        output.setPreparedPhotoSettingsArray([settings]) { (suc: Bool, err: Error?) -> Void in
            if suc {
                self.output.capturePhoto(with: settings, delegate: self.delegate!)
            }
        }
    }
    
    //MARK: CAMERA CONFIG
    func configureCamera() {
        do {
            try self.videoDevice!.lockForConfiguration()
            
            self.videoDevice!.videoZoomFactor = 1.0
            
            if self.videoDevice!.hasTorch {
                self.videoDevice!.torchMode = .off
            }
            
            self.videoDevice!.unlockForConfiguration()
        } catch {
            print("Unable to configure device camera")
        }
    }
    
    //MARK: CAMERA TORCH TOGGLE
    func toggleTorch(_ on: Bool? = nil) {
        if self.videoDevice == nil { return }
        
        do {
            try self.videoDevice!.lockForConfiguration()
            
            if self.videoDevice!.hasTorch {
                if on == nil {
                    if self.videoDevice!.torchMode == .on {
                        self.videoDevice!.torchMode = .off
                    } else if self.videoDevice!.torchMode == .off {
                        try self.videoDevice!.setTorchModeOn(level: 1.0)
                    }
                } else {
                    if on! == true {
                        try self.videoDevice!.setTorchModeOn(level: 1.0)
                    }
                    else if on! == false {
                        self.videoDevice!.torchMode = .off
                    }
                }
            }
            
            self.videoDevice!.unlockForConfiguration()
        } catch {
            print("Unable to configure camera flash")
        }
    }
}

//MARK: VIEW REPRESENTABLE
struct CameraViewController: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController
    
    @Binding var torch: Bool
    
    let cameraService: CameraService
    let didFinishProcessingPhoto: (Result<AVCapturePhoto, Error>) -> ()
    
    func makeUIViewController(context: Context) -> UIViewController {
        cameraService.start(delegate: context.coordinator) { err in
            if let err = err {
                didFinishProcessingPhoto(.failure(err))
                return
            }
        }
        
        let viewController = UIViewController()
        viewController.view.backgroundColor = .black
        viewController.view.layer.addSublayer(cameraService.previewLayer)
        cameraService.previewLayer.frame = viewController.view.bounds
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // nothing
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, didFinishProcessingPhoto: didFinishProcessingPhoto)
    }
    
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        let parent: CameraViewController
        private var didFinishProcessingPhoto: (Result<AVCapturePhoto, Error>) -> ()
        
        init(_ parent: CameraViewController, didFinishProcessingPhoto: @escaping (Result<AVCapturePhoto, Error>) -> ()) {
            self.parent = parent
            self.didFinishProcessingPhoto = didFinishProcessingPhoto
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
            if let error = error {
                didFinishProcessingPhoto(.failure(error))
                return
            }
            didFinishProcessingPhoto(.success(photo))
        }
        
    }
}












//class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoOutput  {
//    private var permissionGranted: Bool = false
//    private var videoDevice: AVCaptureDevice! = nil
//    private var photoOutput: AVCapturePhotoOutput! = AVCapturePhotoOutput()
//    private let captureSession = AVCaptureSession()
//    private let sessionQueue = DispatchQueue(label: "sessionQueue")
//    var previewLayer = AVCaptureVideoPreviewLayer()
//    var screenRect: CGRect! = nil
//    
//    var onImageCapture: ((UIImage?) -> Void)?
//    var isCapturingFrame = false
//    
//    //MARK: VIEW DID LOAD
//    override func viewDidLoad() {
//        checkPermission()
//        
//        sessionQueue.async {
//            guard self.permissionGranted else { return }
//            self.setupCaptureSession()
//
//            self.captureSession.startRunning()
//            
//            self.configureCamera()
//        }
//    }
//    
//    //MARK: CHECK PERMISSIONS
//    func checkPermission() {
//        switch AVCaptureDevice.authorizationStatus(for: .video) {
//        case .authorized:
//            permissionGranted = true
//        
//        case .notDetermined:
//            requestPermission()
//        
//        default:
//            permissionGranted = false
//        }
//    }
//    
//    //MARK: ASK PERMISSION
//    func requestPermission() {
//        sessionQueue.suspend()
//        AVCaptureDevice.requestAccess(for: .video, completionHandler: { [unowned self] granted in
//            self.permissionGranted = granted
//            self.sessionQueue.resume()
//        })
//    }
//    
//    //MARK: SETUP CAPTURE SESSION
//    func setupCaptureSession() {
//        self.videoDevice = AVCaptureDevice.default(for: .video)
//        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
//        
//        guard captureSession.canAddInput(videoDeviceInput) else { return }
//        captureSession.addInput(videoDeviceInput)
//        
//        let output = AVCaptureVideoDataOutput()
//        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
//        output.setSampleBufferDelegate(self, queue: sessionQueue)
//        captureSession.addOutput(output)
//        
//        captureSession.commitConfiguration()
//        
//        screenRect = UIScreen.main.bounds
//        
//        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
//        previewLayer.videoGravity = .resizeAspectFill
//        
//        previewLayer.connection?.videoOrientation = .portrait
//        
//        DispatchQueue.main.async { [weak self] in
//            self!.view.layer.addSublayer(self!.previewLayer)
//        }
//    }
//    
//    //MARK: CAMERA CONFIG
//    func configureCamera() {
//        do {
//            try self.videoDevice.lockForConfiguration()
//            
//            self.videoDevice.videoZoomFactor = 1.0
//            
//            if self.videoDevice.hasTorch {
//                self.videoDevice.torchMode = .off
//            }
//            
//            self.videoDevice.unlockForConfiguration()
//        } catch {
//            print("Unable to configure device camera")
//        }
//    }
//    
//    //MARK: CAMERA TORCH TOGGLE
//    func toggleTorch(_ on: Bool? = nil) {
//        if self.videoDevice == nil { return }
//        
//        do {
//            try self.videoDevice.lockForConfiguration()
//            
//            if self.videoDevice.hasTorch {
//                if on == nil {
//                    if self.videoDevice.torchMode == .on {
//                        self.videoDevice.torchMode = .off
//                    } else if self.videoDevice.torchMode == .off {
//                        try self.videoDevice.setTorchModeOn(level: 1.0)
//                    }
//                } else {
//                    if on! == true {
//                        try self.videoDevice.setTorchModeOn(level: 1.0)
//                    }
//                    else if on! == false {
//                        self.videoDevice.torchMode = .off
//                    }
//                }
//            }
//            
//            self.videoDevice.unlockForConfiguration()
//        } catch {
//            print("Unable to configure camera flash")
//        }
//    }
//    
//    //MARK: CAPTURE FRAME
//    func captureFrame() {
//        sessionQueue.async { [weak self] in
//                self?.isCapturingFrame = true
//            print("CaptureFrame: Flag set to true on sessionQueue: \(self!.isCapturingFrame)")
//            }
////        isCapturingFrame = true // Indicate that the next frame should be captured
////        print("isCapturingFrame set to true: \(isCapturingFrame)")
//    }
//    
//    //MARK: CAPTURE OUTPUT
//    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        
//        sessionQueue.async { [weak self] in
//            guard let self = self else { return }
//            print("Output called: isCapturingFrame: \(self.isCapturingFrame)")
//            if isCapturingFrame == true {
//                print("Capture Output detected, validating...")
//                
//                isCapturingFrame = false // Reset the flag
//                
//                guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//                
//                // Convert the image buffer to a UIImage
//                let ciImage = CIImage(cvPixelBuffer: imageBuffer)
//                let context = CIContext()
//                if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
//                    let image = UIImage(cgImage: cgImage)
//                    
//                    // Send the image back to SwiftUI via the closure
//                    onImageCapture?(image)
//                    print("Image sent back to SwiftUI view representable")
//                }
//            }
//        }
//    }
//    
//    
//    
//}
//
//struct CameraViewControllerHost: UIViewControllerRepresentable {
//    @Binding var flash: Bool
//    @Binding var capturedImage: UIImage?
//    
//    let controller = CameraViewController()
//
//    func makeUIViewController(context: Context) -> CameraViewController {
//        controller.onImageCapture = { image in
//            DispatchQueue.main.async {
//                self.capturedImage = image // Update SwiftUI binding
//                print("Image sent back to content view")
//            }
//        }
//        return controller
//    }
//
//    func updateUIViewController(_ vc: CameraViewController, context: Context) {
//        vc.toggleTorch(flash)
//    }
//
//    func captureFrame() {
//        controller.captureFrame()
//        print("Capture Frame Requested")
//    }
//}
