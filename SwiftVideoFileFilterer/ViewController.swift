import UIKit
import GPUImage
import MobileCoreServices


var filterPreviewVideoURL: NSURL!
var videoPreviewURL: NSURL!
class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITableViewDelegate  {
    
    @IBOutlet var aButton: UIButton!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var previewImage: UIImageView!
    
    var cellContent = ["Sharpen", "Brightness", "Hue", "Saturation", "gaussian blur", "pixelate"]
    
    
    let imagePicker = UIImagePickerController()
    var pixellateFilter: GPUImagePixellateFilter!
    var halfToneFilter: GPUImageHalftoneFilter!
    var movieWriter: GPUImageMovieWriter!
    var movieFile: GPUImageMovie!
    var pathToMovie: String!
    var timer: NSTimer!
    var pickedMovieUrl: NSURL!
    
    static let START = "start"
    static let SELECT = "select image"
    static let PROCESS = "process image"
    static var programMode: String!
    
    static var previewType: String!
    static let PREFILTER = "Prefilter"
    static let POSTFILTER = "Post filter"
    
    

    @IBAction func aButtonPress(sender: AnyObject) {
        
        if ViewController.programMode == ViewController.SELECT || ViewController.programMode == ViewController.START {
            
            imagePicker.allowsEditing = true
            imagePicker.sourceType = .SavedPhotosAlbum
            imagePicker.mediaTypes = [kUTTypeMovie as String]
            presentViewController(imagePicker, animated: true, completion: nil)
            
        } else if ViewController.programMode == ViewController.PROCESS {
            aButton.enabled = false;
            movieFile = GPUImageMovie(URL: pickedMovieUrl)
            pixellateFilter = GPUImagePixellateFilter()
            halfToneFilter = GPUImageHalftoneFilter()
            movieFile.addTarget(halfToneFilter)
            
            let tmpdir = NSTemporaryDirectory()
            pathToMovie = "\(tmpdir)output.mov"
            
            unlink(pathToMovie)//unlink deletes a file
            filterPreviewVideoURL = NSURL.fileURLWithPath(pathToMovie)
            movieWriter = GPUImageMovieWriter(movieURL: filterPreviewVideoURL, size: CGSizeMake(640, 480))
            movieWriter.encodingLiveVideo = false;//https://github.com/BradLarson/GPUImage/issues/1108
            halfToneFilter.addTarget(movieWriter)
            movieWriter.shouldPassthroughAudio = true
            movieFile.audioEncodingTarget = movieWriter
            movieFile.enableSynchronizedEncodingUsingMovieWriter(movieWriter)
            movieWriter.startRecording()
            movieFile.startProcessing()
            
            timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "progress", userInfo: nil, repeats: true)
            progressView.alpha = 1.0
            statusLabel.alpha = 1.0
            movieWriter.completionBlock = {
                print("Processing Complete!")
                if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(self.pathToMovie) {
                    UISaveVideoAtPathToSavedPhotosAlbum(self.pathToMovie as String, self, "savingCallBack:didFinishSavingWithError:contextInfo:", nil)
                } else {
                    print("the file must be bad!")
                }
            }
            
        }
        
        
    }
    
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        dismissViewControllerAnimated(true, completion: nil)
        pickedMovieUrl = info[UIImagePickerControllerMediaURL] as? NSURL
        
        videoPreviewURL = pickedMovieUrl
        
        
        dispatch_after(0, dispatch_get_main_queue()) {
            print("test")
            //we have to do these tasks on the main thread 
            //otherwise there will be no effect
            self.previewImage.image = self.previewImageForLocalVideo(self.pickedMovieUrl!)
            self.aButton.setTitle("Process Video", forState: UIControlState.Normal)
            
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
        progressView.progress = movieFile.progress
        if movieFile.progress == 1.0 {
            timer.invalidate()
            progressView.progress = 0
            progressView.alpha = 0
            statusLabel.alpha = 0
            aButton.enabled = true;
            aButton.setTitle("Select Video", forState: UIControlState.Normal)
            ViewController.programMode = ViewController.SELECT
            ViewController.previewType = ViewController.POSTFILTER
        }
    }
    
    func savingCallBack(video: NSString, didFinishSavingWithError error:NSError, contextInfo:UnsafeMutablePointer<Void>){
        print("the file has been saved sucessfully!")
        performSegueWithIdentifier("playVideo", sender: nil)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        progressView.progress = 0
        progressView.alpha = 0;
        statusLabel.alpha = 0.0
        aButton.enabled = true;
        
        let singleTap = UITapGestureRecognizer(target: self, action: Selector("previewMovie"))
        singleTap.numberOfTapsRequired = 1
        previewImage.userInteractionEnabled = true
        previewImage.addGestureRecognizer(singleTap)
        ViewController.programMode = ViewController.START
        aButton.setTitle("Select Video", forState: UIControlState.Normal)
        ViewController.previewType = "nothing"
    }
    
    func previewMovie() {
        if ViewController.programMode != ViewController.START {
                    performSegueWithIdentifier("playVideo", sender: nil)
        }

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated);
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellContent.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Cell")
        cell.textLabel?.text = cellContent[indexPath.row]
        return cell
    }
    
    
    
    
}