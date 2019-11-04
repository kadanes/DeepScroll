import UIKit

var touchSction: TouchSection = .none

public class LanedScrollerDelegate: NSObject, UITableViewDelegate {
    
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch touchSction {
        case .left:
            return 60
        case .center:
            return 100
        case .right:
            return 150
        default:
            return 150
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let containerView = UIApplication.shared.windows.first!.rootViewController?.view
        let width = (containerView?.bounds.width)!
        let touchLocation = scrollView.panGestureRecognizer.location(in: containerView)
        let touchX = touchLocation.x
        var scrollLaneChanged = false
        
        if (touchSction == .none) {
            touchSction = .right
        } else if ( 0 <= touchX && touchX <= 1/3 * width) {
            scrollLaneChanged = touchSction != .left
            touchSction = .left
        } else if ( 1/3 * width <= touchX  && touchX <= 2/3*width) {
            scrollLaneChanged = touchSction != .center
            touchSction = .center
        } else {
            scrollLaneChanged = touchSction != .right
            touchSction = .right
        }
        
        if scrollLaneChanged {
            let scrollState = ["scrollLane":"\(touchSction)"]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "scrollState"), object: nil, userInfo: scrollState)
        }

    }
}

public class LanedScrollerDataSource: NSObject, UITableViewDataSource {
    
    public var cellId: String = ""
    
    override public init() {
        super.init()
        cellId = "LanedScrollerCellId_\(NSDate().timeIntervalSince1970)"
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 10
  }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
        
        switch touchSction {
        case .right:
            cell.backgroundColor = .blue
        case .center:
            cell.backgroundColor = .brown
        case .left:
            cell.backgroundColor = .yellow
        default:
            cell.backgroundColor = .yellow
        }
        return cell
  }
}
