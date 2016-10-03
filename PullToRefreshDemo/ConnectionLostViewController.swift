//
//  ConnectionLostViewController.swift
//  PullToRefresh
//
//  Created by Ievgen Rudenko on 23/10/15.
//  Copyright © 2015 Josip Cavar. All rights reserved.
//

import UIKit

class ConnectionLostViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var rowsCount = 20
    var showCustomView = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.addPullToRefresh {
            OperationQueue().addOperation { [weak self] in
                sleep(20)
                OperationQueue.main.addOperation {
                    print("Pull to refresh timeout fire")
                    self?.tableView.stopPullToRefresh()
                }
            }
        }
        
        
        if showCustomView {
            if let customSubview = Bundle.main.loadNibNamed("NoConnectionCustomView", owner: self, options: nil)?.first as? UIView {
                tableView.addReachabilityView(customSubview) { status in
                    print("reachability changed with custom view \(status)")
                }
            }
        } else  {
            tableView.addReachability { status in
                print("reachability changed \(status)")
            }
        }
        
        if let rv = tableView.сonnectionLostView {
            rv.stickMode = true
            rv.disableBouncesOnShow = true
        }



    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return self.rowsCount
    }
    
    func tableView(_ tableView: UITableView!, cellForRowAtIndexPath indexPath: IndexPath!) -> UITableViewCell! {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.textLabel?.text = "Row " + String(indexPath.row + 1)
        return cell
    }

    @IBAction func showView(_ sender: AnyObject) {
        tableView.showReachabilityView()
    }

    @IBAction func hideView(_ sender: AnyObject) {
        tableView.hideReachabilityView()
    }
    
    @IBAction func changeStickyMode(_ sender: AnyObject) {
        if let rv = tableView.сonnectionLostView {
            rv.stickMode = !rv.stickMode
        }
    }
    
}
