//
//  filterSelectViewController.swift
//  SwiftVideoFileFilterer
//
//  Created by Scott Yannitell on 10/22/15.
//  Copyright © 2015 Scott Yannitell. All rights reserved.
//

import UIKit

protocol ContainerDelegateProtocol
{
    func CloseFilterSelector()
}

class filterSelectViewController: UIViewController, UITableViewDelegate  {

    var delegate:ContainerDelegateProtocol?
    
    @IBAction func Close(sender: AnyObject) {
        delegate?.CloseFilterSelector()
    }
    
    @IBOutlet var tableView: UITableView!
    
    var cellContent = ["Sharpen", "Brightness", "Hue", "Saturation", "gaussian blur", "pixelate"]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
