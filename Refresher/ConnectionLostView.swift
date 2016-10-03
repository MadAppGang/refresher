//
//  ConnectionLostView.swift
//  Pods
//
//  Created by Ievgen Rudenko on 22/10/15.
//
//

import Foundation
import UIKit
import ReachabilitySwift

private var KVOContext = "NoConnectionKVOContext"
private let ContentOffsetKeyPath = "contentOffset"
private let ContentSizeKeyPath = "contentSize"

internal class ConnectionLostDefaultSubview: UIView {
    
    fileprivate let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Internet connection lost"
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        addSubview(titleLabel)
        //#FF3B30
        backgroundColor = UIColor(red: 1.0, green: 0.231, blue: 0.188, alpha: 1)

        let leftTitleConstraint = NSLayoutConstraint(item: titleLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 16)
        let rightTitleConstraint = NSLayoutConstraint(item: titleLabel, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: -16)
        let centerTitleConstraint = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: titleLabel, attribute: .centerY, multiplier: 1, constant: 0)
        addConstraints([rightTitleConstraint, leftTitleConstraint, centerTitleConstraint])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class ConnectionLostView: UIView {
    
    fileprivate var connectionStateChanged: ((_ newStatus: Reachability.NetworkStatus) -> ()) = { status in }
    fileprivate var scrollViewBouncesDefaultValue: Bool = false
    fileprivate var scrollViewInsetsDefaultValue: UIEdgeInsets = UIEdgeInsets.zero
    fileprivate let reachability: Reachability?
    
    //When internet is unreachable, siable bounces to block load more and pull to refresh
    open var disableBouncesOnShow:Bool = true
    //Stick mode put view not in the inset area, but stick on top of scrollView
    open var stickMode:Bool = false {
        didSet {
            changeStickMode()
        }
    }

    

    
    //MARK: Object lifecycle methods

    convenience init(view: UIView, action :@escaping ((_ newStatus: Reachability.NetworkStatus) -> ())) {
        view.frame.origin = CGPoint(x:0, y:0)
        self.init(frame: view.frame)
        self.addSubview(view)
        self.autoresizingMask = .flexibleWidth
        view.autoresizingMask = .flexibleWidth
        self.connectionStateChanged = action
    }

    
    convenience init(frame: CGRect, action :@escaping ((_ newStatus: Reachability.NetworkStatus) -> ())) {
        self.init(frame: frame)
        self.connectionStateChanged = action
    }

    
    override init(frame: CGRect) {
        do {
            reachability = try Reachability()
        } catch {
            reachability = nil
        }
        var newFrame = frame
        newFrame.origin.y = -newFrame.size.height
        super.init(frame: newFrame)
        self.autoresizingMask = .flexibleWidth
        
        if let reachability = reachability {
            reachability.whenReachable = { reachability in
                DispatchQueue.main.async {
                    self.becomeReachable()
                }
            }
            reachability.whenUnreachable = { reachability in
                DispatchQueue.main.async {
                    self.becomeUnreachable()
                }
            }
            
            do {
                try reachability.startNotifier()
            } catch {
                print("Unable to start notifier")
            }
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        reachability = nil
        super.init(coder: aDecoder)
        // Currently it is not supported to load view from nib
    }
    
    deinit {
        if stickMode == true {
            superview?.removeObserver(self, forKeyPath: ContentOffsetKeyPath, context: &KVOContext)
        }
        superview?.removeObserver(self, forKeyPath: ContentSizeKeyPath, context: &KVOContext)
        reachability?.stopNotifier()
    }


    
    //MARK: UIView methods
    open override func willMove(toSuperview newSuperview: UIView!) {
        if stickMode == true {
            superview?.removeObserver(self, forKeyPath: ContentOffsetKeyPath, context: &KVOContext)
        }
        superview?.removeObserver(self, forKeyPath: ContentSizeKeyPath, context: &KVOContext)
        if let scrollView = newSuperview as? UIScrollView {
            scrollViewBouncesDefaultValue = scrollView.bounces
            scrollViewInsetsDefaultValue = scrollView.contentInset
            if stickMode == true {
                scrollView.addObserver(self, forKeyPath: ContentOffsetKeyPath, options: .initial, context: &KVOContext)
            }
            scrollView.addObserver(self, forKeyPath: ContentSizeKeyPath, options: .initial, context: &KVOContext)
        }
    }
    
    
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if let reachability = reachability {
            switch reachability.currentReachabilityStatus {
            case .notReachable:
                self.becomeUnreachable()
            default:
                self.becomeReachable()
            }
        }
    }
    
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (context == &KVOContext) {
            if let scrollView = superview as? UIScrollView , object as? NSObject == scrollView {
                if keyPath == ContentOffsetKeyPath {
                    self.updateStickyViewPosition(scrollView)
                } else  if keyPath == ContentSizeKeyPath {
                    self.frame.size.width = scrollView.contentSize.width
                }

            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    
    

    //MARK: Reachability methods
    
    internal func becomeReachable() {
        //always happends in main thread
        
        if let scrollView = superview as? UIScrollView {
            scrollView.pullToRefreshView?.disabled = false
            scrollView.loadMoreView?.disabled = false

            scrollViewBouncesDefaultValue = scrollView.bounces
            UIView.animate(withDuration: 0.3, animations: {
                scrollView.contentInset = self.scrollViewInsetsDefaultValue
                self.alpha = 0.0
            }, completion: { finished in
                self.isHidden = true
                self.connectionStateChanged(self.reachability?.currentReachabilityStatus ?? .reachableViaWWAN)
            }) 
        }
    }
    
    internal func becomeUnreachable() {
        //always happends in main thread
        if let scrollView = superview as? UIScrollView {
            scrollView.pullToRefreshView?.disabled = true
            scrollView.loadMoreView?.disabled = true

            var insets = scrollView.contentInset
            insets.top += self.frame.size.height
            
            scrollView.bounces = disableBouncesOnShow
            self.isHidden = false
            self.alpha = 0.0
            UIView.animate(withDuration: 0.3, delay: 0, options:[], animations: {
                scrollView.contentInset = insets
                self.alpha = 1.0
                if self.stickMode == false {
                    scrollView.contentOffset = CGPoint(x: 0, y: -insets.top)
                }
            }, completion: {finished in
                if self.stickMode == true {
                    self.updateStickyViewPosition(scrollView)
                }
                self.connectionStateChanged(.notReachable)
            })
        }
    }
    
    
    
    //MARK: Private methods
    
    fileprivate func updateStickyViewPosition(_ scrollView:UIScrollView) {
        self.frame.origin.y = scrollView.contentOffset.y
    }
    
    fileprivate func changeStickMode() {
        if stickMode ==  true {
            if let scrollView = superview as? UIScrollView {
                scrollView.addObserver(self, forKeyPath: ContentOffsetKeyPath, options: .initial, context: &KVOContext)
                updateStickyViewPosition(scrollView)
                if self.isHidden == false {
                    scrollView.contentInset = self.scrollViewInsetsDefaultValue
                }
            }
        } else {
            superview?.removeObserver(self, forKeyPath: ContentOffsetKeyPath, context: &KVOContext)
            self.frame.origin.y = -frame.size.height
            if let scrollView = superview as? UIScrollView , self.isHidden == false {
                var insets = scrollView.contentInset
                insets.top += self.frame.size.height
                scrollView.contentInset = insets
            }
        }
    }
    
}
