//
//  VideoViewController.swift
//  SwiftVideoFileFilterer
//
//  Created by Scott Yannitell on 10/18/15.
//  Copyright © 2015 Sunset Lake Software. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import AVFoundation


class VideoViewController: UIViewController {

    var player:AVPlayer!
    var playerVC:AVPlayerViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        playerVC = AVPlayerViewController()
        player = AVPlayer(URL: urlToFilteredTempVideo)
        playerVC.player = player
        self.addChildViewController(playerVC)
        self.view.addSubview(playerVC.view)
        playerVC.view.frame = self.view.frame
        player.play()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
