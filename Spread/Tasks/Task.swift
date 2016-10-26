//
//  Task.swift
//  Spread
//
//  Created by Huy Pham on 4/15/15.
//  Copyright (c) 2015 Katana. All rights reserved.
//

import UIKit

class Task: SRemoteTask {
  
  var objectId: String!
  var nameSpace: String!
    
  init(objectId: String, nameSpace: String) {
    super.init()
    self.objectId = objectId
    self.nameSpace = nameSpace
  }
  
  override func getRequestParameters() -> [AnyHashable: Any] {
    return ["type": "block"]
  }
  
  override func getRequestUrl() -> String {
    return "www.google.com"
  }
  
  override func dequeue(_ executingTask: SRemoteTask) -> Bool {
    let task = executingTask as! Task
    if self.objectId != task.objectId {
      return true
    }
    return false
  }
  
  override func enqueue(_ penddingTask: SRemoteTask) -> Bool {
    let task = penddingTask as! Task
    if self.objectId == task.objectId
      && self.nameSpace == task.nameSpace {
        return false
    }
    return true
  }
}
