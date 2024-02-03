/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Contains the view controller for the Breakfast Finder.
*/

import UIKit
import AVFoundation
import Vision //multimedia framework provides high-level services for working with time-based audiovisual media

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var bufferSize: CGSize = .zero
    var rootLayer: CALayer! = nil
    var isSessionRunning = false // handle in-flight captureOutput calls after the session is stopped
    
    @IBOutlet weak private var previewView: UIView!
    private let session = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer! = nil // need access in subclass
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    private let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // to be implemented in the subclass
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAVCapture()
        
        // Disable the idle timer to prevent the screen from sleeping
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Re-enable the idle timer when leaving the screen
        UIApplication.shared.isIdleTimerDisabled = false
        teardownAVCapture()
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupAVCapture() {
        var deviceInput: AVCaptureDeviceInput!
        
        // Select a video device and session resolution, make an input
//        let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first  // change to .front for front camera
        let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices.first  // change to .front for front camera
        do {
            //print(videoDevice!.activeFormat.videoSupportedFrameRateRanges) // 2 - 30
            //print("Min FPS: \(videoDevice!.activeFormat.videoSupportedFrameRateRanges.first!.minFrameRate)")
            //print("Max FPS: \(videoDevice!.activeFormat.videoSupportedFrameRateRanges.first!.maxFrameRate)")
            deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        } catch {
            print("Could not create video device input: \(error)")
            return
        }
        
        session.beginConfiguration()
        session.sessionPreset = .vga640x480 // Model image size is smaller. Even though this is different from iPad front camera resolution & aspect ratio (720x1280), the aspect ratio of objects captured is the same, and the view is wider, which is better.
        
        // Add video input to your session by adding the camera as a device
        guard session.canAddInput(deviceInput) else {
            print("Could not add video device input to the session")
            session.commitConfiguration()
            return
        }
        session.addInput(deviceInput)
        
        // Add video output to your session, being sure to specify the pixel format:
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput) // Add a video data output
            /*
             If processing or other operations cause delays and a new frame arrives before the previous one has been processed, the alwaysDiscardsLateVideoFrames property ensures that late frames are discarded to avoid processing lag or backlog.
             */
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
//            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)] // bi-planar, full-range YCbCr format -> most efficient
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_24RGB)] // 24 bits using the RGB color model.
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            print("Could not add video data output to the session")
            session.commitConfiguration()
            return
        }
        
        // Process every frame, but don’t hold on to more than one Vision request at a time
        // The sample app keeps a queue size of 1; if a Vision request is already queued up for processing when another becomes available, skip it instead of holding on to extras.
        let captureConnection = videoDataOutput.connection(with: .video)
        captureConnection?.isEnabled = true // ensuring that there is a connection for video data, and if there is, the connection is set to be active
//        captureConnection?.isVideoMinFrameDurationSupported
        do {
            try  videoDevice!.lockForConfiguration()
            // set buffer size to current video device output size
            let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
            bufferSize.width = CGFloat(dimensions.width)
            bufferSize.height = CGFloat(dimensions.height)
            //videoDevice!.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 2) // for video, set to 2FPS max
            videoDevice!.unlockForConfiguration()
        } catch {
            print(error)
        }
        
        // Set up a preview layer on view controller, so the camera can feed its frames into app’s UI:
        session.commitConfiguration() // finalizing your changes to the session
        previewLayer = AVCaptureVideoPreviewLayer(session: session) // This layer is specialized for rendering a preview of the camera's visual output
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill // scales the video to fill the layer’s bounds, maintaining the video’s aspect ratio, and potentially cropping the video if the video's aspect ratio is different from the layer’s
        rootLayer = previewView.layer
//        previewLayer.frame = rootLayer.bounds // takes up the entire space of the previewView
        
        // change to be centered with half width and height
//        let newWidth = rootLayer.bounds.width / 1.5
//        let newHeight = rootLayer.bounds.height / 2
//        let originX = (rootLayer.bounds.width - newWidth) / 2
//        let originY = (rootLayer.bounds.height - newHeight) / 4
        // change to be smaller on the top half without cropping too much on the y-axis
        let newWidth = rootLayer.bounds.width / 3
        let newHeight = rootLayer.bounds.height / 3.5
        let originX = (rootLayer.bounds.width - newWidth) / 2
        let originY = (rootLayer.bounds.height - newHeight) / 4
        print("Camera window size and location:", newWidth,newHeight,originX,originY)
        previewLayer.frame = CGRect(x: originX, y: originY, width: newWidth, height: newHeight)

        rootLayer.addSublayer(previewLayer)
    }
    
    func startCaptureSession() {
        // Start the session here if not already started
        session.startRunning()
        isSessionRunning = true
    }
    
    // Clean up capture setup
    func teardownAVCapture() {
        // Stop the session when the view controller is about to disappear
        session.stopRunning()
        isSessionRunning = false
        
        previewLayer.removeFromSuperlayer() // removes the video preview display from the screen
        previewLayer = nil // release it if there are no other strong references to it
    }
    
    
    /*
     called when a frame, represented by a sample buffer, is dropped during the video capture process.
     Is overriden by subclass.
     */
    func captureOutput(_ captureOutput: AVCaptureOutput, didDrop didDropSampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//          print("frame dropped")
    }
    
    /*
     provides a mapping from the device's physical orientation to
     the appropriate image orientation value, ensuring that images
     are tagged with the correct orientation metadata when they're captured.
     */
    public func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation
        
//        // back camera
//        switch curDeviceOrientation {
//        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
//            print("curDeviceOrientation: portraitUpsideDown")
//            exifOrientation = .left
//        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
//            print("curDeviceOrientation: landscapeLeft")
//            exifOrientation = .upMirrored
//        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
//            print("curDeviceOrientation: landscapeRight")
//            exifOrientation = .down
//        case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
//            print("curDeviceOrientation: portrait")
//            exifOrientation = .up
//        default:
//            print("curDeviceOrientation: default")
//            exifOrientation = .up
//        }
        
//        // front camera
//        switch curDeviceOrientation {
//        case .portraitUpsideDown:  // Device oriented vertically, home button on the top
//            exifOrientation = .leftMirrored
//        case .landscapeLeft:       // Device oriented horizontally, home button on the right
//            exifOrientation = .downMirrored
//        case .landscapeRight:      // Device oriented horizontally, home button on the left
//            exifOrientation = .upMirrored
//        case .portrait:            // Device oriented vertically, home button on the bottom
//            print("curDeviceOrientation: portrait")
//            exifOrientation = .rightMirrored
//        default:
//            print("curDeviceOrientation: default")
//            exifOrientation = .rightMirrored // or .upMirrored, depending on how your app handles unknown orientation
//        }
        
        // "https://stackoverflow.com/a/62986917" tested one without flipping
        let isUsingFrontFacingCamera = true
        switch curDeviceOrientation {
            case .portrait:
                exifOrientation = .right
            case .portraitUpsideDown:
                exifOrientation = .left
            case .landscapeLeft:
                exifOrientation = isUsingFrontFacingCamera ? .down : .up
            case .landscapeRight:
                exifOrientation = isUsingFrontFacingCamera ? .up : .down
            default:
                exifOrientation = .right
        }

        return exifOrientation
    }
    
    
    // for debugging the input image
    func exifOrientationToTransform(exifOrientation: CGImagePropertyOrientation) -> CGAffineTransform {
        switch exifOrientation {
        case .up:
            return CGAffineTransform.identity
        case .down:
            return CGAffineTransform(rotationAngle: .pi)
        case .left:
            return CGAffineTransform(rotationAngle: .pi / 2)
        case .right:
            return CGAffineTransform(rotationAngle: -.pi / 2)
        case .upMirrored:
            return CGAffineTransform(scaleX: -1, y: 1)
        case .downMirrored:
            return CGAffineTransform(scaleX: -1, y: 1).rotated(by: .pi)
        case .leftMirrored:
            // This mirrors along the Y-axis and then rotates 90 degrees clockwise.
            return CGAffineTransform(scaleX: 1, y: -1).rotated(by: .pi / 2)
        case .rightMirrored:
            // This mirrors along the Y-axis and then rotates 90 degrees counterclockwise.
            return CGAffineTransform(scaleX: 1, y: -1).rotated(by: -.pi / 2)
//        @unknown default:
//            return CGAffineTransform.identity
        }
    }
}



