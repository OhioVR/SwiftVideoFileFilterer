import UIKit
import GPUImage
import MobileCoreServices

import iAd
import CoreData


var filterPreviewVideoURL: NSURL!
var videoPreviewURL: NSURL!
class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, NSFetchedResultsControllerDelegate, ADBannerViewDelegate  {

    
    //iad http://www.learnswiftonline.com/reference-guides/adding-iad-swift-app/
    ///////var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil
    let mediumRectAdView = ADBannerView(adType: ADAdType.MediumRectangle) //Create banner
    var thinBanner = ADBannerView(adType: ADAdType.Banner)!
    
    var filters = ["Brightness", "Gamma", "Exposure", "Contrast", "Hue", "Saturation", "Amatorka Filter", "Soft Elegance Filter", "Color Invert Filter", "Grayscale Filter", "Miss Etikate Filter", "Sepia Filter", "Sharpen Filter", "Toon Filter", "Median Filter", "Non Maximum Suppression Filter", "Motion Detector", "Pixellate Filter", "Polar Pixellate Filter", "Polka Dot Filter", "Emboss Filter", "Posterize Filter", "Swirl Filter", "Bulge Distortion Filter", "Pinch Distortion Filter", "Stretch Distortion Filter", "Sphere Refraction Filter", "Vignette Filter", "Kuwahara Filter", "CGA Colorspace Filter", "Green Matrix Filter", "RGB Filter", "Highlight Shadow Filter", "Monochrome Filter", "False Color Filter", "Haze Filter", "Gaussian Blur Filter", "Box Blur Filter", "Tilt Shift Filter", "Motion Blur Filter", "Zoom Blur Filter", "Sketch Filter", "Low Pass Filter", "High Pass Filter", "Halftone Filter", "Adaptive Threshold Filter", "Crosshatch Filter", "Luminance Threshold Filter", "XY Derivative Filter", "Local Binary Pattern Filter", "Erosion Filter", "Dilation Filter"]
    
    let transitionManager = TransitionManager()
    
    
    //non useful or inoperational filters:
    //, "Average Luminance Threshold Filter", "Histogram Filter", "Line Generator", "JFA Voronoi Filter", "Threshold Sketch Filter"
    
    
    /*
     *  UIPickerView Protocol
     */
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.filters.count
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.filters[row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.pickedTextField.text = self.filters[row]
        //self.pickedTextField.resignFirstResponder()
    }
    
    var pickedTextField: UITextField!
    var filterPicker: UIPickerView = UIPickerView()
    var filterPickerResetVal: String!
    var filterPickerResetParamVal: [AnyObject]!
    var filterPickerResetIndex: Int!
    
    var toolBar = UIToolbar()
    var doneButton: UIBarButtonItem!
    var spaceButton = UIBarButtonItem()
    var cancelButton = UIBarButtonItem()
    
    ///
    
    struct aFilterS {
        var filterName:String
        var parameters: [AnyObject]
    }
    var tableData: [aFilterS]! = []

    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var previewImage: UIImageView!
    @IBOutlet var theTableView: UITableView!
    var canEditTable = false;
    var previewUIImage: UIImage!
    var videoSourceSize: CGSize!
    var cancelProcessingButton: UIButton!

    let imagePicker = UIImagePickerController()
    let filterPickerDoneButton = UIButton()

    var movieWriter: GPUImageMovieWriter!
    var movieFile: GPUImageMovie!
    var pathToMovie: String!
    var timer: NSTimer!
    var pickedMovieUrl: NSURL!
    
    static let START = "start"
    static let SELECT = "select video"
    static let PROCESS = "process video"
    static var programMode: String!
    
    static var previewType: String!
    static let PREFILTER = "Prefilter"
    static let POSTFILTER = "Post filter"
    
    //processing overlay
    var blurEffectView: UIVisualEffectView!
    var progressView: UIProgressView!
    var progressLabel: UILabel!
    
    // menu
    @IBOutlet var newButton: UIBarButtonItem!
    @IBOutlet var processItButton: UIBarButtonItem!
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var aboutButton: UIBarButtonItem!

    @IBAction func newProject(sender: AnyObject) {
            imagePicker.allowsEditing = true
            imagePicker.sourceType = .SavedPhotosAlbum
            imagePicker.mediaTypes = [kUTTypeMovie as String]
            imagePicker.videoQuality = UIImagePickerControllerQualityType.TypeMedium;
            presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    
    
    @IBAction func beginProcessing(sender: AnyObject) {
        movieFile = GPUImageMovie(URL: pickedMovieUrl)
        var filterList: [GPUImageOutput] = []

        for filter in tableData {
            switch (filter.filterName){
            case "Brightness":
                let myGPUFilter = GPUImageBrightnessFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.brightness = myParameter
                filterList.append(myGPUFilter)
                break
            case "Motion Blur Filter":
                let myGPUFilter = GPUImageMotionBlurFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                let myParameter1 = filter.parameters[1] as! CGFloat
                myGPUFilter.blurSize = myParameter
                myGPUFilter.blurAngle = myParameter1
                filterList.append(myGPUFilter)
                break
            case "Tilt Shift Filter":
                let myGPUFilter = GPUImageTiltShiftFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.blurRadiusInPixels = myParameter
                filterList.append(myGPUFilter)
                break
            case "Gaussian Blur Filter":
                let myGPUFilter = GPUImageGaussianBlurFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.blurRadiusInPixels = myParameter
                filterList.append(myGPUFilter)
                break
            case "Box Blur Filter":
                let myGPUFilter = GPUImageBoxBlurFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.blurRadiusInPixels = myParameter
                filterList.append(myGPUFilter)
                break
            case "RGB Filter":
                let myGPUFilter = GPUImageRGBFilter()
                let myParameter1 = filter.parameters[0] as! CGFloat
                let myParameter2 = filter.parameters[1] as! CGFloat
                let myParameter3 = filter.parameters[2] as! CGFloat
                myGPUFilter.red = myParameter1
                myGPUFilter.green = myParameter2
                myGPUFilter.blue = myParameter3
                filterList.append(myGPUFilter)
                break
            case "Zoom Blur Filter":
                let myGPUFilter = GPUImageZoomBlurFilter()
                let myParameter1 = filter.parameters[0] as! CGFloat
                let myParameter2 = filter.parameters[1] as! CGFloat
                let myParameter3 = filter.parameters[2] as! CGFloat
                myGPUFilter.blurSize = myParameter1
                myGPUFilter.blurCenter = CGPointMake(myParameter2, myParameter3)
                filterList.append(myGPUFilter)
                break
            case "Sketch Filter":
                let myGPUFilter = GPUImageSketchFilter()
                let myParameter1 = filter.parameters[0] as! CGFloat
                let myParameter2 = filter.parameters[1] as! CGFloat
                let myParameter3 = filter.parameters[2] as! CGFloat
                myGPUFilter.texelWidth = myParameter1
                myGPUFilter.texelHeight = myParameter2
                myGPUFilter.edgeStrength = myParameter3
                filterList.append(myGPUFilter)
                break
            case "Threshold Sketch Filter":
                let myGPUFilter = GPUImageThresholdSketchFilter()
                let myParameter1 = filter.parameters[0] as! CGFloat
                let myParameter2 = filter.parameters[1] as! CGFloat
                let myParameter3 = filter.parameters[2] as! CGFloat
                myGPUFilter.texelWidth = myParameter1
                myGPUFilter.texelHeight = myParameter2
                myGPUFilter.edgeStrength = myParameter3
                filterList.append(myGPUFilter)
                break
            case "Highlight Shadow Filter":
                let myGPUFilter = GPUImageHighlightShadowFilter()
                let myParameter1 = filter.parameters[0] as! CGFloat
                let myParameter2 = filter.parameters[1] as! CGFloat
                myGPUFilter.shadows = myParameter1
                myGPUFilter.highlights = myParameter2
                filterList.append(myGPUFilter)
                break
            case "Haze Filter":
                let myGPUFilter = GPUImageHazeFilter()
                let myParameter1 = filter.parameters[0] as! CGFloat
                let myParameter2 = filter.parameters[1] as! CGFloat
                myGPUFilter.distance = myParameter1
                myGPUFilter.slope = myParameter2
                filterList.append(myGPUFilter)
                break
            case "Monochrome Filter":
                let myGPUFilter = GPUImageMonochromeFilter()
                let myParameter1 = filter.parameters[0] as! CGFloat
                let red = filter.parameters[1] as! Float
                let green = filter.parameters[2] as! Float
                let blue = filter.parameters[3] as! Float
                myGPUFilter.intensity = myParameter1
                myGPUFilter.color = GPUVector4(one: red,two: green,three: blue,four: 1)
                filterList.append(myGPUFilter)
                break
            case "Toon Filter":
                let myGPUFilter = GPUImageToonFilter()
                let myParameter1 = filter.parameters[0] as! CGFloat
                let myParameter2 = filter.parameters[1] as! CGFloat
                let myParameter3 = filter.parameters[2] as! CGFloat
                let myParameter4 = filter.parameters[3] as! CGFloat
                myGPUFilter.texelWidth = myParameter1
                myGPUFilter.texelHeight = myParameter2
                myGPUFilter.threshold = myParameter3
                myGPUFilter.quantizationLevels = myParameter4
                filterList.append(myGPUFilter)
                break
            case "False Color Filter":
                let myGPUFilter = GPUImageFalseColorFilter()
                let red1 = filter.parameters[0] as! Float
                let green1 = filter.parameters[1] as! Float
                let blue1 = filter.parameters[2] as! Float
                
                let red2 = filter.parameters[3] as! Float
                let green2 = filter.parameters[4] as! Float
                let blue2 = filter.parameters[5] as! Float
                
                myGPUFilter.firstColor = GPUVector4(one: red1,two: green1,three: blue1,four: 1)
                
                myGPUFilter.secondColor = GPUVector4(one: red2,two: green2,three: blue2,four: 1)
                
                filterList.append(myGPUFilter)
                break
            case "Green Matrix Filter":
                let myGPUFilter = GPUImageMosaicFilter()
                //let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.inputTileSize = CGSizeMake(0.1,0.1)
                myGPUFilter.displayTileSize = CGSizeMake(0.025,0.025)
                myGPUFilter.numTiles = 64
                myGPUFilter.colorOn = true
                myGPUFilter.tileSet = "GPUImageMosaicTiles.png"
                filterList.append(myGPUFilter)
                break
            case "JFA Voronoi Filter":
                let myGPUFilter = GPUImageJFAVoronoiFilter()
                let myParameter = filter.parameters[0] as! CGSize
                myGPUFilter.sizeInPixels = myParameter
                filterList.append(myGPUFilter)
                break
            case "Emboss Filter":
                let myGPUFilter = GPUImageEmbossFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.intensity = myParameter
                filterList.append(myGPUFilter)
                break
            case "Posterize Filter":
                let myGPUFilter = GPUImagePosterizeFilter()
                let myParameter = filter.parameters[0] as! UInt
                myGPUFilter.colorLevels = myParameter
                filterList.append(myGPUFilter)
                break
            case "Swirl Filter":
                let myGPUFilter = GPUImageSwirlFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.angle = myParameter
                filterList.append(myGPUFilter)
                break
            case "Bulge Distortion Filter":
                let myGPUFilter = GPUImageBulgeDistortionFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.scale = myParameter
                myGPUFilter.radius = 0.5
                filterList.append(myGPUFilter)
                break
            case "Pinch Distortion Filter":
                let myGPUFilter = GPUImagePinchDistortionFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.scale = myParameter
                myGPUFilter.radius = 0.5
                filterList.append(myGPUFilter)
                break
            case "Stretch Distortion Filter":
                let myGPUFilter = GPUImagePinchDistortionFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.center = CGPointMake(0.5, myParameter)
                filterList.append(myGPUFilter)
                break
            case "Sphere Refraction Filter":
                let myGPUFilter = GPUImageGlassSphereFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.radius = myParameter
                filterList.append(myGPUFilter)
                break
            case "Vignette Filter":
                let myGPUFilter = GPUImageVignetteFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.vignetteEnd = myParameter
                filterList.append(myGPUFilter)
                break
            case "Kuwahara Filter":
                let myGPUFilter = GPUImageKuwaharaFilter()
                let myParameter = filter.parameters[0] as! UInt
                myGPUFilter.radius = myParameter
                filterList.append(myGPUFilter)
                break
            case "Halftone Filter":
                let myGPUFilter = GPUImageHalftoneFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.fractionalWidthOfAPixel = myParameter
                filterList.append(myGPUFilter)
                break
            case "Crosshatch Filter":
                let myGPUFilter = GPUImageCrosshatchFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.crossHatchSpacing = myParameter
                myGPUFilter.lineWidth = myParameter / 10
                filterList.append(myGPUFilter)
                break
            case "Polka Dot Filter":
                let myGPUFilter = GPUImagePolkaDotFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.fractionalWidthOfAPixel = myParameter
                filterList.append(myGPUFilter)
                break
            case "Pixellate Filter":
                let myGPUFilter = GPUImagePixellateFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.fractionalWidthOfAPixel = myParameter
                filterList.append(myGPUFilter)
                break
                
            case "Polar Pixellate Filter":
                let myGPUFilter = GPUImagePolarPixellateFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.pixelSize = CGSizeMake(myParameter, myParameter)
                filterList.append(myGPUFilter)
                break
            case "Motion Detector":
                let myGPUFilter = GPUImageMotionDetector()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.lowPassFilterStrength = myParameter
                filterList.append(myGPUFilter)
                break
            case "GPUImageLineGenerator":
                let myGPUFilter = GPUImageLineGenerator()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.lineWidth = myParameter
                filterList.append(myGPUFilter)
                break
            case "Luminance Threshold Filter":
                let myGPUFilter = GPUImageLuminanceThresholdFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.threshold = myParameter
                filterList.append(myGPUFilter)
                break
            case "Adaptive Threshold Filter":
                let myGPUFilter = GPUImageAdaptiveThresholdFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.blurRadiusInPixels = myParameter
                filterList.append(myGPUFilter)
                break
            case "Sharpen Filter":
                let myGPUFilter = GPUImageSharpenFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.sharpness = myParameter
                filterList.append(myGPUFilter)
                break
            case "Average Luminance Threshold Filter":
                let myGPUFilter = GPUImageAverageLuminanceThresholdFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.thresholdMultiplier = myParameter
                filterList.append(myGPUFilter)
                break
                
                
            case "Histogram Filter":
                let myGPUFilter = GPUImageHistogramFilter()
                let myParameter = filter.parameters[0] as! UInt
                myGPUFilter.downsamplingFactor = myParameter
                filterList.append(myGPUFilter)
                break
                
                
            case "Sepia Filter":
                let myGPUFilter = GPUImageSepiaFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.intensity = myParameter
                filterList.append(myGPUFilter)
                break
            case "Gamma":
                let myGPUFilter = GPUImageGammaFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.gamma = myParameter
                filterList.append(myGPUFilter)
                break
            case "Exposure":
                let myGPUFilter = GPUImageExposureFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.exposure = myParameter
                filterList.append(myGPUFilter)
                break
            case "Contrast":
                let myGPUFilter = GPUImageContrastFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.contrast = myParameter
                filterList.append(myGPUFilter)
                break
            case "Hue":
                let myGPUFilter = GPUImageHueFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.hue = myParameter
                filterList.append(myGPUFilter)
                break
            case "Saturation":
                let myGPUFilter = GPUImageSaturationFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.saturation = myParameter
                filterList.append(myGPUFilter)
            case "Amatorka Filter":
                let myGPUFilter = GPUImageAmatorkaFilter()
                filterList.append(myGPUFilter)
                break
            case "Non Maximum Suppression Filter":
                let myGPUFilter = GPUImageNonMaximumSuppressionFilter()
                filterList.append(myGPUFilter)
                break
                
            case "Dilation Filter":
                let myGPUFilter = GPUImageDilationFilter()
                filterList.append(myGPUFilter)
                break
            case "Erosion Filter":
                let myGPUFilter = GPUImageErosionFilter()
                filterList.append(myGPUFilter)
                break
            case "Local Binary Pattern Filter":
                let myGPUFilter = GPUImageLocalBinaryPatternFilter()
                filterList.append(myGPUFilter)
                break
            case "Low Pass Filter":
                let myGPUFilter = GPUImageLowPassFilter()
                filterList.append(myGPUFilter)
                break
            case "High Pass Filter":
                let myGPUFilter = GPUImageHighPassFilter()
                filterList.append(myGPUFilter)
                break
            case "XY Derivative Filter":
                let myGPUFilter = GPUImageXYDerivativeFilter()
                filterList.append(myGPUFilter)
                break
            case "Median Filter":
                let myGPUFilter = GPUImageMedianFilter()
                filterList.append(myGPUFilter)
                break
            case "Soft Elegance Filter":
                let myGPUFilter = GPUImageSoftEleganceFilter()
                filterList.append(myGPUFilter)
                break
            case "CGA Colorspace Filter":
                let myGPUFilter = GPUImageCGAColorspaceFilter()
                filterList.append(myGPUFilter)
                break
            case "Miss Etikate Filter":
                let myGPUFilter = GPUImageMissEtikateFilter()
                filterList.append(myGPUFilter)
                break
                
            case "Color Invert Filter":
                let myGPUFilter = GPUImageColorInvertFilter()
                filterList.append(myGPUFilter)
                break
                
            case "Grayscale Filter":
                let myGPUFilter = GPUImageGrayscaleFilter()
                filterList.append(myGPUFilter)
                break

            default :
                print("no filter")
            }
        }
        
        if (filterList.count < 1){
            print("nothing to filter")
            alert("Notice:", message: "There are no filters selected.\n\nChoose Add Filter from the menu")
            return
        }
        
        movieFile.addTarget(filterList[0] as! GPUImageInput)
        
        for var i = 0;i<filterList.count-1; i++ {
            if filterList[i] is GPUImageFilter {
                if filterList[i+1] is GPUImageFilter {
                    (filterList[i] as! GPUImageFilter).addTarget(filterList[i+1] as! GPUImageFilter)
                } else {
                    (filterList[i] as! GPUImageFilter).addTarget(filterList[i+1] as! GPUImageFilterGroup)
                }
            } else {
                if filterList[i+1] is GPUImageFilter {
                    (filterList[i] as! GPUImageFilterGroup).addTarget(filterList[i+1] as! GPUImageFilter)
                } else {
                    (filterList[i] as! GPUImageFilterGroup).addTarget(filterList[i+1] as! GPUImageFilterGroup)
                }
            }
        }
        
        let tmpdir = NSTemporaryDirectory()
        pathToMovie = "\(tmpdir)output.mov"
        
        unlink(pathToMovie)//unlink deletes a file
        filterPreviewVideoURL = NSURL.fileURLWithPath(pathToMovie)
        
        movieWriter = GPUImageMovieWriter(movieURL: filterPreviewVideoURL, size: videoSourceSize)//now the  output size is always the same as the input
        movieWriter.encodingLiveVideo = false;//https://github.com/BradLarson/GPUImage/issues/1108
        
        if filterList.last is GPUImageFilter {
            (filterList.last as! GPUImageFilter).addTarget(movieWriter)
        } else if filterList.last is GPUImageFilterGroup {
            (filterList.last as! GPUImageFilterGroup).addTarget(movieWriter)
        }
        
        movieWriter.shouldPassthroughAudio = true
        movieFile.audioEncodingTarget = movieWriter
        movieFile.enableSynchronizedEncodingUsingMovieWriter(movieWriter)
        movieWriter.startRecording()
        movieFile.startProcessing()
        
        timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "progress", userInfo: nil, repeats: true)
        progressView!.alpha = 1.0
        statusLabel.alpha = 1.0
        self.view.addSubview(blurEffectView)
        mediumRectAdView!.hidden = false
        self.view.bringSubviewToFront(mediumRectAdView)
        
    }
    
    func cancelProcessingPress(sender: UIButton){
        print("do cancel now")
        self.movieWriter.cancelRecording()//.cancelProcessing()
        backFromProcessing()
        ViewController.previewType = ViewController.PREFILTER
    }
    
    @IBAction func saveFile(sender: AnyObject) {
            if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(self.pathToMovie) {
                UISaveVideoAtPathToSavedPhotosAlbum(self.pathToMovie as String, self, "savingCallBack:didFinishSavingWithError:contextInfo:", nil)
            } else {
                print("the file must be bad!")
            }
    }
    
    @IBAction func aboutButton(sender: AnyObject) {
        let appName = NSBundle.mainBundle().infoDictionary!["CFBundleDisplayName"] as! String
        alert("About", message: "\(appName)\n\nWritten by Scott Yannitell \n\nImage Filters provided by GPUImage:\n\nA project led and developed by Brad Larson.\n\nGet the source code for this program and GPUImage at github.com\n\nNeed an app developed?\n\ntxt me at 740 396 5922")
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return canEditTable
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true // Yes, the table view can be reordered
    }
 
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            // handle delete (by removing the data from your array and updating the tableview)
            tableData.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            //fielble
            tableView.reloadData()
            updatePreviewImage1()
        }
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        // update the item in my data source by first removing at the from index, then inserting at the to index.
        let item = tableData[fromIndexPath.row]
        tableData.removeAtIndex(fromIndexPath.row)
        tableData.insert(item, atIndex: toIndexPath.row)
        tableView.reloadData()
        updatePreviewImage1()
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        
        let cell: AnyObject = self.tableView(tableView, cellForRowAtIndexPath: indexPath)
        
        if cell.isKindOfClass(ThreeSliderCell) {
           return 179
        } else if cell.isKindOfClass(TwoSliderCell){
            return 145
        } else if cell.isKindOfClass(SingleSliderCell){
            return 120
        } else if cell.isKindOfClass(FourSliderCell){
            return 220
        } else if cell.isKindOfClass(SixSliderCell){
            return 297
        }
        
        //flieble
        return 92;//default row height
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let filterName = tableData[indexPath.row].filterName
        switch (filterName){
        case "tap to select filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("OnlyNameCell") as! OnlyNameCell
            cell.filterField.text! = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.tag = indexPath.row
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            return cell
        case "Amatorka Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("OnlyNameCell") as! OnlyNameCell
            cell.filterField.text! = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.tag = indexPath.row
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            return cell
        case "Non Maximum Suppression Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("OnlyNameCell") as! OnlyNameCell
            cell.filterField.text! = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.tag = indexPath.row
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            return cell
        case "Dilation Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("OnlyNameCell") as! OnlyNameCell
            cell.filterField.text! = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.tag = indexPath.row
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            return cell
        case "Erosion Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("OnlyNameCell") as! OnlyNameCell
            cell.filterField.text! = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.tag = indexPath.row
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            return cell
        case "Local Binary Pattern Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("OnlyNameCell") as! OnlyNameCell
            cell.filterField.text! = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.tag = indexPath.row
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            return cell
        case "Low Pass Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("OnlyNameCell") as! OnlyNameCell
            cell.filterField.text! = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.tag = indexPath.row
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            return cell
        case "High Pass Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("OnlyNameCell") as! OnlyNameCell
            cell.filterField.text! = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.tag = indexPath.row
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            return cell
        case "XY Derivative Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("OnlyNameCell") as! OnlyNameCell
            cell.filterField.text! = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.tag = indexPath.row
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            return cell
        case "Median Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("OnlyNameCell") as! OnlyNameCell
            cell.filterField.text! = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.tag = indexPath.row
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            return cell
            
        case "Grayscale Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("OnlyNameCell") as! OnlyNameCell
            cell.filterField.text! = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.tag = indexPath.row
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            return cell
        case "Soft Elegance Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("OnlyNameCell") as! OnlyNameCell
            cell.filterField.text! = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.tag = indexPath.row
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            return cell
        case "CGA Colorspace Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("OnlyNameCell") as! OnlyNameCell
            cell.filterField.text! = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.tag = indexPath.row
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            return cell
        case "Miss Etikate Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("OnlyNameCell") as! OnlyNameCell
            cell.filterField.text! = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.tag = indexPath.row
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            return cell
        case "Color Invert Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("OnlyNameCell") as! OnlyNameCell
            cell.filterField.text! = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.tag = indexPath.row
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            return cell
        case "Brightness":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 1
            cell.slider.minimumValue = -1
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float
            return cell
            
        case "Motion Blur Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("TwoSliderCell") as! TwoSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row

            cell.slider1.maximumValue = 16
            cell.slider1.minimumValue = 0
            cell.slider1.continuous = true
            cell.slider1.addTarget(self, action: "slider1Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider1.tag = indexPath.row
            cell.slider1.value = tableData[indexPath.row].parameters[0] as! Float
            
            cell.slider2.maximumValue = 360
            cell.slider2.minimumValue = -360
            cell.slider2.continuous = true
            cell.slider2.addTarget(self, action: "slider2Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider2.tag = indexPath.row
            cell.slider2.value = tableData[indexPath.row].parameters[1] as! Float
            
            cell.label1.text = "amount"
            cell.label2.text = "angle"
            return cell
        case "Tilt Shift Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 16
            cell.slider.minimumValue = 0
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float
            return cell
        case "Gaussian Blur Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 64
            cell.slider.minimumValue = 0
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float
            return cell
        case "Box Blur Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 64
            cell.slider.minimumValue = 0
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float
            return cell
        case "RGB Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("ThreeSliderCell") as! ThreeSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            
            cell.slider1.maximumValue = 1
            cell.slider1.minimumValue = 0
            cell.slider1.continuous = true
            cell.slider1.addTarget(self, action: "slider1Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider1.tag = indexPath.row
            cell.slider1.value = tableData[indexPath.row].parameters[0] as! Float
            
            cell.slider2.maximumValue = 1
            cell.slider2.minimumValue = 0
            cell.slider2.continuous = true
            cell.slider2.addTarget(self, action: "slider2Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider2.tag = indexPath.row
            cell.slider2.value = tableData[indexPath.row].parameters[1] as! Float
            
            cell.slider3.maximumValue = 1
            cell.slider3.minimumValue = 0
            cell.slider3.continuous = true
            cell.slider3.addTarget(self, action: "slider3Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider3.tag = indexPath.row
            cell.slider3.value = tableData[indexPath.row].parameters[2] as! Float
            
            cell.label1.text = "red"
            cell.label2.text = "green"
            cell.label3.text = "blue"
            
            return cell
        case "Zoom Blur Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("ThreeSliderCell") as! ThreeSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            
            cell.slider1.maximumValue = 32
            cell.slider1.minimumValue = 0
            cell.slider1.continuous = true
            cell.slider1.addTarget(self, action: "slider1Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider1.tag = indexPath.row
            cell.slider1.value = tableData[indexPath.row].parameters[0] as! Float
            
            cell.slider2.maximumValue = 1
            cell.slider2.minimumValue = 0
            cell.slider2.continuous = true
            cell.slider2.addTarget(self, action: "slider2Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider2.tag = indexPath.row
            cell.slider2.value = tableData[indexPath.row].parameters[1] as! Float
            
            cell.slider3.maximumValue = 1
            cell.slider3.minimumValue = 0
            cell.slider3.continuous = true
            cell.slider3.addTarget(self, action: "slider3Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider3.tag = indexPath.row
            cell.slider3.value = tableData[indexPath.row].parameters[2] as! Float
            
            cell.label1.text = "blur size"
            cell.label2.text = "x"
            cell.label3.text = "y"
            
            return cell
            
        case "Sketch Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("ThreeSliderCell") as! ThreeSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            
            cell.slider1.maximumValue = 0.1
            cell.slider1.minimumValue = 0
            cell.slider1.continuous = true
            cell.slider1.addTarget(self, action: "slider1Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider1.tag = indexPath.row
            cell.slider1.value = tableData[indexPath.row].parameters[0] as! Float
            
            cell.slider2.maximumValue = 0.1
            cell.slider2.minimumValue = 0
            cell.slider2.continuous = true
            cell.slider2.addTarget(self, action: "slider2Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider2.tag = indexPath.row
            cell.slider2.value = tableData[indexPath.row].parameters[1] as! Float
            
            cell.slider3.maximumValue = 4
            cell.slider3.minimumValue = 0
            cell.slider3.continuous = true
            cell.slider3.addTarget(self, action: "slider3Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider3.tag = indexPath.row
            cell.slider3.value = tableData[indexPath.row].parameters[2] as! Float
            
            cell.label1.text = "texel width"
            cell.label2.text = "texel height"
            cell.label3.text = "edge strength"
            
            return cell

        case "Threshold Sketch Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("ThreeSliderCell") as! ThreeSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            
            cell.slider1.maximumValue = 0.1
            cell.slider1.minimumValue = 0
            cell.slider1.continuous = true
            cell.slider1.addTarget(self, action: "slider1Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider1.tag = indexPath.row
            cell.slider1.value = tableData[indexPath.row].parameters[0] as! Float
            
            cell.slider2.maximumValue = 0.1
            cell.slider2.minimumValue = 0
            cell.slider2.continuous = true
            cell.slider2.addTarget(self, action: "slider2Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider2.tag = indexPath.row
            cell.slider2.value = tableData[indexPath.row].parameters[1] as! Float
            
            cell.slider3.maximumValue = 4
            cell.slider3.minimumValue = 0
            cell.slider3.continuous = true
            cell.slider3.addTarget(self, action: "slider3Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider3.tag = indexPath.row
            cell.slider3.value = tableData[indexPath.row].parameters[2] as! Float
            
            cell.label1.text = "texel width"
            cell.label2.text = "texel height"
            cell.label3.text = "edge strength"
            
            return cell
        case "Highlight Shadow Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("TwoSliderCell") as! TwoSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            
            cell.slider1.maximumValue = 1
            cell.slider1.minimumValue = 0
            cell.slider1.continuous = true
            cell.slider1.addTarget(self, action: "slider1Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider1.tag = indexPath.row
            cell.slider1.value = tableData[indexPath.row].parameters[0] as! Float
            
            cell.slider2.maximumValue = 1
            cell.slider2.minimumValue = 0
            cell.slider2.continuous = true
            cell.slider2.addTarget(self, action: "slider2Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider2.tag = indexPath.row
            cell.slider2.value = tableData[indexPath.row].parameters[1] as! Float
            
            cell.label1.text = "shadows"
            cell.label2.text = "highlights"
            
            return cell
        case "Haze Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("TwoSliderCell") as! TwoSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            
            cell.slider1.maximumValue = 0.3
            cell.slider1.minimumValue = -0.3
            cell.slider1.continuous = true
            cell.slider1.addTarget(self, action: "slider1Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider1.tag = indexPath.row
            cell.slider1.value = tableData[indexPath.row].parameters[0] as! Float
            
            cell.slider2.maximumValue = 0.3
            cell.slider2.minimumValue = -0.3
            cell.slider2.continuous = true
            cell.slider2.addTarget(self, action: "slider2Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider2.tag = indexPath.row
            cell.slider2.value = tableData[indexPath.row].parameters[1] as! Float
            
            cell.label1.text = "distance"
            cell.label2.text = "slope"
            
            return cell
        case "Monochrome Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("FourSliderCell") as! FourSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            
            cell.slider1.maximumValue = 1
            cell.slider1.minimumValue = 0
            cell.slider1.continuous = true
            cell.slider1.addTarget(self, action: "slider1Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider1.tag = indexPath.row
            cell.slider1.value = tableData[indexPath.row].parameters[0] as! Float
            
            cell.slider2.maximumValue = 1
            cell.slider2.minimumValue = 0
            cell.slider2.continuous = true
            cell.slider2.addTarget(self, action: "slider2Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider2.tag = indexPath.row
            cell.slider2.value = tableData[indexPath.row].parameters[1] as! Float
            
            cell.slider3.maximumValue = 1
            cell.slider3.minimumValue = 0
            cell.slider3.continuous = true
            cell.slider3.addTarget(self, action: "slider3Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider3.tag = indexPath.row
            cell.slider3.value = tableData[indexPath.row].parameters[2] as! Float
            
            cell.slider4.maximumValue = 1
            cell.slider4.minimumValue = 0
            cell.slider4.continuous = true
            cell.slider4.addTarget(self, action: "slider4Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider4.tag = indexPath.row
            cell.slider4.value = tableData[indexPath.row].parameters[3] as! Float
            
            
            cell.label1.text = "intensity"
            cell.label2.text = "red"
            cell.label3.text = "green"
            cell.label4.text = "blue"
            return cell
        case "Toon Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("FourSliderCell") as! FourSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            
            cell.slider1.maximumValue = 0.01
            cell.slider1.minimumValue = 0
            cell.slider1.continuous = true
            cell.slider1.addTarget(self, action: "slider1Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider1.tag = indexPath.row
            cell.slider1.value = tableData[indexPath.row].parameters[0] as! Float
            
            cell.slider2.maximumValue = 0.01
            cell.slider2.minimumValue = 0
            cell.slider2.continuous = true
            cell.slider2.addTarget(self, action: "slider2Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider2.tag = indexPath.row
            cell.slider2.value = tableData[indexPath.row].parameters[1] as! Float
            
            cell.slider3.maximumValue = 1
            cell.slider3.minimumValue = 0
            cell.slider3.continuous = true
            cell.slider3.addTarget(self, action: "slider3Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider3.tag = indexPath.row
            cell.slider3.value = tableData[indexPath.row].parameters[2] as! Float
            
            cell.slider4.maximumValue = 10
            cell.slider4.minimumValue = 2
            cell.slider4.continuous = true
            cell.slider4.addTarget(self, action: "slider4Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider4.tag = indexPath.row
            cell.slider4.value = tableData[indexPath.row].parameters[3] as! Float
            
            
            cell.label1.text = "texel width"
            cell.label2.text = "texel height"
            cell.label3.text = "threshold"
            cell.label4.text = "Q level"
            return cell
        case "False Color Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SixSliderCell") as! SixSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            
            cell.slider1.maximumValue = 1
            cell.slider1.minimumValue = 0
            cell.slider1.continuous = true
            cell.slider1.addTarget(self, action: "slider1Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider1.tag = indexPath.row
            cell.slider1.value = tableData[indexPath.row].parameters[0] as! Float
            
            cell.slider2.maximumValue = 1
            cell.slider2.minimumValue = 0
            cell.slider2.continuous = true
            cell.slider2.addTarget(self, action: "slider2Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider2.tag = indexPath.row
            cell.slider2.value = tableData[indexPath.row].parameters[1] as! Float
            
            cell.slider3.maximumValue = 1
            cell.slider3.minimumValue = 0
            cell.slider3.continuous = true
            cell.slider3.addTarget(self, action: "slider3Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider3.tag = indexPath.row
            cell.slider3.value = tableData[indexPath.row].parameters[2] as! Float
            
            cell.slider4.maximumValue = 1
            cell.slider4.minimumValue = 0
            cell.slider4.continuous = true
            cell.slider4.addTarget(self, action: "slider4Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider4.tag = indexPath.row
            cell.slider4.value = tableData[indexPath.row].parameters[3] as! Float
            
            cell.slider5.maximumValue = 1
            cell.slider5.minimumValue = 0
            cell.slider5.continuous = true
            cell.slider5.addTarget(self, action: "slider5Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider5.tag = indexPath.row
            cell.slider5.value = tableData[indexPath.row].parameters[4] as! Float
            
            cell.slider6.maximumValue = 1
            cell.slider6.minimumValue = 0
            cell.slider6.continuous = true
            cell.slider6.addTarget(self, action: "slider6Changed:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider6.tag = indexPath.row
            cell.slider6.value = tableData[indexPath.row].parameters[5] as! Float
            
            
            
            cell.label1.text = "1 red"
            cell.label2.text = "1 green"
            cell.label3.text = "1 blue"
            cell.label4.text = "2 red"
            cell.label5.text = "2 green"
            cell.label6.text = "2 blue"
            return cell
        case "Green Matrix Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 8
            cell.slider.minimumValue = 1
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float
            return cell
        case "Emboss Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 4
            cell.slider.minimumValue = 0
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float //sliderValuesArray.objectAtIndex(indexPath.row).intValue()
            return cell
        case "Posterize Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 16
            cell.slider.minimumValue = 1
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float //
            return cell
            
        case "Swirl Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 1
            cell.slider.minimumValue = -1
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float //
            return cell
        case "Bulge Distortion Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 1
            cell.slider.minimumValue = -1
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float //
            return cell
        case "Pinch Distortion Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 1
            cell.slider.minimumValue = -1
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float //
            return cell
        case "Stretch Distortion Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 1
            cell.slider.minimumValue = 0
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float //
            return cell
        case "Sphere Refraction Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 1
            cell.slider.minimumValue = 0
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float //
            return cell
        case "Vignette Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 1
            cell.slider.minimumValue = 0.5
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float //
            return cell
        case "Vignette Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 1
            cell.slider.minimumValue = 0.5
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float //
            return cell
        case "Kuwahara Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 6
            cell.slider.minimumValue = 1
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float
            return cell
        case "Halftone Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 0.1
            cell.slider.minimumValue = 0.01
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float
            return cell
        case "Crosshatch Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 0.12
            cell.slider.minimumValue = 0.01
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float
            return cell
        case "Polka Dot Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 0.25
            cell.slider.minimumValue = 0.01
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float //sliderValuesArray.objectAtIndex(indexPath.row).intValue()
            return cell
        case "Pixellate Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 0.25
            cell.slider.minimumValue = 0
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float //sliderValuesArray.objectAtIndex(indexPath.row).intValue()
            return cell
        case "Pixellate Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 0.25
            cell.slider.minimumValue = 0
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float //sliderValuesArray.objectAtIndex(indexPath.row).intValue()
            return cell
        case "Polar Pixellate Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 0.25
            cell.slider.minimumValue = 0.01
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float //sliderValuesArray.objectAtIndex(indexPath.row).intValue()
            return cell
            
        case "Line Generator":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 8
            cell.slider.minimumValue = 1
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float //sliderValuesArray.objectAtIndex(indexPath.row).intValue()
            return cell
        case "Luminance Threshold Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 1
            cell.slider.minimumValue = 0
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float //sliderValuesArray.objectAtIndex(indexPath.row).intValue()
            return cell
        case "Adaptive Threshold Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 20
            cell.slider.minimumValue = 0
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float //sliderValuesArray.objectAtIndex(indexPath.row).intValue()
            return cell
        case "Sharpen Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 2
            cell.slider.minimumValue = 0
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float //sliderValuesArray.objectAtIndex(indexPath.row).intValue()
            return cell
        case "Average Luminance Threshold Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 1
            cell.slider.minimumValue = 0
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float
            return cell
        case "Histogram Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 16
            cell.slider.minimumValue = 1
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float
            return cell
        case "Sepia Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 1
            cell.slider.minimumValue = -1
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float //sliderValuesArray.objectAtIndex(indexPath.row).intValue()
            return cell
        case "Contrast" :
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 4
            cell.slider.minimumValue = 0
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float
            return cell
        case "Gamma" :
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 3
            cell.slider.minimumValue = 0
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float
            return cell
        case "Exposure" :
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 3.5
            cell.slider.minimumValue = -3.5
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float
            return cell
        case "Hue" :
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 360
            cell.slider.minimumValue = -360
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float
            return cell
        case "Saturation" :
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
            cell.filterField.inputAccessoryView = toolBar
            cell.filterField.tag = indexPath.row
            cell.slider.maximumValue = 2
            cell.slider.minimumValue = 0
            cell.slider.continuous = true
            cell.slider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.slider.tag = indexPath.row
            cell.slider.value = tableData[indexPath.row].parameters[0] as! Float
            return cell
        default:
            break;
        }
        
        //if we got to this point we're screwed //yeah I'm sure I'm doing it wrong
        print("shouldn't be here!!!!!!!!!!!! \(filterName)")
        let cell = tableView.dequeueReusableCellWithIdentifier("OnlyNameCell") as! OnlyNameCell
        cell.filterField.text! = tableData[indexPath.row].filterName
        cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
        cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
        cell.filterField.tag = indexPath.row
        cell.filterField.inputView = filterPicker
        cell.filterField.inputAccessoryView = toolBar
        return cell
    }
    
    func pressFilterFieldStart(sender:UITextField!){
        print("field edit begin")
        self.filterPickerResetIndex = sender.tag
        self.filterPickerResetVal = tableData[sender.tag].filterName
        self.filterPickerResetParamVal = tableData[sender.tag].parameters
        self.pickedTextField = sender
    }
    
    func pressFilterFieldEnd(sender:UITextField!){
        var params : [AnyObject] = []
        switch(sender.text!){
        case "Brightness":
            params.append(0)
            break //
        case "Motion Blur Filter":
            params.append(16)
            params.append(45)
            break //
        case "Tilt Shift Filter":
            params.append(6)
        case "Gaussian Blur Filter":
            params.append(4)
            break
        case "Box Blur Filter":
            params.append(4)
            break
        case "RGB Filter":
            params.append(1)
            params.append(1)
            params.append(1)
            break
        case "Zoom Blur Filter":
            params.append(16)
            params.append(0.5)
            params.append(0.5)
            break
        case "Sketch Filter":
            params.append(0.001)
            params.append(0.001)
            params.append(1)
            break
        case "Threshold Sketch Filter":
            params.append(0.001)
            params.append(0.001)
            params.append(1)
            break
        case "Highlight Shadow Filter":
            params.append(0)
            params.append(1)
            break
        case "Haze Filter":
            params.append(0)
            params.append(0)
            break
        case "Monochrome Filter":
            params.append(1)
            params.append(0.6)
            params.append(0.45)
            params.append(0.3)
            break
        case "Toon Filter":
            params.append(0.001)
            params.append(0.001)
            params.append(0.2)
            params.append(10)
            break
        case "False Color Filter":
            params.append(0)
            params.append(0.0)
            params.append(0.5)
            params.append(1.0)
            params.append(0.0)
            params.append(0.0)
            break
        case "Green Matrix Filter":
            params.append(8)
            break
        case "JFA Voronoi Filter":
            params.append(8)
            break
        case "Emboss Filter":
            params.append(1)
            break
        case "Posterize Filter":
            params.append(16)
            break
        case "Swirl Filter":
            params.append(1)
            break
        case "Bulge Distortion Filter":
            params.append(0.6)
            break
        case "Pinch Distortion Filter":
            params.append(0.6)
            break
        case "Stretch Distortion Filter":
            params.append(0.6)
            break
        case "Sphere Refraction Filter":
            params.append(0.25)
            break
        case "Vignette Filter":
            params.append(0.75)
            break
        case "Kuwahara Filter":
            params.append(3)
            break
        case "Halftone Filter":
            params.append(0.05)
            break
        case "Crosshatch Filter":
            params.append(0.03)
            break
        case "Polka Dot Filter":
            params.append(0.05)
            break
        case "Pixellate Filter":
            params.append(0.05)
            break
        case "Polar Pixellate Filter":
            params.append(0.05)
            break
        case "Motion Detector":
            params.append(0.5)
            break
        case "Line Generator":
            params.append(1)
            break
        case "Luminance Threshold Filter":
            params.append(0.5)
            break
        case "Adaptive Threshold Filter":
            params.append(4)
            break
        case "Sharpen Filter":
            params.append(1.4)
            break
        case "Average Luminance Threshold Filter":
            params.append(1)
            break
        case "Histogram Filter":
            params.append(16)
            break
        case "Sepia Filter":
            params.append(0.8)
            break
        case "Contrast":
            params.append(1)
            break
        case "Gamma":
            params.append(1)
            break
        case "Exposure":
            params.append(0)
            break
        case "Hue":
            params.append(0)
            break
        case "Saturation":
            params.append(1)
            break
        default :
            break
        }
        
        self.tableData[sender.tag] = aFilterS(filterName: sender.text!, parameters:params)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.theTableView.reloadData()
            self.updatePreviewImage1()
        })
    }
    
    func sliderChanged(sender: UISlider!){
        tableData[sender.tag].parameters[0] = sender.value
        updatePreviewImage1()
    }
    
    func slider1Changed(sender: UISlider!){
        tableData[sender.tag].parameters[0] = sender.value
        updatePreviewImage1()
    }
    
    func slider2Changed(sender: UISlider!){
        tableData[sender.tag].parameters[1] = sender.value
        updatePreviewImage1()
    }
    
    func slider3Changed(sender: UISlider!){
        tableData[sender.tag].parameters[2] = sender.value
        updatePreviewImage1()
    }
    
    func slider4Changed(sender: UISlider!){
        tableData[sender.tag].parameters[3] = sender.value
        updatePreviewImage1()
    }
    
    func slider5Changed(sender: UISlider!){
        tableData[sender.tag].parameters[4] = sender.value
        updatePreviewImage1()
    }
    
    func slider6Changed(sender: UISlider!){
        tableData[sender.tag].parameters[5] = sender.value
        updatePreviewImage1()
    }
    
    func slider7Changed(sender: UISlider!){
        tableData[sender.tag].parameters[6] = sender.value
        updatePreviewImage1()
    }
    
    func slider8Changed(sender: UISlider!){
        tableData[sender.tag].parameters[7] = sender.value
        updatePreviewImage1()
    }
    
    func slider9Changed(sender: UISlider!){
        tableData[sender.tag].parameters[8] = sender.value
        updatePreviewImage1()
    }
    
    func slider10Changed(sender: UISlider!){
        tableData[sender.tag].parameters[9] = sender.value
        updatePreviewImage1()
    }
    
    func slider11Changed(sender: UISlider!){
        tableData[sender.tag].parameters[10] = sender.value
        updatePreviewImage1()
    }
    
    func slider12Changed(sender: UISlider!){
        tableData[sender.tag].parameters[11] = sender.value
        updatePreviewImage1()
    }
    
    /*
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    */
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        dismissViewControllerAnimated(true, completion: nil)
        pickedMovieUrl = info[UIImagePickerControllerMediaURL] as? NSURL
        
        videoPreviewURL = pickedMovieUrl
        
        
        dispatch_after(0, dispatch_get_main_queue()) {
            //we have to do these tasks on the main thread 
            //otherwise there will be no effect
            self.processItButton.enabled = true
            self.saveButton.enabled = false
            
            self.previewUIImage = self.previewImageForLocalVideo(videoPreviewURL, beginEndRatio: 0.2)
            self.previewImage.image = self.previewUIImage
            self.updatePreviewImage1()
        }
        ViewController.programMode = ViewController.PROCESS
        ViewController.previewType = ViewController.PREFILTER
    }

    //http://stackoverflow.com/questions/8906004/thumbnail-image-of-video
    func previewImageForLocalVideo(url:NSURL, beginEndRatio:Float64) -> UIImage?
    {
        let asset = AVAsset(URL: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        //without these 2 lines the video capture will not be frame accurate:
        imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
        imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    
        let vidLength = asset.duration;
        let seconds = CMTimeGetSeconds(vidLength);
        let timeScaleOfVideo = Float64(vidLength.timescale)
        let positionInTime = Int64(seconds * timeScaleOfVideo * beginEndRatio)
        let timeQ1 = CMTimeMake(positionInTime, vidLength.timescale);
        var actual : CMTime = CMTimeMake(0, 0)
        do {
            let imageRef = try imageGenerator.copyCGImageAtTime(timeQ1, actualTime: &actual)//hmm what does the & mean?
            let image = UIImage(CGImage: imageRef)
            videoSourceSize = image.size
            let size = CGSizeApplyAffineTransform(image.size, CGAffineTransformMakeScale(0.25 * 0.5, 0.25 * 0.5))
            let hasAlpha = false
            let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
            
            UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
            image.drawInRect(CGRect(origin: CGPointZero, size: size))
            
            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return scaledImage
        }
        catch let error as NSError
        {
            print("Image generation failed with error \(error)")
            return nil
        }
    }
    
    
    func updatePreviewImage1() {
        if (previewUIImage == nil){
            return
        }
        
        let stillImageSource: GPUImagePicture = GPUImagePicture(image: previewUIImage)
        
        
        //let stillImageFilter: GPUImageSepiaFilter = GPUImageSepiaFilter()
        //stillImageSource.addTarget(stillImageFilter)

        
        
        
        var filterList: [GPUImageOutput] = []
        
        for filter in tableData {
            switch (filter.filterName){
            case "Brightness":
                let myGPUFilter = GPUImageBrightnessFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.brightness = myParameter
                filterList.append(myGPUFilter)
                break
            case "Motion Blur Filter":
                let myGPUFilter = GPUImageMotionBlurFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                let myParameter1 = filter.parameters[1] as! CGFloat
                myGPUFilter.blurSize = myParameter
                myGPUFilter.blurAngle = myParameter1
                filterList.append(myGPUFilter)
                break
            case "Tilt Shift Filter":
                let myGPUFilter = GPUImageTiltShiftFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.blurRadiusInPixels = myParameter
                filterList.append(myGPUFilter)
                break
            case "Gaussian Blur Filter":
                let myGPUFilter = GPUImageGaussianBlurFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.blurRadiusInPixels = myParameter
                filterList.append(myGPUFilter)
                break
            case "Box Blur Filter":
                let myGPUFilter = GPUImageBoxBlurFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.blurRadiusInPixels = myParameter
                filterList.append(myGPUFilter)
                break
            case "RGB Filter":
                let myGPUFilter = GPUImageRGBFilter()
                let myParameter1 = filter.parameters[0] as! CGFloat
                let myParameter2 = filter.parameters[1] as! CGFloat
                let myParameter3 = filter.parameters[2] as! CGFloat
                myGPUFilter.red = myParameter1
                myGPUFilter.green = myParameter2
                myGPUFilter.blue = myParameter3
                filterList.append(myGPUFilter)
                break
            case "Zoom Blur Filter":
                let myGPUFilter = GPUImageZoomBlurFilter()
                let myParameter1 = filter.parameters[0] as! CGFloat
                let myParameter2 = filter.parameters[1] as! CGFloat
                let myParameter3 = filter.parameters[2] as! CGFloat
                myGPUFilter.blurSize = myParameter1
                myGPUFilter.blurCenter = CGPointMake(myParameter2, myParameter3)
                filterList.append(myGPUFilter)
                break
            case "Sketch Filter":
                let myGPUFilter = GPUImageSketchFilter()
                let myParameter1 = filter.parameters[0] as! CGFloat
                let myParameter2 = filter.parameters[1] as! CGFloat
                let myParameter3 = filter.parameters[2] as! CGFloat
                myGPUFilter.texelWidth = myParameter1
                myGPUFilter.texelHeight = myParameter2
                myGPUFilter.edgeStrength = myParameter3
                filterList.append(myGPUFilter)
                break
            case "Threshold Sketch Filter":
                let myGPUFilter = GPUImageThresholdSketchFilter()
                let myParameter1 = filter.parameters[0] as! CGFloat
                let myParameter2 = filter.parameters[1] as! CGFloat
                let myParameter3 = filter.parameters[2] as! CGFloat
                myGPUFilter.texelWidth = myParameter1
                myGPUFilter.texelHeight = myParameter2
                myGPUFilter.edgeStrength = myParameter3
                filterList.append(myGPUFilter)
                break
            case "Highlight Shadow Filter":
                let myGPUFilter = GPUImageHighlightShadowFilter()
                let myParameter1 = filter.parameters[0] as! CGFloat
                let myParameter2 = filter.parameters[1] as! CGFloat
                myGPUFilter.shadows = myParameter1
                myGPUFilter.highlights = myParameter2
                filterList.append(myGPUFilter)
                break
            case "Haze Filter":
                let myGPUFilter = GPUImageHazeFilter()
                let myParameter1 = filter.parameters[0] as! CGFloat
                let myParameter2 = filter.parameters[1] as! CGFloat
                myGPUFilter.distance = myParameter1
                myGPUFilter.slope = myParameter2
                filterList.append(myGPUFilter)
                break
            case "Monochrome Filter":
                let myGPUFilter = GPUImageMonochromeFilter()
                let myParameter1 = filter.parameters[0] as! CGFloat
                let red = filter.parameters[1] as! Float
                let green = filter.parameters[2] as! Float
                let blue = filter.parameters[3] as! Float
                myGPUFilter.intensity = myParameter1
                myGPUFilter.color = GPUVector4(one: red,two: green,three: blue,four: 1)
                filterList.append(myGPUFilter)
                break
            case "Toon Filter":
                let myGPUFilter = GPUImageToonFilter()
                let myParameter1 = filter.parameters[0] as! CGFloat
                let myParameter2 = filter.parameters[1] as! CGFloat
                let myParameter3 = filter.parameters[2] as! CGFloat
                let myParameter4 = filter.parameters[3] as! CGFloat
                myGPUFilter.texelWidth = myParameter1
                myGPUFilter.texelHeight = myParameter2
                myGPUFilter.threshold = myParameter3
                myGPUFilter.quantizationLevels = myParameter4
                filterList.append(myGPUFilter)
                break
            case "False Color Filter":
                let myGPUFilter = GPUImageFalseColorFilter()
                let red1 = filter.parameters[0] as! Float
                let green1 = filter.parameters[1] as! Float
                let blue1 = filter.parameters[2] as! Float
                
                let red2 = filter.parameters[3] as! Float
                let green2 = filter.parameters[4] as! Float
                let blue2 = filter.parameters[5] as! Float
                
                myGPUFilter.firstColor = GPUVector4(one: red1,two: green1,three: blue1,four: 1)
                
                myGPUFilter.secondColor = GPUVector4(one: red2,two: green2,three: blue2,four: 1)
                
                filterList.append(myGPUFilter)
                break
            case "Green Matrix Filter":
                let myGPUFilter = GPUImageMosaicFilter()
               // let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.inputTileSize = CGSizeMake(0.1,0.1)
                myGPUFilter.displayTileSize = CGSizeMake(0.025,0.025)
                myGPUFilter.numTiles = 64
                myGPUFilter.colorOn = true
                myGPUFilter.tileSet = "GPUImageMosaicTiles.png"
                filterList.append(myGPUFilter)
                break
            case "JFA Voronoi Filter":
                let myGPUFilter = GPUImageJFAVoronoiFilter()
                let myParameter = filter.parameters[0] as! CGSize
                myGPUFilter.sizeInPixels = myParameter
                filterList.append(myGPUFilter)
                break
            case "Emboss Filter":
                let myGPUFilter = GPUImageEmbossFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.intensity = myParameter
                filterList.append(myGPUFilter)
                break
            case "Posterize Filter":
                let myGPUFilter = GPUImagePosterizeFilter()
                let myParameter = filter.parameters[0] as! UInt
                myGPUFilter.colorLevels = myParameter
                filterList.append(myGPUFilter)
                break
            case "Swirl Filter":
                let myGPUFilter = GPUImageSwirlFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.angle = myParameter
                filterList.append(myGPUFilter)
                break
            case "Bulge Distortion Filter":
                let myGPUFilter = GPUImageBulgeDistortionFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.scale = myParameter
                myGPUFilter.radius = 0.5
                filterList.append(myGPUFilter)
                break
            case "Pinch Distortion Filter":
                let myGPUFilter = GPUImagePinchDistortionFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.scale = myParameter
                myGPUFilter.radius = 0.5
                filterList.append(myGPUFilter)
                break
            case "Stretch Distortion Filter":
                let myGPUFilter = GPUImagePinchDistortionFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.center = CGPointMake(0.5, myParameter)
                filterList.append(myGPUFilter)
                break
            case "Sphere Refraction Filter":
                let myGPUFilter = GPUImageGlassSphereFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.radius = myParameter
                filterList.append(myGPUFilter)
                break
            case "Vignette Filter":
                let myGPUFilter = GPUImageVignetteFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.vignetteEnd = myParameter
                filterList.append(myGPUFilter)
                break
            case "Kuwahara Filter":
                let myGPUFilter = GPUImageKuwaharaFilter()
                let myParameter = filter.parameters[0] as! UInt
                myGPUFilter.radius = myParameter
                filterList.append(myGPUFilter)
                break
            case "Halftone Filter":
                let myGPUFilter = GPUImageHalftoneFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.fractionalWidthOfAPixel = myParameter
                filterList.append(myGPUFilter)
                break
            case "Crosshatch Filter":
                let myGPUFilter = GPUImageCrosshatchFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.crossHatchSpacing = myParameter
                myGPUFilter.lineWidth = myParameter / 10
                filterList.append(myGPUFilter)
                break
            case "Polka Dot Filter":
                let myGPUFilter = GPUImagePolkaDotFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.fractionalWidthOfAPixel = myParameter
                filterList.append(myGPUFilter)
                break
            case "Pixellate Filter":
                let myGPUFilter = GPUImagePixellateFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.fractionalWidthOfAPixel = myParameter
                filterList.append(myGPUFilter)
                break
            case "Polar Pixellate Filter":
                let myGPUFilter = GPUImagePolarPixellateFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.pixelSize = CGSizeMake(myParameter, myParameter)
                filterList.append(myGPUFilter)
                break
            case "Motion Detector":
                let myGPUFilter = GPUImageMotionDetector()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.lowPassFilterStrength = myParameter
                filterList.append(myGPUFilter)
                break
            case "Luminance Threshold Filter":
                let myGPUFilter = GPUImageLuminanceThresholdFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.threshold = myParameter
                filterList.append(myGPUFilter)
                break
            case "Adaptive Threshold Filter":
                let myGPUFilter = GPUImageAdaptiveThresholdFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.blurRadiusInPixels = myParameter
                filterList.append(myGPUFilter)
                break
                
            case "Sharpen Filter":
                let myGPUFilter = GPUImageSharpenFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.sharpness = myParameter
                filterList.append(myGPUFilter)
                break
                
            case "Average Luminance Threshold Filter":
                let myGPUFilter = GPUImageAverageLuminanceThresholdFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.thresholdMultiplier = myParameter
                filterList.append(myGPUFilter)
                break
            case "Histogram Filter":
                let myGPUFilter = GPUImageHistogramFilter()
                let myParameter = filter.parameters[0] as! UInt
                myGPUFilter.downsamplingFactor = myParameter
                filterList.append(myGPUFilter)
                break
            case "Sepia Filter":
                let myGPUFilter = GPUImageSepiaFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.intensity = myParameter
                filterList.append(myGPUFilter)
                break
            case "Gamma":
                let myGPUFilter = GPUImageGammaFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.gamma = myParameter
                filterList.append(myGPUFilter)
                break
            case "Exposure":
                let myGPUFilter = GPUImageExposureFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.exposure = myParameter
                filterList.append(myGPUFilter)
                break
            case "Contrast":
                let myGPUFilter = GPUImageContrastFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.contrast = myParameter
                filterList.append(myGPUFilter)
                break
            case "Hue":
                let myGPUFilter = GPUImageHueFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.hue = myParameter
                filterList.append(myGPUFilter)
                break
            case "Saturation":
                let myGPUFilter = GPUImageSaturationFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.saturation = myParameter
                filterList.append(myGPUFilter)
            case "Amatorka Filter":
                let myGPUFilter = GPUImageAmatorkaFilter()
                filterList.append(myGPUFilter)
                break
            case "Non Maximum Suppression Filter":
                let myGPUFilter = GPUImageNonMaximumSuppressionFilter()
                filterList.append(myGPUFilter)
                break
            case "Dilation Filter":
                let myGPUFilter = GPUImageDilationFilter()
                filterList.append(myGPUFilter)
                break
            case "Erosion Filter":
                let myGPUFilter = GPUImageErosionFilter()
                filterList.append(myGPUFilter)
                break
            case "Local Binary Pattern Filter":
                let myGPUFilter = GPUImageLocalBinaryPatternFilter()
                filterList.append(myGPUFilter)
                break
            case "Low Pass Filter":
                let myGPUFilter = GPUImageLowPassFilter()
                filterList.append(myGPUFilter)
                break
            case "High Pass Filter":
                let myGPUFilter = GPUImageHighPassFilter()
                filterList.append(myGPUFilter)
                break
            case "XY Derivative Filter":
                let myGPUFilter = GPUImageXYDerivativeFilter()
                filterList.append(myGPUFilter)
                break
            case "Median Filter":
                let myGPUFilter = GPUImageMedianFilter()
                filterList.append(myGPUFilter)
                break
            case "Soft Elegance Filter":
                let myGPUFilter = GPUImageSoftEleganceFilter()
                filterList.append(myGPUFilter)
                break
            case "CGA Colorspace Filter":
                let myGPUFilter = GPUImageCGAColorspaceFilter()
                filterList.append(myGPUFilter)
                break
            case "Miss Etikate Filter":
                let myGPUFilter = GPUImageMissEtikateFilter()
                filterList.append(myGPUFilter)
                break
            case "Color Invert Filter":
                let myGPUFilter = GPUImageColorInvertFilter()
                filterList.append(myGPUFilter)
                break
                
            case "Grayscale Filter":
                let myGPUFilter = GPUImageGrayscaleFilter()
                filterList.append(myGPUFilter)
                break
                
            default :
                break
            }
        }
        
        if (filterList.count < 1){
           // print("nothing to filter")
            self.previewImage.image = previewUIImage
            return
        }
        
        ////movieFile.addTarget(filterList[0] as! GPUImageInput)
        stillImageSource.addTarget(filterList[0] as! GPUImageInput)
        
        
        for var i = 0;i<filterList.count-1; i++ {
            if filterList[i] is GPUImageFilter {
                if filterList[i+1] is GPUImageFilter {
                    (filterList[i] as! GPUImageFilter).addTarget(filterList[i+1] as! GPUImageFilter)
                } else {
                    (filterList[i] as! GPUImageFilter).addTarget(filterList[i+1] as! GPUImageFilterGroup)
                }
            } else {
                if filterList[i+1] is GPUImageFilter {
                    (filterList[i] as! GPUImageFilterGroup).addTarget(filterList[i+1] as! GPUImageFilter)
                } else {
                    (filterList[i] as! GPUImageFilterGroup).addTarget(filterList[i+1] as! GPUImageFilterGroup)
                }
            }
        }

        
        

        
        filterList.last!.useNextFrameForImageCapture()
        
        
        stillImageSource.processImage()
        let currentFilteredVideoFrame: UIImage = filterList.last!.imageFromCurrentFramebuffer()
        self.previewImage.image = currentFilteredVideoFrame
    }
    
    
    func progress() {
        progressView!.progress = movieFile.progress

        if movieFile.progress == 1.0 {
            backFromProcessing()
            performSegueWithIdentifier("playVideo", sender: nil)
        }
    }
    
    func backFromProcessing(){
        timer.invalidate()
        progressView!.progress = 0
        progressView!.alpha = 0
        statusLabel.alpha = 0
        ViewController.programMode = ViewController.SELECT
        ViewController.previewType = ViewController.POSTFILTER
        blurEffectView.removeFromSuperview()
        mediumRectAdView!.hidden = true
        //self.canDisplayBannerAds = false
        saveButton.enabled = true
    }
    
    func savingCallBack(video: NSString, didFinishSavingWithError error:NSError, contextInfo:UnsafeMutablePointer<Void>){
        print("the file has been saved sucessfully!")
        alert("Notice", message: "Your movie has been saved to the Camera Roll.")
        self.saveButton.enabled = false
    }
    
    func alert(title: String, message: String){
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {(action: UIAlertAction) in
        })
        alert.addAction(defaultAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func editFilterTable(sender: AnyObject) {
        if self.theTableView.editing == true {
            canEditTable = false
            self.theTableView.setEditing(false, animated: true)
        }
        else {
            canEditTable = true
            self.theTableView.setEditing(true, animated: true)
        }
    }



    func panShuttle(rec:UIPanGestureRecognizer) {
        if self.previewUIImage == nil {return}
        let p:CGPoint = rec.locationInView(self.previewImage)
        
        let xVal:Float64 = Float64(p.x / UIScreen.mainScreen().bounds.width)
        self.previewUIImage = self.previewImageForLocalVideo(videoPreviewURL, beginEndRatio: xVal)
        updatePreviewImage1()
        
        switch rec.state {
        case .Began:
            print("began")
            break
        default: break
        }
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("number of filters so far = \(filters.count)")
        filters.sortInPlace()
        imagePicker.delegate = self
        
        previewImage.userInteractionEnabled = true
        
        let singleTap = UITapGestureRecognizer(target: self, action: Selector("previewMovie"))
        singleTap.numberOfTapsRequired = 1


        let pan = UIPanGestureRecognizer(target:self, action:"panShuttle:")
        pan.maximumNumberOfTouches = 1
        pan.minimumNumberOfTouches = 1
        previewImage.addGestureRecognizer(pan)
        
        
      
        previewImage.addGestureRecognizer(singleTap)
        ViewController.programMode = ViewController.START
        ViewController.previewType = "nothing"
        
        theTableView.allowsSelection = false
        let darkBlur = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        blurEffectView = UIVisualEffectView(effect: darkBlur)
        blurEffectView.frame = self.view.bounds
    
        progressView = UIProgressView(progressViewStyle: UIProgressViewStyle.Default)
        progressView?.center = self.view.center
        blurEffectView.alpha = 0.8
        blurEffectView.addSubview(progressView)
        
        //make a purdy photoshop like font
        let titleFont = UIFont(name: "HelveticaNeue-Bold", size: 23)
        let shadow = NSShadow()
        shadow.shadowOffset = CGSizeMake (1.0, 1.0)
        shadow.shadowBlurRadius = 1
        let attributes: NSDictionary = [
            NSFontAttributeName : titleFont!,
            NSStrokeColorAttributeName : UIColor.blackColor(),
            NSStrokeWidthAttributeName : -1.5,
            NSForegroundColorAttributeName : UIColor.whiteColor(),
            NSShadowAttributeName : shadow]
        let title = NSAttributedString(string: "Processing...", attributes: attributes as? [String : AnyObject]) //1
        progressLabel = UILabel(frame: CGRectMake(0, 0, 200, 40)) //2
        progressLabel.center = CGPointMake(UIScreen.mainScreen().bounds.size.width/2, (UIScreen.mainScreen().bounds.size.height/2)-25)
        progressLabel.attributedText = title //3
        progressLabel.textAlignment = .Center; //same as NSTextAlignment.Center
        blurEffectView.addSubview(progressLabel) //4
        progressView!.progress = 0.0
        blurEffectView.removeFromSuperview()
        processItButton.enabled = false
        saveButton.enabled = false
        let tblView =  UIView(frame: CGRectZero)
        theTableView.tableFooterView = tblView
        theTableView.tableFooterView!.hidden = true
        theTableView.backgroundColor = UIColor.lightGrayColor()
        //theTableView.rowHeight = 100
        
        
        cancelProcessingButton = UIButton()
        cancelProcessingButton.setTitle("Cancel", forState: .Normal)
        cancelProcessingButton.frame = CGRectMake(0, 0, 200, 50)
        cancelProcessingButton.center = CGPointMake(UIScreen.mainScreen().bounds.size.width/2, (UIScreen.mainScreen().bounds.size.height/2)+25)
        cancelProcessingButton.addTarget(self, action: "cancelProcessingPress:", forControlEvents: .TouchUpInside)
        blurEffectView.addSubview(cancelProcessingButton)
        
        
        canEditTable = true
        theTableView.setEditing(true, animated: false)
        
        
        filterPicker.delegate = self
        filterPicker.dataSource = self
  
        toolBar = UIToolbar()
        doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: "donePicker")
        spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: "canclePicker")
        toolBar.barStyle = UIBarStyle.Default
        toolBar.translucent = true
        toolBar.tintColor = UIColor(red: 76/255, green: 217/255, blue: 100/255, alpha: 1)
        toolBar.sizeToFit()
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.userInteractionEnabled = true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "goBackGround", name: UIApplicationWillResignActiveNotification, object: nil)
        UIApplication.sharedApplication().idleTimerDisabled = true //prevent app from going to sleep

        
        self.canDisplayBannerAds = true
        mediumRectAdView!.delegate = self;
        mediumRectAdView!.hidden = true

        
        
    }
    
    func goBackGround (){
        print("we've gone to the background")
        if movieWriter == nil {return}
        self.movieWriter.cancelRecording()//.cancelProcessing()
        backFromProcessing()

        
        
        if ViewController.programMode == ViewController.PROCESS {
            alert("Notice:", message: "processing has been canceled")
           // ViewController.programMode = ViewController.SELECT
           // ViewController.previewType = ViewController.PREFILTER
        }
        
    }
    
    func donePicker(){
        print("done now what?")
        self.pickedTextField.resignFirstResponder()
    }
    
    func filterpickerDone(sender: AnyObject) {
        print("are we done yet?")
        self.pickedTextField.resignFirstResponder()
    }
    
    func canclePicker(){
        self.pickedTextField.resignFirstResponder()
        tableData[filterPickerResetIndex].filterName = self.filterPickerResetVal
        tableData[filterPickerResetIndex].parameters = self.filterPickerResetParamVal
    }

    @IBAction func addItem(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableData.append(aFilterS(filterName: "tap to select filter", parameters:[]))
            self.theTableView.reloadData()
            
            //scroll to the bottom
            let indexPath = NSIndexPath(forRow: self.tableData.count-1, inSection: 0)
            self.theTableView.scrollToRowAtIndexPath(indexPath,
                atScrollPosition: UITableViewScrollPosition.Middle, animated: true)        })
    }
    
    func previewMovie() {
        if ViewController.programMode != ViewController.START {
                    performSegueWithIdentifier("playVideo", sender: nil)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated);
    }
    
    override func shouldAutorotate() -> Bool {
        if (UIDevice.currentDevice().orientation == UIDeviceOrientation.LandscapeLeft ||
            UIDevice.currentDevice().orientation == UIDeviceOrientation.LandscapeRight ||
            UIDevice.currentDevice().orientation == UIDeviceOrientation.Unknown) {
                return false
        }
        else {
            return true
        }
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [UIInterfaceOrientationMask.Portrait ,UIInterfaceOrientationMask.PortraitUpsideDown]
    }
    
    /* - I wanted a fade transition for my segue, but its mangling my constraints in the video player
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // this gets a reference to the screen that we're about to transition to
        let toViewController = segue.destinationViewController as UIViewController
        
        // instead of using the default transition animation, we'll ask
        // the segue to use our custom TransitionManager object to manage the transition animation
        toViewController.transitioningDelegate = self.transitionManager
        
    }
    */
    
    override func viewDidAppear(animated: Bool) {
        //let value = UIInterfaceOrientation.LandscapeLeft.rawValue
       // UIDevice.currentDevice().setValue(value, forKey: "orientation")
    }
    
    //Delegate methods for AdBannerView
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        print("success")

        thinBanner = banner
        self.view.addSubview(thinBanner) //Add banner to view (Ad loaded)
        
    }
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError
        error: NSError!) {
            print("failed to load ad")
            banner.removeFromSuperview() //Remove the banner (No ad)
    }
    
}