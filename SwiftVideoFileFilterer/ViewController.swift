import UIKit
import GPUImage
import MobileCoreServices

var urlToFilteredTempVideo = NSURL(fileURLWithPath: "")
class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var aButton: UIButton!
    @IBOutlet var progressView: UIProgressView!
    
    let imagePicker = UIImagePickerController()
    var pixellateFilter: GPUImagePixellateFilter!
    var halfToneFilter: GPUImageHalftoneFilter!
    var movieWriter: GPUImageMovieWriter!
    var movieFile: GPUImageMovie!
    var pathToMovie: String!
    var movieURL: NSURL!
    var timer: NSTimer!
    
    
    
    
    
    
    
    @IBAction func filterVideo(sender: AnyObject) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .SavedPhotosAlbum //.PhotoLibrary
        imagePicker.mediaTypes = [kUTTypeMovie as String]
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
 
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        dismissViewControllerAnimated(true, completion: nil)
        let pickedMovieUrl = info[UIImagePickerControllerMediaURL] as? NSURL
        
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
        
        movieWriter.completionBlock = {
            print("Processing Complete!")
            if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(self.pathToMovie) {
                UISaveVideoAtPathToSavedPhotosAlbum(self.pathToMovie as String, self, "savingCallBack:didFinishSavingWithError:contextInfo:", nil)
            } else {
                print("the file must be bad!")
            }
        }
    }
    
    func progress() {
        print("progress is = \(movieFile.progress)")
        progressView.progress = movieFile.progress
        if movieFile.progress == 1.0 {
            timer.invalidate()
            progressView.progress = 0
            progressView.alpha = 0
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
    }
}