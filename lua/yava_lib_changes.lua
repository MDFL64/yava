AddCSLuaFile()

yava.changes = [[
A3: June 10, 2018
    [Testbed]
    - Diagnostic commands for textures.
    - Voxel guns are now spawnable.
    - Bulk voxel gun is admin-restricted.
    - Added automatic workshop dl.
    - Added advanced voxel gun.
    [Internal]
    - Added clientside physics meshes.
    - Removed unneeded crap from physics meshing.
    - Dialed back chunk collider's clientside think rate.
    - Reduced atlas size for older GPU support.
    - Added warning if GPU does not support hardcoded atlas size.
    - Attempted to speed up bulk updates by flagging dirty chunks after editing block data.

A2: June 9, 2018
    [Testbed]
    - New block types.
    - Removed 'void' as selectable block type.
    - Bulk voxel gun.
    [API]
    - Bulk modification functions.
    - Image directory config setting.
    [Internal]
    - Faster chunk networking. Chunk data is sent as quickly as possible over an unreliable channel.
    - Faster mesh generation. Generator will now spend about 5ms on mesh generation each frame.
    - Modified atlas generation should produce less artifacts on the top/bottom edges of some textures.

A1: June 4, 2018
    [Initial Release]
]]