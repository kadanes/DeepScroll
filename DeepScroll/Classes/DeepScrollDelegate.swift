//
//  DeepScrollDelegate.swift
//  DeepScroll
//
//  Created by Parth Tamane on 06/11/19.
//

import Foundation
import UIKit

public class LanedScrollerDelegate: NSObject, UITableViewDelegate {
    
    let lanedScrollerId: Int
    private var touchSection: TouchSection = .none
    private var leftLaneBounds: [LaneXBound: CGFloat] = [:]
    private var centerLaneBounds: [LaneXBound: CGFloat] = [:]
    private var rightLaneBounds: [LaneXBound: CGFloat] = [:]
    private var resettingLanedScroller = false
    private var resetTimer: Timer = Timer()
    private var screenHeight: CGFloat = UIScreen.main.bounds.height
    internal var compressionDirection: CompressionDirection = .RTL
    internal var laneWidthRatio: ScrollLaneWidthRatio = .equal
    internal var tapToExpandCell = true
    internal var autoResetCellState = false
    internal var tableViewData: [Decodable] = []
    internal var didSelectCallback: DidSelectCallback?
    
    convenience override public init() {
        self.init()
    }
    
    init(lanedScrollerId: Int) {
        self.lanedScrollerId = lanedScrollerId
        super.init()
        
        //Setting up lane ratio properties
        setLaneProperties()
    }
    
    // Scroll lane visual overlays.
    
    var leftLane: UIView = {
        let v = UIView()
        v.backgroundColor = .lightGray
        v.alpha = 0
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    var centerLane: UIView = {
        let v = UIView()
        v.backgroundColor = .lightGray
        v.alpha = 0
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    var rightLane: UIView = {
        let v = UIView()
        v.backgroundColor = .lightGray
        v.alpha = 0
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    // Creates gray header between cells.
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section != 0 {
            let v = UIView()
            v.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
            return v
        }
        return UIView()
    }
    
    // Sets height for header between cells.
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section != 0 {
            return 10
        }
        
        return 0
    }
    
    // Sets height for rows in the tableView.
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    /**
     Listen for scroll action and change cell size.
     */
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        resetTimer.invalidate()
        if resettingLanedScroller { return }
        
        // Set up haptic feedback and get touch location.
        let hapticfeedback = UIImpactFeedbackGenerator()
        let containerView = UIApplication.shared.windows.first!.rootViewController?.view
        let touchLocation = scrollView.panGestureRecognizer.location(in: containerView)
        let touchX = touchLocation.x
        var scrollLaneChanged = false
        
        // Add visual overlays to the screen.
        scrollView.superview!.addSubview(leftLane)
        scrollView.superview!.addSubview(centerLane)
        scrollView.superview!.addSubview(rightLane)
        
        // Set touchSection based on scroll.
        if (touchSection == .none) {
            touchSection = getNormalStateLane(compressionDirection: compressionDirection)
        } else if (leftLaneBounds[.lower]! <= touchX && touchX < leftLaneBounds[.upper]!) {
            scrollLaneChanged = touchSection != .left
            touchSection = .left
        } else if (centerLaneBounds[.lower]! <= touchX && touchX < centerLaneBounds[.upper]!) {
            scrollLaneChanged = touchSection != .center
            touchSection = .center
        } else {
            scrollLaneChanged = touchSection != .right
            touchSection = .right
        }
        
        // Reset cell state if auto reset is turned on.
        if autoResetCellState {
            if touchSection != getNormalStateLane(compressionDirection: compressionDirection) {
                resetTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { (timer) in
                    self.resetScrollState()
                })
            }
        }
        
        // Executes when the scroll lane changes. Animation and haptic feedback are activated.
        if scrollLaneChanged {
            hapticfeedback.impactOccurred()
            sendScrollStateNotification(for: lanedScrollerId, touchSection: touchSection)
            switch touchSection {
            case .left:
                UIView.animate(withDuration: 0.6, animations: {
                    self.leftLane.alpha = 0.8
                    self.leftLane.frame.size.height += self.screenHeight
                    self.leftLane.alpha = 0
                }) { (Bool) in
                    self.leftLane.frame.size.height = 0
                }
            case .center:
                UIView.animate(withDuration: 0.6, animations: {
                    self.centerLane.alpha = 0.8
                    self.centerLane.frame.size.height += self.screenHeight
                    self.centerLane.alpha = 0
                }) { (Bool) in
                    self.centerLane.frame.size.height = 0
                }
            case .right:
                UIView.animate(withDuration: 0.6, animations: {
                    self.rightLane.alpha = 0.8
                    self.rightLane.frame.size.height += self.screenHeight
                    self.rightLane.alpha = 0
                }) { (Bool) in
                    self.rightLane.frame.size.height = 0
                }
            default:
                break
            }
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollingFinish()
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollingFinish()
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollingFinish()
        }
    }
    
    
    /**
     Send notification to reset cell state.
     */
    
    @objc
    func resetScrollState() {
        resettingLanedScroller = true
        touchSection = getNormalStateLane(compressionDirection: compressionDirection)
        sendScrollStateNotification(for: lanedScrollerId, touchSection: touchSection)
        self.resettingLanedScroller = false
    }
    
    /**
     After scorlling is over set the reset flag to false.
     */
    
    private func scrollingFinish() {
        resettingLanedScroller = false
    }
    
    // Detects a touch on a cell.
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Handle cell expansion and regular cell selection.
        if tapToExpandCell {
            if getCellState(compressionDirection: compressionDirection, touchSection: touchSection) == .normal {
                if let didSelectCallback = didSelectCallback {
                    didSelectCallback(tableViewData[indexPath.section])
                }
                return
            }
            resettingLanedScroller = true
            let normalLane = getNormalStateLane(compressionDirection: compressionDirection)
            sendScrollStateNotification(for: lanedScrollerId, touchSection: normalLane)
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            touchSection = normalLane
        }
    }
}

//MARK: Extension to handle configuration changes

extension LanedScrollerDelegate {
    
    /**
     Function to set properties dependent on scroll width ratio.
     */
    
    func setLaneProperties() {
        touchSection = .none
        leftLaneBounds = getLaneXBounds(with: laneWidthRatio, for: .left, direction: compressionDirection)
        centerLaneBounds = getLaneXBounds(with: laneWidthRatio, for: .center, direction: compressionDirection)
        rightLaneBounds = getLaneXBounds(with: laneWidthRatio, for: .right, direction: compressionDirection)
        leftLane.frame = CGRect(x: leftLaneBounds[.lower]!, y: 0, width: getLaneWidth(with: laneWidthRatio, for: .left, direction: compressionDirection), height: 0)
        centerLane.frame = CGRect(x: centerLaneBounds[.lower]!, y: 0, width: getLaneWidth(with: laneWidthRatio, for: .center, direction: compressionDirection), height: 0)
        rightLane.frame = CGRect(x: rightLaneBounds[.lower]!, y: 0, width: getLaneWidth(with: laneWidthRatio, for: .right, direction: compressionDirection), height: 0)
    }
}
