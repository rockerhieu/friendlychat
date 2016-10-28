//
//  MessageCell.swift
//  FriendlyChatSwift
//
//  Created by Hieu Rocker on 10/29/16.
//  Copyright © 2016 Google Inc. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage

class MessageCell: UITableViewCell {
  
  @IBOutlet weak var senderName: UILabel!
  @IBOutlet weak var senderAvatar: UIImageView!
  @IBOutlet weak var message: UILabel!
  @IBOutlet weak var photo: UIImageView!
  @IBOutlet weak var photoHeightConstraint: NSLayoutConstraint!

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }

  func loadImage(URL: URL?) {
    if let URL = URL {
      self.photo.isHidden = false
      self.photo.sd_setImage(with: URL, completed: { (image, error, type, url) in
        if let image = image {
          let ratio = image.size.width / image.size.height
          let width = self.photo.frame.size.width
          let height = width / ratio
          self.photoHeightConstraint.constant = height
          print("image.size = (\(image.size.width),\(image.size.height)), ratio = \(ratio), width = \(width), height = \(height)")
        } else {
          self.photoHeightConstraint.constant = 1
          self.photo.isHidden = true
        }
      })
    } else {
      self.photoHeightConstraint.constant = 1
      self.photo.isHidden = true
    }
  }
  
  var msg: Message? {
    didSet {
      self.senderName.text = msg?.senderName
      self.message.text = msg?.text
      
      self.senderAvatar.sd_cancelCurrentImageLoad()
      self.senderAvatar.image = nil
      if let photoURL = msg?.photoURL {
        self.senderAvatar.sd_setImage(with: URL(string: photoURL))
      }
      self.photo.sd_cancelCurrentImageLoad()
      if let imageURL = msg?.imageURL {
        self.photo.image = nil
        self.loadImage(URL: URL(string: imageURL))
      } else {
        self.loadImage(URL: nil)
      }
    }
  }
}
