//
//  Networking.swift
//  Spread
//
//  Created by Huy Pham on 3/26/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

import UIKit

class Networking {
  
  class func getData(_ handler: @escaping ((_ response: NSDictionary) -> Void)) {
    
    let url = URL(string: "http://latte.lozi.vn/albums/5437779d72cc6b292f8fc9dd/blocks")
    let task = URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
      let response = (try! JSONSerialization.jsonObject(with: data!,
        options: JSONSerialization.ReadingOptions.mutableLeaves)) as! NSDictionary
      handler(response)
    }) 
    task.resume()
  }
}
