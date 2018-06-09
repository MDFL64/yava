AddCSLuaFile()

yava.changes = [[
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