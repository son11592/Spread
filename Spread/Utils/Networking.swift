//
//  Networking.swift
//  Spread
//
//  Created by Huy Pham on 3/26/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

import UIKit

class Networking {
  
  class func getData(handler: ((response: NSDictionary) -> Void)) {
    
    let url = NSURL(string: "http://latte.lozi.vn/albums/5437779d72cc6b292f8fc9dd/blocks")
    let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
      let response = NSJSONSerialization.JSONObjectWithData(data,
        options: NSJSONReadingOptions.MutableLeaves, error: nil) as NSDictionary
      handler(response: response)
    }
    task.resume()
  }
}
