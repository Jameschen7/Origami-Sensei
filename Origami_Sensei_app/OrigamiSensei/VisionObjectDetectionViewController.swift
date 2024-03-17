/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Contains the object recognition view controller for the Breakfast Finder.
*/

import UIKit
import AVFoundation
import Vision

class VisionObjectDetectionViewController: ViewController {
    // projection website url
    //    private let url_address = "http://172.26.73.110:5000/param"
    //    private let url_address = "http://192.168.240.162:5000/param"
    //    private let url_address = "http://192.168.139.162:5000/param"
    private let url_address = "http://192.168.1.75:5000/param"
    
    // Const
    private let requestProcessMaxFPS: Double = 30.0 //5 // the input frame comes at max 30fps
    private var lastExecutionTimestamp: TimeInterval = 0.0 // for throttling
    private let DEBUG: Bool = false
    private let oriModelMaxStepDict = ["Dog": 8, "Cat": 9, "Whale": 6]
//
    // local variable
    private var currValidStage: String = "1"
//    private var prevValidStage: String = "1" // used for
//    private var currValidStage: String = "1"
    var currentOriModel: String = "Dog" // cannot be private since need to be prepared in a segue in the source view
//    private var predCenterXQueue: FixedSizeQueue = FixedSizeQueue(maxSize: 3)
//    private var predCenterYQueue: FixedSizeQueue = FixedSizeQueue(maxSize: 3)
//    private var predWidthQueue: FixedSizeQueue = FixedSizeQueue(maxSize: 3)
//    private var predHeightXQueue: FixedSizeQueue = FixedSizeQueue(maxSize: 3)
    
    // Vision parts
    private var requests = [VNRequest]()
    private var detectionOverlay: CALayer! = nil

    
    // UI
    @IBOutlet weak var pageTitle: UILabel!
    @IBOutlet weak var instructionImageView: UIImageView!
    @IBOutlet weak var nextStepImageView: UIImageView!
    @IBOutlet weak var previewContrainerView: UIView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBAction func goBackAction(_ sender: Any) {
//        self.navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pageTitle.text = currentOriModel
        
        // update origami model name on the website
        performGetRequestForOriModelUpdate(oriModel: currentOriModel)
                
        // set up the previewContrainerView
        previewLayer.removeFromSuperlayer()
        previewLayer.frame = previewContrainerView.bounds
        previewContrainerView.layer.addSublayer(previewLayer)
//        print(previewLayer.superlayer)
        
        // configure instructionImageView & nextStepImageView
        // Set the border width
        instructionImageView.layer.borderWidth = 2
        instructionImageView.layer.cornerRadius = 5 // Adjust the value as needed
        instructionImageView.clipsToBounds = true
        nextStepImageView.layer.borderWidth = 1.5
        nextStepImageView.layer.cornerRadius = 5 // Adjust the value as needed
        nextStepImageView.clipsToBounds = true
        
        // configure progress bar
//        progressBar.progressTintColor = UIColor.blue // Color of the progress bar
//        progressBar.progressTintColor = UIColor(red: 5 / 255.0, green: 128 / 255.0, blue: 174 / 255.0, alpha: 1.0)
        progressBar.trackTintColor = UIColor.lightGray // Background color
        progressBar.transform = progressBar.transform.scaledBy(x: 1, y: 2.5) // Doubles the thickness

        // Set the border color
        instructionImageView.layer.borderColor = UIColor.black.cgColor
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // update the frame of the previewLayer when the layout changes (e.g., device rotation, view layout changes)
        previewLayer.frame = previewContrainerView.bounds
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
    
    @discardableResult
    func setupVision() -> NSError? {
        // Setup Vision parts
        let error: NSError! = nil
        
        do {
//            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let config = MLModelConfiguration()
            config.computeUnits = .all // Use any available compute unit, including GPUs and ANEs
            
//            let visionModel = try VNCoreMLModel(
//                for: optimized_origami_resnet_v2(configuration: config).model)
//            let visionModel = try VNCoreMLModel(for: PaperDetector_10000(configuration: config).model)
            let visionModel: VNCoreMLModel
            switch currentOriModel {
                case "Dog":
                    visionModel = try VNCoreMLModel(for: PaperDetector_dog_extra7000(configuration: config).model)
                case "Cat":
                    visionModel = try VNCoreMLModel(for: PaperDetector_cat_extra7000(configuration: config).model)
                case "Whale":
                    visionModel = try VNCoreMLModel(for: PaperDetector_whale_extra7000(configuration: config).model)
                default:
                    print("-X '\(currentOriModel)' model not recognized.")
                    return error
            }
            
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
            print("-X '\(currentOriModel)' Model loading went wrong: \(error)")
        }
        
        return error
    }
    
    func drawVisionRequestResults(_ results: [Any]) {
        // make changes to one or more layer properties
        CATransaction.begin()
        // have those changes appear instantly
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        detectionOverlay.sublayers = nil // remove all the old recognized objects
        
        for observation in results where observation is VNRecognizedObjectObservation {
            if (DEBUG) {
                print("observation", observation)
            }
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
//            print(objectObservation)  // 0-1. e.g.: [0.162353, 0.35479, 0.805361, 0.243748]
            
            // Select only the label with the highest confidence.
            let topLabelObservation = objectObservation.labels[0]
            
            // get predicted bbox
//            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.width), Int(bufferSize.height))
            
            // swap x and y axis to encounter then rotation from graph coord to screen coord, (solve that move down increase bbox y-coord)
            var objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(bufferSize.height), Int(bufferSize.width))
//            print(objectObservation.boundingBox)
            let newBoundX = bufferSize.width-objectBounds.origin.y - objectBounds.height
            let newBoundY = bufferSize.height-objectBounds.origin.x - objectBounds.width
//            // edit the origin and scale based on the previewLayer.frame
//            let scaleX = previewLayer.frame.width / rootLayer.frame.width
//            newBoundX = newBoundX*scaleX + previewLayer.frame.origin.x
//            newBoundY += previewLayer.frame.origin.y
            objectBounds = CGRect(x: newBoundX,y: newBoundY,
                                  width: objectBounds.height, height: objectBounds.width)
//            print(objectBounds) // x,y,w,h
            
            let shapeLayer = self.createRoundedRectLayerWithBounds(objectBounds)
            
            // test drawing
//            let objectBoundsTest = CGRect(x: 50, y: 0, width: 200, height: 100) //(0,50,100,200)
//            let shapeLayerTest = self.createRoundedRectLayerWithBounds(objectBoundsTest)
//            detectionOverlay.addSublayer(shapeLayerTest)
            
            let textLayer = self.createTextSubLayerInBounds(objectBounds,
                                            identifier: topLabelObservation.identifier,
                                            confidence: topLabelObservation.confidence)
            shapeLayer.addSublayer(textLayer)
            detectionOverlay.addSublayer(shapeLayer)
            
            // update projected instruction; for the prediction in the buffer space, swap x and y back
            performGetRequestForPrediction(stage: topLabelObservation.identifier,
                              xCoord: Float(objectBounds.origin.y),
                              yCoord: Float(objectBounds.origin.x))
            
            // update ipad instruction
            if (currValidStage != topLabelObservation.identifier && topLabelObservation.identifier != "0") {
                currValidStage = topLabelObservation.identifier
//                instructionImageView.image = UIImage(contentsOfFile: Bundle.main.path(forResource: "OrigamiSensei/Dog_imgs/Dog_instruction_Inst"+currValidStage, ofType: "png")!)
                instructionImageView.image = UIImage(named: "\(currentOriModel)_instruction_Inst\(currValidStage)_blue")
                
                // find the next step and set progress bar
                if var currValidStageForStage = Int(currValidStage) {
                    currValidStageForStage += 1
                    if currValidStageForStage > oriModelMaxStepDict[currentOriModel]! {
                        currValidStageForStage -= 1
                    }
                    nextStepImageView.image = UIImage(named: "\(currentOriModel)_instruction_Step\(currValidStageForStage)_blue")
                    progressBar.progress = Float(currValidStage)! / Float(oriModelMaxStepDict[currentOriModel]!)
                } else {
                    print("The `currValidStage` string '\(currValidStage)' cannot be converted to an integer.")
                }
            }
            break // only process the first bbox
        }
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
        
        
//        // save the raw camera image for debug/test
//        let ciImage = CIImage(cvImageBuffer: pixelBuffer) // Convert CVImageBuffer to CIImage
//        let orientedCIImage = ciImage.transformed(by: exifOrientationToTransform(exifOrientation: exifOrientation))
//
//        let context = CIContext(options: nil)
//        print(orientedCIImage.extent)
//        guard let cgImage = context.createCGImage(orientedCIImage, from: orientedCIImage.extent) else {
//            // Handle error
//            return
//        }
//        let uiImage = UIImage(cgImage: cgImage) // Convert CIImage to UIImage:
//        if let imageData = uiImage.jpegData(compressionQuality: 1.0) ?? uiImage.pngData() {
//            do {
////                try imageData.write(to: URL(fileURLWithPath: "tmp.jpg"))
//                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
//                let fileURL = documentsDirectory?.appendingPathComponent("image.jpg")
//
//                try imageData.write(to: fileURL!)
//                print("Save succeed", fileURL!.absoluteString)
//            } catch{
//                print("Save failed")
//            }
//        }
//        //////////////////
        
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
    
    
    func updateLayerGeometry() {
        // early return if the session is already ended
        if (!isSessionRunning) {
            return
        }
        
//        let bounds = rootLayer.bounds
        var scale: CGFloat
        
//        let xScale: CGFloat = bounds.size.width / bufferSize.height
//        let yScale: CGFloat = bounds.size.height / bufferSize.width
//        print(xScale, bounds.size.width, bufferSize.height) // 1.6875 810.0 480.0
//        print(yScale, bounds.size.height, bufferSize.width) // 1.6875 1080.0 640.0
        
        // scale from the video buffer coordinate (bufferSize) to preview layer coord
        let xScale: CGFloat = previewContrainerView.frame.width / bufferSize.height
        let yScale: CGFloat = previewContrainerView.frame.height / bufferSize.width
//        print(previewContrainerView.frame)
        
        scale = fmax(xScale, yScale)
        if scale.isInfinite {
            scale = 1.0
        }
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // rotate the layer into screen orientation and scale and mirror
        detectionOverlay.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(.pi / 2.0)).scaledBy(x: scale, y: -scale))

        // center the layer
//        detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
        detectionOverlay.position = CGPoint(x: previewContrainerView.frame.midX, y: previewContrainerView.frame.midY) // set the layer center to overlap with previewLayer center
        
        CATransaction.commit()
    }
    
    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        let formattedString = NSMutableAttributedString(string: String(format: "\(identifier)  Score:  %.2f", confidence))
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
        shapeLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 0.2, 0.3])
        shapeLayer.cornerRadius = 7
        return shapeLayer
    }
    
    func setupFPSLayer(){
        // show FPS
        let textLayer = CATextLayer()
        textLayer.name = "FPS"
        let formattedString = NSMutableAttributedString(string: "Model Process FPS: \(requestProcessMaxFPS)")
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
    
    
    // MARK: - HTTP Related
    func performGetRequestForOriModelUpdate(oriModel: String) {
        let urlParamString = "current_ori_model=\(oriModel)"
        performGetRequest(urlParamString)
    }
    
    func performGetRequestForPrediction(stage: String, xCoord: Float, yCoord: Float) {
        let xCoordStr = String(format: "%.4f", xCoord)
        let yCoordStr = String(format: "%.4f", yCoord)
        let urlParamString = "stage=\(stage)&x_coord=\(xCoordStr)&y_coord=\(yCoordStr)"
        performGetRequest(urlParamString)
    }
    
    func performGetRequest(_ urlParam: String) {
        guard let url = URL(string: "\(url_address)?\(urlParam)")
        else {
            print("Invalid URL: \(url_address)?\(urlParam)")
            return
        }
        
        let session = URLSession.shared
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Server error! not HTTPURLResponse or not 2xx status code")
                return
            }

            if let data = data,
               let dataString = String(data: data, encoding: .utf8) {
                print("Response data string: \(dataString)")
            }
        }
        task.resume()
    }
}



struct FixedSizeQueue {
    private var elements: [Float] = []
    private let maxSize: Int

    init(maxSize: Int) {
        self.maxSize = maxSize
    }

    mutating func enqueue(_ element: Float) {
        if elements.count == maxSize {
            elements.removeFirst()
        }
        elements.append(element)
    }

    func mean() -> Float? {
        guard !elements.isEmpty else { return nil }
        let sum = elements.reduce(0, +)
        return sum / Float(elements.count)
    }
}
