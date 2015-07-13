import UIKit

class LQSAnnouncementsTableViewCell: UITableViewCell {

    @IBOutlet weak var senderName: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var indicatorLabel: UILabel!

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func updateSenderName(senderName: String) {
        self.senderName.text = senderName
    }
    
    func updateDate(date: String) {
        dateLabel.text = date
    }

    func updateMessageLabel(message: String) {
        messageLabel.text = message
    }
}
