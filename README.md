[![Build Status](https://travis-ci.org/huyphams/Spread.svg)](https://travis-ci.org/huyphams/Spread)[![Cocoapods Version](https://cocoapod-badges.herokuapp.com/v/Spread/badge.png)](http://cocoapods.org/?q=spread)


Spread is a data flow control. It changes the way you manage your data.

## Features

- [x] Create, mapping (with NSDictionary / JSON) and manage data model automatic.
- [x] Auto trigger event to all models in register pools.
- [x] React when model properties change value.
- [ ] Store and restore models in pools from local database.
- [ ] DataSouceManager fetch/push data from internet sound awesome.

## Installation

#### Cocoa pods

```ruby

pod "Spread", "~> 1.0.4"

```

#### Manual

 - Drag and drop Classes folder into your project.

## Usage

```objc

#import "Spread.h"

```

#### Create a class sub class SModel

```swift

class Model: SModel {

  dynamic var objectId: String!
  dynamic var name: String!
}

```
#### Register class

```swift

  Spread.registerClass(Model.classForCoder(), forPoolIdentifier:"PoolIdentifier")

```

#### Register pool event

```swift

Spread.registerEvent("TheEvent",
  poolIdentifiers:["PoolIdentifier"]) { (value, spool) -> Void in
  let objectId = (value as NSDictionary).valueForKey("objectId") as String
  let newName = (value as NSDictionary).valueForKey("name") as String
  let models = spool.filter({ (model) -> Bool in
    return (model as Model).objectId == objectId
  })
  for item in models {
    let model = item as Model
      model.name = newName
    }
  }

```

#### Add sample data model and setup reaction for property

```swift

let model = Spread.addObject(["name": "Some name", "objectId": "123"],
  toPool: self.pool1Identifier)

  model.property("name", onChangeReaction: { (newValue) -> Void in
  aTextField.text = newValue as String
})

```

#### Perform an event

```swift

  Spread.outEvent("TheEvent",
    value: ["name": "Change the name", "objectId": "123"])

```

## Contact

- [@duchuykun@gmail.com](http://facebook.com/huyphams)

If you use/enjoy `Spread`, let me know!

## License

See the LICENSE file for more info.

