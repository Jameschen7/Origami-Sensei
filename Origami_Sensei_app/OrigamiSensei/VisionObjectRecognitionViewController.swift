/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Contains the object recognition view controller for the Breakfast Finder.
*/

import UIKit
import AVFoundation
import Vision

class VisionObjectRecognitionViewController: ViewController {
    
    private var detectionOverlay: CALayer! = nil
    private let requestProcessMaxFPS: Double = 5.0 // the input frame comes at max 30fps
    var lastExecutionTimestamp: TimeInterval = 0.0 // for throttling
    
    // Vision parts
    private var requests = [VNRequest]()
    
    @IBAction func goBackAction(_ sender: Any) {
//        self.navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)

    }
    
    @discardableResult
    func setupVision() -> NSError? {
        // Setup Vision parts
        let error: NSError! = nil
        
//        guard let modelURL = Bundle.main.url(forResource: "ObjectDetector", withExtension: "mlmodelc") else {
//            return NSError(domain: "VisionObjectRecognitionViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model file is missing"])
//        }
        do {
//            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let config = MLModelConfiguration()
            config.computeUnits = .all // Use any available compute unit, including GPUs and ANEs
//            let visionModel = try VNCoreMLModel(for: optimized_origami_resnet_v2().model)
            let visionModel = try VNCoreMLModel(
                for: optimized_origami_resnet_v2(configuration: config).model)
            
//            let request = VNCoreMLRequest(model: visionModel) { (finishedReq, err) in
////                print(finishReq.results)
//                guard let results = finishedReq.results as? [VNClassificationObservation] else { fatalError("Model failed to process image") }
//                guard let firstObservation = results.first else { return }
//                print(firstObservation.identifier, firstObservation.confidence)
//            }
//            self.requests = [request]
            
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
                DispatchQueue.main.async(execute: {
                    // perform all the UI updates on the main queue
                    if let results = request.results {
                        self.drawVisionRequestResults(results)
                    }
                })
            })
            self.requests = [objectRecognition]
        } catch let error as NSError {
            print("Model loading went wrong: \(error)")
        }
        
        return error
    }
    
    func drawVisionRequestResults(_ results: [Any]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        
//        if results.first is VNRecognizedObjectObservation {
//            print("result is VNRecognizedObjectObservation")
//        }
//        else if results.first is VNRecognizedObjectObservation {
//            print("result is VNRecognizedObjectObservation")
//        }
        
//        for observation in results where observation is VNRecognizedObjectObservation {
//            print("observation", observation)
//            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
//                continue
//            }
//            print(objectObservation)
//            // Select only the label with the highest confidence.
//            let topLabelObservation = objectObservation.labels[0]
//            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
//
//            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
//
//            let textLayer = self.createTextSubLayerInBounds(objectBounds,
//                                                            identifier: topLabelObservation.identifier,
//                                                            confidence: topLabelObservation.confidence)
//            shapeLayer.addSublayer(textLayer)
//            detectionOverlay.addSublayer(shapeLayer)
//        }
//        self.updateLayerGeometry()
//        CATransaction.commit()
        
        // draw classification result
        guard let observations = results as? [VNClassificationObservation] else { fatalError("Model failed to process image") }
        guard let firstObservation = observations.first else {return}
        let secondObservation = observations[1]

        //print(firstObservation)

//        let newWidth = 100
//        let newHeight = 200
//        let originX = 405
//        let originY = 135

        let objectBounds = CGRect(x: 405, y: 135, width: 100, height: 200) // dimension in landscape-right
        let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
        let textLayer = self.createTextSubLayerInBounds(objectBounds,
                                                        identifier: firstObservation.identifier,
                                                        confidence: firstObservation.confidence)
        shapeLayer.addSublayer(textLayer)
        detectionOverlay.addSublayer(shapeLayer)
        
        let objectBounds2 = CGRect(x: 455, y: 135, width: 100, height: 200)
        let shapeLayer2 = self.createRoundedRectLayerWithBounds(objectBounds2)
        let textLayer2 = self.createTextSubLayerInBounds(objectBounds2,
                                                        identifier: secondObservation.identifier,
                                                        confidence: secondObservation.confidence)
        shapeLayer.addSublayer(textLayer2)
        detectionOverlay.addSublayer(shapeLayer2)
        
        self.updateLayerGeometry()
        CATransaction.commit()
    }
    
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // set the FPS to process request (run models)
        let currentTimestamp = Date().timeIntervalSince1970
        if currentTimestamp - lastExecutionTimestamp < 1/requestProcessMaxFPS {
            return
        }
        lastExecutionTimestamp = currentTimestamp
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let exifOrientation = exifOrientationFromDeviceOrientation()
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
    
    override func setupAVCapture() {
        super.setupAVCapture()
        
        // setup Vision parts
        setupLayers()
        updateLayerGeometry()
        setupVision()
        
        setupFPSLayer() // show FPS
        
        // start the capture
        startCaptureSession()
    }
    
    func setupLayers() {
        detectionOverlay = CALayer() // container layer that has all the renderings of the observations
        detectionOverlay.name = "DetectionOverlay"
        detectionOverlay.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: bufferSize.width,
                                         height: bufferSize.height)
        detectionOverlay.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        rootLayer.addSublayer(detectionOverlay)
    }
    
    func updateLayerGeometry() {
        // early return if the session is already ended
        if (!isSessionRunning) {
            return
        }
        
        let bounds = rootLayer.bounds
        var scale: CGFloat
        
        let xScale: CGFloat = bounds.size.width / bufferSize.height
        let yScale: CGFloat = bounds.size.height / bufferSize.width
//        print(xScale, bounds.size.width, bufferSize.height)
//        print(yScale, bounds.size.height, bufferSize.width)
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // rotate the layer into screen orientation and scale and mirror
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))
        // center the layer
        detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        CATransaction.commit()
    }
    
    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        let formattedString = NSMutableAttributedString(string: String(format: "\(identifier)  Confidence:  %.2f", confidence))
        let largeFont = UIFont(name: "Helvetica", size: 24.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: identifier.count))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.height - 10, height: bounds.size.width - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.shadowOpacity = 0.7
        textLayer.shadowOffset = CGSize(width: 2, height: 2)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        // rotate the layer into screen orientation and scale and mirror
        textLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: 1.0, y: -1.0))
        return textLayer
    }
    
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        // print(bounds, bounds.midX, bounds.midY) //(455.0, 135.0, 100.0, 200.0)
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.name = "Classification Output"
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.4])
        shapeLayer.cornerRadius = 7
        return shapeLayer
    }
    
    func setupFPSLayer(){
        // show FPS
        let textLayer = CATextLayer()
        textLayer.name = "FPS"
        let formattedString = NSMutableAttributedString(string:
            String(format: "Model Process FPS: \(requestProcessMaxFPS)"))
        let largeFont = UIFont(name: "Helvetica", size: 15.0)!
        formattedString.addAttributes([NSAttributedString.Key.font: largeFont], range: NSRange(location: 0, length: formattedString.length))
        textLayer.string = formattedString
        textLayer.bounds = CGRect(x: 0, y: 0, width: 200, height: 100) // the origin specifies the starting location of the masking rectange over the full text string
        print("root layer bound:", rootLayer.bounds, "FPS layer:", textLayer.bounds, textLayer.bounds.midX, textLayer.bounds.midY)
        textLayer.position = CGPoint(x: 10+textLayer.bounds.midX, y: 25+textLayer.bounds.midY)
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        textLayer.contentsScale = 2.0 // retina rendering
        rootLayer.addSublayer(textLayer)
    }
}
