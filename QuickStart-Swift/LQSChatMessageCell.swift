import UIKit

class LQSChatMessageCell: UITableViewCell {
    var messageImageView: UIImageView!

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var messageStatus: UIImageView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        messageImageView = UIImageView()
        messageImageView.tag = 1
        messageImageView.frame = CGRectMake(100, 30, 150, 90)
        addSubview(self.messageImageView)
    }

    func updateWithImage(image: UIImage) {
        messageImageView.image = image
    }

    func removeImage() {
        if messageImageView.image != nil {
            messageImageView.image = nil
        }
    }

    func assignText(text: String) {
        messageLabel.text = text
    }
}
