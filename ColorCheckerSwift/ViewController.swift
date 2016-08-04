//
//  ViewController.swift
//  ColorCheckerSwift
//
//  Created by Hiroyuki Kai on 7/27/16.
//  Copyright © 2016 Hiroyuki Kai. All rights reserved.
//

import UIKit
import AVFoundation
import ReplayKit

class GraphView: UIView {
    var vs : [Float] = []
    var vs_count = 0
    var parent : ViewController!
    
    init(frame: CGRect, parent: ViewController) {
        super.init(frame: frame)
        self.vs = [0]
        self.vs_count = 0
        self.parent = parent
        self.opaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func tr_x(v: Float, _ v0 : Float, _ duration : Float?) -> Float {
        var dur : Float
        if(duration == nil){
            dur = 10
        }else{
            dur = duration!
        }
        return (v-v0) / dur * Float(self.bounds.width) * 0.8 + 45
    }
    
    func tr_y(v : Float, _ vmin : Float = 0, _ vmax : Float = 100) -> Float {
        let view_y_min : Float = 15
        let view_y_max = Float(self.bounds.height) - 15
        return view_y_min + (1-(v-vmin)/(vmax-vmin))*(view_y_max-view_y_min)
    }
    
    func drawGraphFrame(vmin : Float, _ vmax : Float) {
        // set the text color to dark gray
        let fieldColor: UIColor = UIColor.blueColor()
        
        // set the font to Helvetica Neue 18
        let fieldFont = UIFont(name: "Helvetica Neue", size: 24)
        
        // set the line spacing to 6
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.lineSpacing = 6.0
        paraStyle.alignment = NSTextAlignment.Right
        
        // set the Obliqueness to 0.1
        var skew = 0.1
        
        let attributes: NSDictionary = [
            NSForegroundColorAttributeName: fieldColor,
            NSParagraphStyleAttributeName: paraStyle,
            //                NSObliquenessAttributeName: skew,
            NSFontAttributeName: fieldFont!
        ]
        let s: NSString = String(format: "%3.1f", vmax)
        s.drawInRect(CGRectMake(0, 0, 45, 48.0), withAttributes: attributes as! [String: AnyObject])
        let s2: NSString = String(format: "%3.1f", vmin)
        s2.drawInRect(CGRectMake(0, self.bounds.height-30, 45, 48.0), withAttributes: attributes as! [String: AnyObject])
        
        let color2 = UIColor.grayColor()
        let path2 = CGPathCreateMutable()
        CGPathMoveToPoint(path2, nil, CGFloat(45), CGFloat(15))
        CGPathAddLineToPoint(path2, nil,
                             CGFloat(self.bounds.width),
                             CGFloat(15))
        let bpath2:UIBezierPath = UIBezierPath(CGPath: path2)
        bpath2.lineWidth = 1
        color2.set()
        bpath2.stroke()
        
        let path3 = CGPathCreateMutable()
        CGPathMoveToPoint(path3, nil, CGFloat(45), CGFloat(self.bounds.height-15))
        CGPathAddLineToPoint(path3, nil,
                             CGFloat(self.bounds.width),
                             CGFloat(self.bounds.height-15))
        let bpath3:UIBezierPath = UIBezierPath(CGPath: path3)
        bpath3.lineWidth = 1
        color2.set()
        bpath3.stroke()
    }
    
    override func drawRect(rect: CGRect) {
        let color:UIColor = UIColor.blueColor()
        let path = CGPathCreateMutable()
        let vs = self.parent.vs_accum
        if(self.vs_count > 0){
            var xi_from : Int
            var xi_until : Int
            let ts = self.parent.times
            if(self.vs_count < 100){
                xi_from = 0
                xi_until = self.vs_count
            }else{
//                xi_from = self.vs_count-100
                xi_from = 0
                xi_until = self.vs_count
            }
            let dur : Float = Float(self.vs_count) / 10.0
            let slice = vs[xi_from...xi_until-1]
            let (vmin,vmax) = (slice.minElement()!,slice.maxElement()!)
            drawGraphFrame(vmin,vmax)
            CGPathMoveToPoint(path, nil, CGFloat(tr_x(ts[xi_from],ts[xi_from],dur)), CGFloat(self.tr_y(vs[xi_from],vmin,vmax)))
            for i in xi_from..<xi_until {
                CGPathAddLineToPoint(path, nil,
                                     CGFloat(self.tr_x(ts[i],ts[xi_from],dur)),
                                     CGFloat(self.tr_y(vs[i],vmin,vmax)))
            }
            let bpath:UIBezierPath = UIBezierPath(CGPath: path)
            bpath.lineWidth = 2
            color.set()
            bpath.stroke()
        
        }
        
    }
}

class InfoView: UIView {
    var lab : (Float,Float,Float) = (0,0,0)
    
    override func drawRect(rect: CGRect) {
        // set the text color to dark gray
        let fieldColor: UIColor = UIColor.blackColor()
        
        // set the font to Helvetica Neue 18
        let fieldFont = UIFont(name: "Helvetica Neue", size: 48)
        
        // set the line spacing to 6
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.lineSpacing = 6.0
        paraStyle.alignment = NSTextAlignment.Center
        
        // set the Obliqueness to 0.1
        var skew = 0.1
        
        let attributes: NSDictionary = [
            NSForegroundColorAttributeName: fieldColor,
            NSParagraphStyleAttributeName: paraStyle,
            NSObliquenessAttributeName: skew,
            NSFontAttributeName: fieldFont!
        ]
        let s: NSString = String(format: "L* = %3.1f", self.lab.0)
        s.drawInRect(CGRectMake(0, 20, self.bounds.width, self.bounds.height-20*2), withAttributes: attributes as! [String: AnyObject])
    }
}

class ROIView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.opaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawRect(rect: CGRect) {
        let h = rect.height
        let w = rect.width
        let color:UIColor = UIColor.yellowColor()
        let w_scale = CGFloat(0.1)
        
        let drect = CGRect(x: (w * 0.5-w*w_scale*0.5),y: (h * 0.5-w*w_scale*0.5),width: (w*w_scale),height: (w*w_scale))
        let bpath:UIBezierPath = UIBezierPath(rect: drect)
        bpath.lineWidth = 2
        
        color.set()
        bpath.stroke()
    }
    
}

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, RPPreviewViewControllerDelegate {
    @IBOutlet weak var view2: UIImageView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var smallView: UIImageView!
    @IBOutlet weak var colorView: UIView!
    var graphView: GraphView!
    @IBOutlet weak var graphViewBG: UIView!
    @IBOutlet weak var infoView: InfoView!
    @IBOutlet weak var textField: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.vs_accum = Array(count: 10000, repeatedValue: 0.0)
        self.times = Array(count: 10000, repeatedValue: 0.0)
        // Do any additional setup after loading the view, typically from a nib.
        self.configureCamera()
        let f = ROIView(frame: CGRectMake(0, 20, 375, 500))
        view.addSubview(f)
        graphView = GraphView(frame: CGRectMake(0, 370, 375, 150),parent: self)
        view.addSubview(graphView)
        mySession.startRunning()
        self.textField.hidden = true
        
    }
    
    var mySession : AVCaptureSession!
    var myDevice : AVCaptureDevice!
    var myImageOutput : AVCaptureStillImageOutput!
    
    var running : Bool = false
    var count = 0
    
    var vs_count = 0
    var times : [Float] = []
    var vs_accum : [Float] = []
    
    var prevCaptureTime : Double! = nil
    var initialTime : Double! = nil
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setCameraMode() {
        do {
            let d = self.myDevice
            try d.lockForConfiguration()
            d.activeVideoMinFrameDuration = CMTimeMake(1,10)
            d.activeVideoMaxFrameDuration = CMTimeMake(1,10)
            d.whiteBalanceMode = AVCaptureWhiteBalanceMode.Locked
            d.exposureMode = AVCaptureExposureMode.AutoExpose
            d.unlockForConfiguration()
        }catch{
        }
    }
    
    func configureCamera() -> Bool {
        mySession = AVCaptureSession()
        let devices = AVCaptureDevice.devices()
        for device in devices{
            if(device.position == AVCaptureDevicePosition.Back){
                myDevice = device as! AVCaptureDevice
            }
        }
        setCameraMode()
        
        let videoInput: AVCaptureInput!
        do {
            videoInput = try AVCaptureDeviceInput.init(device: myDevice!)
        }catch {
            videoInput = nil
        }
        
        mySession.addInput(videoInput)
        
        let previewLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer.init(session:mySession)
        previewLayer.frame = smallView.bounds
        smallView.layer.addSublayer(previewLayer)
        let videoDataOutput: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        mySession.addOutput(videoDataOutput)
        mySession.sessionPreset = AVCaptureSessionPreset640x480
        let cameraQueue = dispatch_queue_create("cameraQueue", nil)
        
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : Int(kCVPixelFormatType_32BGRA)]
        videoDataOutput.setSampleBufferDelegate(self, queue: cameraQueue)
        
        return true
    }
    
    typealias Float3 = (Float,Float,Float)
    
    // Verified a few results with http://www.easyrgb.com/index.php
    func rgb_to_lab(r : Float, _ g : Float, _ b : Float) -> Float3 {
        assert(0<=r && r<=1)
        assert(0<=g && g<=1)
        assert(0<=b && b<=1)
        
        return xyz2lab(rgb2xyz(r,g,b));
    }
    
    func mul_mat(m : [[Float]], _ v : Float3) -> Float3 {
        assert(m.count == 3 && m[0].count == 3 && m[1].count == 3 && m[2].count == 3)
        let x = m[0][0]*v.0+m[0][1]*v.1+m[0][2]*v.2
        let y = m[1][0]*v.0+m[1][1]*v.1+m[1][2]*v.2
        let z = m[2][0]*v.0+m[2][1]*v.1+m[2][2]*v.2
        return (x,y,z)
    }
    
    func rgb2xyz(c : Float3) -> Float3 {
        let (r,g,b) = c
        
        assert(0<=r && r<=1)
        assert(0<=g && g<=1)
        assert(0<=b && b<=1)
        
        func f(v: Float) -> Float {
            return Float(v > 0.04045 ? pow((v + 0.055)/1.055, 2.4) : v / 12.92)
        }
        
        let mat : [[Float]] = [[0.412453, 0.357580, 0.180423],
                               [0.212671, 0.715160, 0.072169],
                               [0.019334, 0.119193, 0.950227]]
        
        let c2 = (f(c.0),f(c.1),f(c.2))
        
        let xyz = mul_mat(mat, c2)
        
        return xyz
    }
    
    
    func xyz2lab(c : Float3) -> Float3 {
        let (x,y,z)=c
        //        NSLog("%.3f,%.3f,%.3f",x,y,z)
        
        //        assert(0<=x && x<=1)
        //        assert(0<=y && y<=1)
        //        assert(0<=z && z<=1)
        
        func f(v: Float) -> Float {
            return v > 0.008856 ? pow(v, 1.0/3.0) : (7.787 * v + 16.0/116.0)
        }
        
        let r : Float3 = (0.95047, 1.0, 1.08883)
        let (x2,y2,z2) = (f(x/r.0),f(y/r.1),f(z/r.2))
        let l = (116.0*y2) - 16.0
        let a = 500.0 * (x2 - y2)
        let b = 200.0 * (y2 - z2)
        
        return (l,a,b)
    }
    
    var timer_count : Int = 0
    
    // sampleBufferからCGImageを作成
    func captureImage(sampleBuffer:CMSampleBufferRef) -> (CGImageRef?,CGContext?) {
        // Sampling Bufferから画像を取得
        let imageBuffer:CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        // pixel buffer のベースアドレスをロック
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        
        let baseAddress:UnsafeMutablePointer<Void> = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        
        let bytesPerRow:Int = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width:Int = CVPixelBufferGetWidth(imageBuffer)
        let height:Int = CVPixelBufferGetHeight(imageBuffer)
        //        NSLog("%d %d %d",bytesPerRow,width,height)
        
        // 色空間
        let colorSpace:CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()!
        
        if(baseAddress == nil) {
            return (nil,nil)
        }
        
        let newContext:CGContextRef = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace,
                                                            CGImageAlphaInfo.PremultipliedFirst.rawValue|CGBitmapInfo.ByteOrder32Little.rawValue)!
        let imageRefOpt = CGBitmapContextCreateImage(newContext)
        if(imageRefOpt == nil){
            NSLog("No image.")
        }
        
        //ここで計算
        let vs = self.measure(newContext)
        let rgb : Float3 = (vs[2],vs[1],vs[0])
        let lab = rgb_to_lab(vs[2]/255,vs[1]/255,vs[0]/255)
        vs_accum[vs_count] = lab.0
//        NSLog("RGB to Lab: %.1f,%.1f,%.1f -> %.1f,%.1f,%.1f",rgb.0,rgb.1,rgb.2,lab.0,lab.1,lab.2)
        
        vs_count += 1
        times[vs_count] = Float(prevCaptureTime!-initialTime)
        //        self.textField.text = (lab.map { String(format: "%.0f", $0)}).joinWithSeparator(",  ")
        self.textField.text = "L* = " + String(format: "%.0f", lab.0)
        
        dispatch_async(dispatch_get_main_queue()) {
            self.timer_count += 1
            // Update the UI on the main thread.
            let c = UIColor(colorLiteralRed: rgb.0/255, green: rgb.1/255, blue: rgb.2/255, alpha: vs[3]/255)
            let allImage1 = CGImageCreateWithImageInRect(imageRefOpt,CGRectMake(0,0,640,480))!  //x,yが入れ替わっていることに注意
            let allImage = UIImage(CGImage: allImage1, scale: 1.0, orientation: UIImageOrientation.Right)
            self.viewForScreenshot.image = allImage
            self.view.sendSubviewToBack(self.viewForScreenshot)

            self.textField.layer.borderColor = c.CGColor
            self.textField.layer.borderWidth = 2
            self.colorView.backgroundColor = c
            self.graphView.vs = self.vs_accum
            self.graphView.vs_count = self.vs_count
            self.graphView.setNeedsDisplay()
            self.infoView.lab = lab
            self.infoView.setNeedsDisplay()
            
            if(self.timer_count >= 50) {
                self.timer_count = 0
                let layer = UIApplication.sharedApplication().keyWindow!.layer
                let scale = UIScreen.mainScreen().scale
                UIGraphicsBeginImageContextWithOptions(layer.frame.size, false, scale);
                
                layer.renderInContext(UIGraphicsGetCurrentContext()!)
                let screenshot = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext();
                
                //キャプチャ画像をフォトアルバムへ保存
                UIImageWriteToSavedPhotosAlbum(screenshot, nil, nil, nil);
            }

            //            NSLog(c.description)
        }
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0)
        return (imageRefOpt,newContext)
    }
    
    //x,yが入れ替わっていることに注意（これで正しく動いている）
    private func measure(ctx: CGContextRef) -> [Float] {
        let w_scale = 0.1

        let x_offset : Int = 640/2-Int(480*w_scale*0.5)
        let y_offset : Int = 480/2-Int(480*w_scale*0.5)
        
        let w : Int = Int(480*w_scale) // CGBitmapContextGetWidth(ctx)
        let h : Int = Int(480*w_scale) // CGBitmapContextGetHeight(ctx)
        let dat: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer<UInt8>(CGBitmapContextGetData(ctx))
        var accum : [Int] = [0,0,0,0]
        for x in x_offset..<(x_offset+w) {
            for y in y_offset..<(y_offset+h) {
                let bi = 4*(y*640+x)
                accum[0] += Int(dat[bi])
                accum[1] += Int(dat[bi+1])
                accum[2] += Int(dat[bi+2])
                accum[3] += Int(dat[bi+3])
            }
        }
        
        return accum.map{Float($0)/Float(w*h)}
    }
    
    func startRecording() {
        let recorder = RPScreenRecorder.sharedRecorder()
        NSLog("%@",recorder)

        recorder.startRecordingWithMicrophoneEnabled(true) { [unowned self] (error) in
            if let unwrappedError = error {
                print(unwrappedError.localizedDescription)
            } else {
//                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Stop", style: .Plain, target: self, action: "stopRecording")
            }
        }
    }
    
    func stopRecording() {
        let recorder = RPScreenRecorder.sharedRecorder()
        
        recorder.stopRecordingWithHandler { [unowned self] (preview, error) in
//            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Start", style: .Plain, target: self, action: "startRecording")
            
            if let unwrappedPreview = preview {
                unwrappedPreview.previewControllerDelegate = self
                self.presentViewController(unwrappedPreview, animated: true, completion: nil)
            }
        }
    }
    @IBOutlet weak var viewForScreenshot: UIImageView!
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!)
    {
        if(!running){
            return
        }
        let time = CACurrentMediaTime()
        //        if (prevCaptureTime == nil || time-prevCaptureTime >= 0.1) {
        prevCaptureTime = time
        dispatch_async(dispatch_get_main_queue(), {
            self.count += 1
            self.textField.text = String(self.count)
            let (cgImg,ctx) = self.captureImage(sampleBuffer)
            let cropped = CGImageCreateWithImageInRect(cgImg,CGRectMake(640/2-48,480/2-48,96,96))!  //x,yが入れ替わっていることに注意
            let resultImage = UIImage(CGImage: cropped, scale: 1.0, orientation: UIImageOrientation.Right)
            let image : UIImage? = resultImage
            self.view2.image = image
            
            
        })
        //        }
    }
    
    @IBAction func captureHandler(sender: AnyObject) {
        if(running){
            running = false
            button.setTitle("Start", forState: UIControlState.Normal)
            textField.text = ""
            //x            mySession.stopRunning()
            self.vs_count = 0
            //            imageView.image = nil
            stopRecording()
        }else{
            setCameraMode()
            
            if(!mySession.running){
                mySession.startRunning()
                startRecording()
            }
            running = true
            button.setTitle("Stop", forState: UIControlState.Normal)
            initialTime = CACurrentMediaTime()
            prevCaptureTime = initialTime
            
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.mySession.stopRunning()
        
    }
    
}

