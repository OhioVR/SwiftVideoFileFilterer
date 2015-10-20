import UIKit
import GPUImage
import MobileCoreServices

var urlToFilteredTempVideo = NSURL(fileURLWithPath: "")
class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITableViewDelegate  {
    
    @IBOutlet var aButton: UIButton!
    @IBOutlet var progressView: UIProgressView!
    
    
    
    ////@IBOutlet var tableView: UITableView!
    var cellContent = ["Sharpen", "Brightness", "Hue", "Saturation"]
    
    
    let imagePicker = UIImagePickerController()
    var pixellateFilter: GPUImagePixellateFilter!
    var halfToneFilter: GPUImageHalftoneFilter!
    var movieWriter: GPUImageMovieWriter!
    var movieFile: GPUImageMovie!
    var pathToMovie: String!
    var movieURL: NSURL!
    var timer: NSTimer!
    

    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var previewImage: UIImageView!
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return cellContent.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Cell")
        cell.textLabel?.text = cellContent[indexPath.row]
        return cell
    }

    
    
    
    @IBAction func filterVideo(sender: AnyObject) {
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .SavedPhotosAlbum
        imagePicker.mediaTypes = [kUTTypeMovie as String]
        presentViewController(imagePicker, animated: true, completion: nil)
      
    }
    
 
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        dismissViewControllerAnimated(true, completion: nil)
        let pickedMovieUrl = info[UIImagePickerControllerMediaURL] as? NSURL
        
        
        aButton.setTitle("Process Video", forState: UIControlState.Normal)
        
        previewImage.image = previewImageForLocalVideo(pickedMovieUrl!)
        
        aButton.enabled = false;
        movieFile = GPUImageMovie(URL: pickedMovieUrl)
        pixellateFilter = GPUImagePixellateFilter()
        halfToneFilter = GPUImageHalftoneFilter()
        movieFile.addTarget(halfToneFilter)
        
        let tmpdir = NSTemporaryDirectory()
        pathToMovie = "\(tmpdir)output.mov"
        
        unlink(pathToMovie)//unlink deletes a file
        movieURL = NSURL.fileURLWithPath(pathToMovie)
        movieWriter = GPUImageMovieWriter(movieURL: movieURL, size: CGSizeMake(640, 480))
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
        }
    }
    
    func savingCallBack(video: NSString, didFinishSavingWithError error:NSError, contextInfo:UnsafeMutablePointer<Void>){
        print("the file has been saved sucessfully!")
        urlToFilteredTempVideo = movieURL
        performSegueWithIdentifier("playFilteredVideo", sender: nil)
    
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        progressView.progress = 0
        progressView.alpha = 0;
        statusLabel.alpha = 0.0
        aButton.enabled = true;
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated);
        aButton.setTitle("Select Video", forState: UIControlState.Normal)
    }
    
}