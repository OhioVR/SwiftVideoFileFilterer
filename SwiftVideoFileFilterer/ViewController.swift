import UIKit
import GPUImage
import MobileCoreServices


var filterPreviewVideoURL: NSURL!
var videoPreviewURL: NSURL!
class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource  {

    var filters = ["Filter-Red","Filter-Yellow","Filter-Green","Filter-Blue"]
    
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
   

    
    
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var previewImage: UIImageView!
    @IBOutlet var theTableView: UITableView!
    

    let imagePicker = UIImagePickerController()
    var pixellateFilter: GPUImagePixellateFilter!
    var halfToneFilter: GPUImageHalftoneFilter!
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
        // filterTable.hidden = true;
        
        movieFile = GPUImageMovie(URL: pickedMovieUrl)
        
        pixellateFilter = GPUImagePixellateFilter()
        halfToneFilter = GPUImageHalftoneFilter()
        
        var filterList: [GPUImageFilter] = [pixellateFilter, halfToneFilter]
        
        
        movieFile.addTarget(filterList[0])
        filterList[0].addTarget(filterList[1])
        
        let tmpdir = NSTemporaryDirectory()
        pathToMovie = "\(tmpdir)output.mov"
        
        unlink(pathToMovie)//unlink deletes a file
        filterPreviewVideoURL = NSURL.fileURLWithPath(pathToMovie)
        movieWriter = GPUImageMovieWriter(movieURL: filterPreviewVideoURL, size: CGSizeMake(320, 240))//640 x 480
        movieWriter.encodingLiveVideo = false;//https://github.com/BradLarson/GPUImage/issues/1108
        
        filterList[1].addTarget(movieWriter)
        //halfToneFilter.addTarget(movieWriter)
        
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
        
        //movieWriter.completionBlock = {
        //    print("Processing Complete!")
            if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(self.pathToMovie) {
                UISaveVideoAtPathToSavedPhotosAlbum(self.pathToMovie as String, self, "savingCallBack:didFinishSavingWithError:contextInfo:", nil)
            } else {
                print("the file must be bad!")
            }
        //}

        
    }
    
    @IBAction func aboutButton(sender: AnyObject) {
        let alert: UIAlertController = UIAlertController(title: "About:", message: "Made by Scott Yannitell. If you need an app developed, contact me at scott@ohiovr.com", preferredStyle: UIAlertControllerStyle.Alert)
        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {(action: UIAlertAction) in
        })
        alert.addAction(defaultAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
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
        // Create a new cell with the reuse identifier of our prototype cell
        // as our custom table cell class
        let cell = tableView.dequeueReusableCellWithIdentifier("myPrototypeCell") as! myTableCell
        // Set the first row text label to the firstRowLabel data in our current array item
        cell.filterField.text = tableData[indexPath.row].firstRowLabel
        // Set the second row text label to the secondRowLabel data in our current array item
        /////cell.label2.text = tableData[indexPath.row].secondRowLabel
        
        //cell.setButton.tag = indexPath.row;
        //cell.setButton.addTarget(self, action: "tableCellSetButtonClicked:", forControlEvents: .TouchUpInside)
       //// cell.setButton.inputView = filterPicker
        
        cell.filterField.addTarget(self, action:Selector("pressFilterField:"), forControlEvents: UIControlEvents.EditingDidBegin)
        cell.filterField.inputView = filterPicker
        
        // Return our new cell for display
        return cell
    }
    
    func pressFilterField(sender:UITextField!){
        pickedTextField = sender
    }
    

    
    struct MyData {
        var firstRowLabel:String
        var secondRowLabel:String
    }

    var tableData: [MyData]! = []
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        //check here for the right segue by name
        
        print (segue.identifier)
        if segue.identifier == "playVideo" {
            
        }

       
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
            //aButton.enabled = true;
            ViewController.programMode = ViewController.SELECT
            ViewController.previewType = ViewController.POSTFILTER
            blurEffectView.removeFromSuperview()
            processItButton.enabled = false
            saveButton.enabled = true
            performSegueWithIdentifier("playVideo", sender: nil)
            //self.previewImage.image = self.previewImageForLocalVideo(filterPreviewVideoURL) //doesn't belong here
            
            
            
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
            self.theTableView.setEditing(false, animated: true)
        }
        else {
            self.theTableView.setEditing(true, animated: true)
        }
        print("sis boom bah")
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self

        ///aButton.enabled = true;
        
        let singleTap = UITapGestureRecognizer(target: self, action: Selector("previewMovie"))
        singleTap.numberOfTapsRequired = 1
        previewImage.userInteractionEnabled = true
        previewImage.addGestureRecognizer(singleTap)
        ViewController.programMode = ViewController.START
        ViewController.previewType = "nothing"
        //filterTable.hidden = true;
        
        tableData = [
            MyData(firstRowLabel: "The first row", secondRowLabel: "Hello"),
            MyData(firstRowLabel: "The second row", secondRowLabel: "There"),
            MyData(firstRowLabel: "Third and final row", secondRowLabel: "http://peterwitham.com")
        ]
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
        //self.view.addSubview(blurEffectView)
        blurEffectView.removeFromSuperview()
        processItButton.enabled = false
        saveButton.enabled = false
        
        
        let tblView =  UIView(frame: CGRectZero)
        theTableView.tableFooterView = tblView
        theTableView.tableFooterView!.hidden = true
        theTableView.backgroundColor = UIColor.lightGrayColor()
        
        filterPicker.delegate = self
        filterPicker.dataSource = self
    }

    @IBAction func addItem(sender: AnyObject) {
        
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableData.append(MyData(firstRowLabel: "a brand new row", secondRowLabel: "Yay"))
            self.theTableView.reloadData()
        })
  
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