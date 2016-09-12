#Objects

Objects are rendered exactly as set up in Tiled. 

*SKTiled* also respects the type as set up in Tiled:


![Tiled obeject types](https://github.com/mfessenden/SKTiled/blob/iOS10/docs/img/object_types.png)


To query objects of a certain type, use the `SKObjectGroup.getObjects` method:

```swift
let emitterObjects = objectsGroup.getObjects(ofType: "Emitter")
 ```

## Dynamics

Dynamics can be turned on for objects with the `SKTileObject.setupDynamics()` method.

## GameplayKit

The `SKTileObject.obstacleType` property will flag the object as an `GKObstacle`.