import UIKit
import GPUImage
import MobileCoreServices


var filterPreviewVideoURL: NSURL!
var videoPreviewURL: NSURL!
class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource  {

    var filters = ["Brightness", "Gamma", "Exposure", "Contrast", "Hue", "Saturation", "Amatorka Filter", "Soft Elegance Filter", "Color Invert Filter", "Grayscale Filter"]
    
    
    
    
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
        self.pickedTextField.resignFirstResponder()
    }
    
    var pickedTextField: UITextField!
    var filterPicker: UIPickerView = UIPickerView()
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

    let imagePicker = UIImagePickerController()

    var movieWriter: GPUImageMovieWriter!
    var movieFile: GPUImageMovie!
    var pathToMovie: String!
    var timer: NSTimer!
    var pickedMovieUrl: NSURL!
    
    var previewToBeFilteredTimer: NSTimer! //when a filter changes, stop this timer, start it to run .3 seconds, and then filter the preview
    
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
                
            case "Soft Elegance Filter":
                let myGPUFilter = GPUImageSoftEleganceFilter()
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
            //flieble
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
        movieWriter = GPUImageMovieWriter(movieURL: filterPreviewVideoURL, size: CGSizeMake(1920, 1080))//640 x 480
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
        alert("About", message: "\(appName)\n\nwritten by Scott Yannitell \n\nImage Filters provided by GPUImage:\n\nA project led and developed by Brad Larson.\n\nGet the source code for this program and GPUImage at github.com\n\nNeed an app developed? call me or txt me at 740 396 5922")
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
            return cell
        case "Amatorka Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("OnlyNameCell") as! OnlyNameCell
            cell.filterField.text! = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.tag = indexPath.row
            cell.filterField.inputView = filterPicker
            return cell
        case "Grayscale Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("OnlyNameCell") as! OnlyNameCell
            cell.filterField.text! = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.tag = indexPath.row
            cell.filterField.inputView = filterPicker
            return cell
        case "Soft Elegance Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("OnlyNameCell") as! OnlyNameCell
            cell.filterField.text! = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.tag = indexPath.row
            cell.filterField.inputView = filterPicker
            return cell
        case "Color Invert Filter":
            let cell = tableView.dequeueReusableCellWithIdentifier("OnlyNameCell") as! OnlyNameCell
            cell.filterField.text! = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.tag = indexPath.row
            cell.filterField.inputView = filterPicker
            return cell
        case "Brightness":
            let cell = tableView.dequeueReusableCellWithIdentifier("SingleSliderCell") as! SingleSliderCell
            cell.filterField.text = tableData[indexPath.row].filterName
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldStart:"), forControlEvents: UIControlEvents.EditingDidBegin)
            cell.filterField.addTarget(self, action:Selector("pressFilterFieldEnd:"), forControlEvents: UIControlEvents.EditingDidEnd)
            cell.filterField.inputView = filterPicker
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
        return cell
    }
    
    func pressFilterFieldStart(sender:UITextField!){
        print("field edit begin")
        self.pickedTextField = sender
    }
    
    func pressFilterFieldEnd(sender:UITextField!){
        var params : [AnyObject] = []
        switch(sender.text!){
        case "Brightness":
            params.append(0)
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
        
        let time:Int64 = Int64(CMTimeGetSeconds(asset.duration) * beginEndRatio * 1000)
        //If possible - take not the first frame (it could be completely black or white on camara's videos)
       // time.value = min(time.value, 2)
        print(time)
        let time2:CMTime = CMTimeMake(time,1000)
        do {
            let imageRef = try imageGenerator.copyCGImageAtTime(time2, actualTime: nil)
            
            
            let image = UIImage(CGImage: imageRef)
            
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
                
            case "Soft Elegance Filter":
                let myGPUFilter = GPUImageSoftEleganceFilter()
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
            print("nothing to filter")
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
            timer.invalidate()
            progressView!.progress = 0
            progressView!.alpha = 0
            statusLabel.alpha = 0
            ViewController.programMode = ViewController.SELECT
            ViewController.previewType = ViewController.POSTFILTER
            blurEffectView.removeFromSuperview()
            saveButton.enabled = true
            performSegueWithIdentifier("playVideo", sender: nil)
        }
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
        if self.previewUIImage == nil {return}//this is dumb flieble
        let p:CGPoint = rec.locationInView(self.previewImage)
        
        let xVal:Float64 = Float64(p.x / UIScreen.mainScreen().bounds.width)
        
        ////print("\(xVal)")
        
        self.previewUIImage = self.previewImageForLocalVideo(videoPreviewURL, beginEndRatio: xVal)
        updatePreviewImage1()
        //flieble
        //self.previewImage.image = self.previewUIImage
        
        
        
        
        
        
        switch rec.state {
        case .Began:
            print("began")
            break
        default: break
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
       // tableData = [
//
  //      ]
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
        theTableView.rowHeight = 100
        canEditTable = true
        theTableView.setEditing(true, animated: false)
        
        
        filterPicker.delegate = self
        filterPicker.dataSource = self
        
        previewToBeFilteredTimer = NSTimer()
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
    
}