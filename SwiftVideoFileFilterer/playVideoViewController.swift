//
//  playVideoViewController.swift
//  SwiftVideoFileFilterer
//
//  Created by Scott Yannitell on 10/18/15.
//  Copyright © 2015 Sunset Lake Software. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class playVideoViewController: AVPlayerViewController {
    override func viewDidLoad() {
        var player:AVPlayer!
        ////var playerItem:AVPlayerItem!;
        let avPlayerLayer:AVPlayerLayer = AVPlayerLayer(player: player)
        avPlayerLayer.frame = self.view.frame
        self.view.layer.addSublayer(avPlayerLayer)
        ////var steamingURL:NSURL = NSURL(string: urlToFilteredTempVideo)
        player = AVPlayer(URL: urlToFilteredTempVideo)
        player.play()
    }
    
    
}
