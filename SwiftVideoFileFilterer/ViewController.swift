import UIKit
import GPUImage
import MobileCoreServices


var filterPreviewVideoURL: NSURL!
var videoPreviewURL: NSURL!
class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource  {

    var filters = ["Brightness", "Gamma", "Exposure", "Contrast", "Hue", "Saturation", "Amatorka Filter", "Soft Elegance Filter", "Color Invert Filter", "Grayscale Filter"]
    
    var pickedTextField: UITextField!
    
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
    
    var filterPicker: UIPickerView = UIPickerView()
    
    struct MyData {
        var filterName:String
        var parameters: [AnyObject]
    }
    
    var tableData: [MyData]! = []

    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var previewImage: UIImageView!
    @IBOutlet var theTableView: UITableView!
    var canEditTable = false;

    let imagePicker = UIImagePickerController()

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
            presentViewController(imagePicker, animated: true, completion: nil)
        
    }
    
    @IBAction func beginProcessing(sender: AnyObject) {
        movieFile = GPUImageMovie(URL: pickedMovieUrl)
        var filterList: [GPUImageOutput] = []
        var dataList:[String] = []
        for filter in tableData {
            switch (filter.filterName){
            case "Brightness":
                dataList.append(filter.filterName)
                let myGPUFilter = GPUImageBrightnessFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.brightness = myParameter
                filterList.append(myGPUFilter)
                break
            case "Gamma":
                dataList.append(filter.filterName)
                let myGPUFilter = GPUImageGammaFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.gamma = myParameter
                filterList.append(myGPUFilter)
                break
            case "Exposure":
                dataList.append(filter.filterName)
                let myGPUFilter = GPUImageExposureFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.exposure = myParameter
                filterList.append(myGPUFilter)
                break
            case "Contrast":
                dataList.append(filter.filterName)
                let myGPUFilter = GPUImageContrastFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.contrast = myParameter
                filterList.append(myGPUFilter)
                break
            case "Hue":
                dataList.append(filter.filterName)
                let myGPUFilter = GPUImageHueFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.hue = myParameter
                filterList.append(myGPUFilter)
                break
            case "Saturation":
                dataList.append(filter.filterName)
                let myGPUFilter = GPUImageSaturationFilter()
                let myParameter = filter.parameters[0] as! CGFloat
                myGPUFilter.saturation = myParameter
                filterList.append(myGPUFilter)
            case "Amatorka Filter":
                dataList.append(filter.filterName)
                let myGPUFilter = GPUImageAmatorkaFilter()
                filterList.append(myGPUFilter)
                break
                
            case "Soft Elegance Filter":
                dataList.append(filter.filterName)
                let myGPUFilter = GPUImageSoftEleganceFilter()
                filterList.append(myGPUFilter)
                break
                
            case "Color Invert Filter":
                dataList.append(filter.filterName)
                let myGPUFilter = GPUImageColorInvertFilter()
                filterList.append(myGPUFilter)
                break
                
            case "Grayscale Filter":
                dataList.append(filter.filterName)
                let myGPUFilter = GPUImageGrayscaleFilter()
                filterList.append(myGPUFilter)
                break

            default :
                print("no filter")
                
            }
        }
        
        if (filterList.count < 1){
            print("nothing to filter")
            return
        }
        
        movieFile.addTarget(filterList[0] as! GPUImageInput)
        
        for var i = 0;i<filterList.count-1; i++ {
            print("list of filters")
            if filterList[i] is GPUImageFilter {
                print("1")
                if filterList[i+1] is GPUImageFilter {
                    print("2")
                    (filterList[i] as! GPUImageFilter).addTarget(filterList[i+1] as! GPUImageFilter)
                } else {
                    print("3")
                    (filterList[i] as! GPUImageFilter).addTarget(filterList[i+1] as! GPUImageFilterGroup)
                }
            } else {
                print("4")
                if filterList[i+1] is GPUImageFilter {
                   print("5")
                    (filterList[i] as! GPUImageFilterGroup).addTarget(filterList[i+1] as! GPUImageFilter)
                } else {
                    print("6")
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
        let alert: UIAlertController = UIAlertController(title: "About:", message: "Developed by Scott Yannitell\nGPUImage developed by Brad Larson.\nIf you need an app developed, contact me at scott@ohiovr.com", preferredStyle: UIAlertControllerStyle.Alert)
        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {(action: UIAlertAction) in
        })
        alert.addAction(defaultAction)
        self.presentViewController(alert, animated: true, completion: nil)
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
        }
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        // update the item in my data source by first removing at the from index, then inserting at the to index.
        let item = tableData[fromIndexPath.row]
        tableData.removeAtIndex(fromIndexPath.row)
        tableData.insert(item, atIndex: toIndexPath.row)
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
        
        //if we got to this point we're screwed
        print("shouldn't be here!!!!!!!!!!!!")
        // Return our new cell for display
        let cell = tableView.dequeueReusableCellWithIdentifier("OnlyNameCell") as! OnlyNameCell
        return cell
    }
    
    func pressFilterFieldStart(sender:UITextField!){
        print("field edit begin")
        self.pickedTextField = sender
    }
    
    func pressFilterFieldEnd(sender:UITextField!){
        print(sender.tag)
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
            print("no params")
        }
        
        self.tableData[sender.tag] = MyData(filterName: sender.text!, parameters:params)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.theTableView.reloadData()
        })
        print("field edit end");
    }
    
    func sliderChanged(sender: UISlider!){
        print("slider value = \(sender.value)")
        tableData[sender.tag].parameters[0] = sender.value
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
            self.previewImage.image = self.previewImageForLocalVideo(videoPreviewURL)
        }
        ViewController.programMode = ViewController.PROCESS
        ViewController.previewType = ViewController.PREFILTER
    }

    //http://stackoverflow.com/questions/8906004/thumbnail-image-of-video
    func previewImageForLocalVideo(url:NSURL) -> UIImage?
    {
        let asset = AVAsset(URL: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        var time = asset.duration
        //If possible - take not the first frame (it could be completely black or white on camara's videos)
        time.value = min(time.value, 2)
        
        do {
            let imageRef = try imageGenerator.copyCGImageAtTime(time, actualTime: nil)
            return UIImage(CGImage: imageRef)
        }
        catch let error as NSError
        {
            print("Image generation failed with error \(error)")
            return nil
        }
    }
    
    func progress() {
        print("progress is = \(movieFile.progress)")
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
        let alert: UIAlertController = UIAlertController(title: "About:", message: "Your movie has been saved to the Camera Roll.", preferredStyle: UIAlertControllerStyle.Alert)
        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {(action: UIAlertAction) in
        })
        alert.addAction(defaultAction)
        self.presentViewController(alert, animated: true, completion: nil)
        self.saveButton.enabled = false
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

    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        let singleTap = UITapGestureRecognizer(target: self, action: Selector("previewMovie"))
        singleTap.numberOfTapsRequired = 1
        previewImage.userInteractionEnabled = true
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
        filterPicker.delegate = self
        filterPicker.dataSource = self
    }

    @IBAction func addItem(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableData.append(MyData(filterName: "tap to select filter", parameters:[]))
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