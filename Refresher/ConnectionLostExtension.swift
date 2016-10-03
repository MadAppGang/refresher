//
//  ConnectionLostExtension.swift
//  Pods
//
//  Created by Ievgen Rudenko on 21/10/15.
//
//

import Foundation
import ReachabilitySwift

private let сonnectionLostTag = 1326
private let ConnectionLostViewDefaultHeight: CGFloat = 24

extension UIScrollView {

    
    // View on top that shows "connection lost"
    public var сonnectionLostView: ConnectionLostView? {
        get {
            let theView = viewWithTag(сonnectionLostTag) as? ConnectionLostView
            return theView
        }
    }
    
    
    // If you want to connection lost functionality to your UIScrollView just call this method and pass action closure you want to execute when Reachabikity changed. If you want to stop showing reachability view you must do that manually calling hideReachabilityView methods on your scroll view
    public func addReachability(_ action:@escaping (_ newStatus: Reachability.NetworkStatus) -> ()) {
        let frame = CGRect(x: 0, y: -ConnectionLostViewDefaultHeight, width: self.frame.size.width, height: ConnectionLostViewDefaultHeight)
        let defaultView = ConnectionLostDefaultSubview(frame: frame)
        let reachabilityView = ConnectionLostView(view:defaultView, action:action)
        reachabilityView.tag = сonnectionLostTag
        reachabilityView.isHidden = true
        addSubview(reachabilityView)
    }

    public func addReachabilityView(_ view:UIView, action:@escaping (_ newStatus: Reachability.NetworkStatus) -> ()) {
        let reachabilityView = ConnectionLostView(view:view, action:action)
        reachabilityView.tag = сonnectionLostTag
        reachabilityView.isHidden = true
        addSubview(reachabilityView)
    }
    
    // Manually start pull to refresh
    public func showReachabilityView() {
        сonnectionLostView?.becomeUnreachable()
    }
    
    // Manually stop pull to refresh
    public func hideReachabilityView() {
        сonnectionLostView?.becomeReachable()
    }

    
}
