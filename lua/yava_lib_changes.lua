AddCSLuaFile()

yava.changes = [[
A2: 
    [Testbed]
    - New block types.
    - Bulk voxel gun.
    - Explosions destroy terrain.
    [API]
    - Bulk modification functions.
    - Image directory config setting.
    [Internal]
    - Faster chunk networking. Chunk data is sent as quickly as possible over an unreliable channel.
    - Faster mesh generation. Generator will now spend about 5ms on mesh generation each frame.


A1: June 4, 2018
    [Initial Release]
]]