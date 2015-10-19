//
//  PlayerViewController.swift
//  SwiftVideoFileFilterer
//
//  Created by Scott Yannitell on 10/18/15.
//  Copyright © 2015 Sunset Lake Software. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import AVFoundation

class PlayerViewController: UIViewController {
    var playerVC:AVPlayerViewController!
    var player:AVPlayer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        playerVC = AVPlayerViewController()
       // let url = NSURL(string: streamURL as String)!
        
        
        
        player = AVPlayer(URL: urlToFilteredTempVideo)
        playerVC.player = player
        self.addChildViewController(playerVC)
        self.view.addSubview(playerVC.view)
        playerVC.view.frame = self.view.frame
        player.play()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
