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
  
  override func getRequestParameters() -> [NSObject : AnyObject]! {
    
    return ["type": "block"]
  }
  
  override func getRequestUrl() -> String! {
    
    return "www.google.com"
  }
  
  override func dequeueCondtion(executingTask: SRemoteTask!) -> Bool {
    
    if executingTask.isKindOfClass(Task) {
      let task = executingTask as! Task
      return self.objectId != task.objectId
    } else {
      return true
    }
  }
  
  override func enqueueCondtion(penddingTask: SRemoteTask!) -> Bool {

    if penddingTask.isKindOfClass(Task) {
        let task = penddingTask as! Task
        return self.objectId != task.objectId || self.nameSpace != task.nameSpace
    } else {
      return true
    }
  }
}
