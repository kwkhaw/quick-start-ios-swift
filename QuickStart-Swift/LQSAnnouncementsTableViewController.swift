import UIKit

class LQSAnnouncementsTableViewController: UITableViewController, UIAlertViewDelegate, LYRQueryControllerDelegate {
    private var queryController: LYRQueryController?
    private var shouldScrollAfterUpdates: Bool = false
    
    var layerClient: LYRClient?

    override func viewDidLoad() {
        super.viewDidLoad()

        var error: NSError? = nil
        let query = LYRQuery(queryableClass: LYRAnnouncement.self)
        query.sortDescriptors = [ NSSortDescriptor(key: "position", ascending: false) ]
        
        queryController = layerClient!.queryControllerWithQuery(query)
        queryController!.delegate = self
        queryController!.execute(&error)
        
        if queryController!.count() <= 0 {
            let emptyView: UIView = UIView(frame: CGRectMake(0, 0, 320, 100))
            emptyView.backgroundColor = UIColor.whiteColor()
            let alert = UIAlertView(title: "No Announcements",
                                    message: "You currently have no announcements. Would you like to learn about announcements?",
                                    delegate: self,
                                    cancelButtonTitle: "No",
                                    otherButtonTitles: "Yes")
            
            alert.show()

            let label: UILabel = UILabel(frame: CGRectMake(10, 50, 500, 500))
            label.font = UIFont(name: "Helvetica Neue", size:17)
            label.lineBreakMode = NSLineBreakMode.ByWordWrapping
            label.numberOfLines = 0
            label.text = "You currently have no announcements!"

            emptyView.addSubview(label)
            self.view = emptyView
        }
    }

    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        let ourURL = NSURL(string: "http://bit.ly/layer-announcements")
        if buttonIndex == 1 {
            UIApplication.sharedApplication().openURL(ourURL!)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return Int(queryController!.count())
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let announcement: LYRAnnouncement = queryController!.objectAtIndexPath(indexPath) as! LYRAnnouncement
        announcement.markAsRead(nil)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "cell"
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as? LQSAnnouncementsTableViewCell
        
        if cell == nil {
            cell = LQSAnnouncementsTableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: cellIdentifier)
        }
        
        let announcementsInfo: LYRAnnouncement = queryController!.objectAtIndexPath(indexPath) as! LYRAnnouncement
        let message: LYRMessage = queryController!.objectAtIndexPath(indexPath) as! LYRMessage
        
        let messagePart: LYRMessagePart = message.parts[0] as! LYRMessagePart
        let dateFormat = NSDateFormatter()
        
        let announcementMessage = NSString(data: messagePart.data, encoding: NSUTF8StringEncoding)
        dateFormat.dateFormat = "yyyy-MM-dd"
        cell!.updateDate("\(dateFormat.stringFromDate(announcementsInfo.sentAt))")
        cell!.updateSenderName(announcementsInfo.sender.name)
        cell!.updateMessageLabel(announcementMessage as! String)
        
        if (announcementsInfo.isUnread) {
            cell!.indicatorLabel.hidden = false
        } else {
            cell!.indicatorLabel.hidden = true
        }
        
        return cell!
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 90
    }


// MARK: - Query controller delegate implementation

    func queryController(controller: LYRQueryController, didChangeObject object: AnyObject!, atIndexPath indexPath: NSIndexPath!, forChangeType type: LYRQueryControllerChangeType, newIndexPath: NSIndexPath!) {
        switch (type) {
            case LYRQueryControllerChangeType.Delete:
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            case LYRQueryControllerChangeType.Insert:
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                if Int(controller.count()) >= newIndexPath.row {
                    self.shouldScrollAfterUpdates = true
                }
            case LYRQueryControllerChangeType.Move:
                tableView.moveRowAtIndexPath(indexPath, toIndexPath: newIndexPath)
            case LYRQueryControllerChangeType.Update:
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            default:
                break
        }
    }

    func queryControllerWillChangeContent(queryController: LYRQueryController) {
        tableView.beginUpdates()
    }

    func queryControllerDidChangeContent(queryController: LYRQueryController) {
        tableView.endUpdates()
        if self.shouldScrollAfterUpdates {
            scrollToBottomAnimated(true)
        }
    }

    func scrollToBottomAnimated(animated: Bool) {
        if queryController!.count() > 0 {
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: Int(queryController!.count())-1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: animated)
        }
    }
}
