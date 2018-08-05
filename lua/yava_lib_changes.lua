AddCSLuaFile()

yava.changes = [[
A5: ???
    [Testbed]
    - Increased resolution of some of the testbed textures.
    - Fixed a bug that caused the advanced voxel gun to fire too rapidly.
    - The map is now auto-saved every 10 minutes, and upon server closing.
    [Enhancements]
    - Map cleanup now ignores voxel chunks.
    - Entity lighting should now match the voxel world's lighting.
    - Default voxel world now fills the entire yava_void map.
    - The yava_void map now uses a painted sky and sun.
    - Face texture resolution increased to 32x32 pixels.
    - The yava_void map's height now matches its other dimensions.
    - The world can now be reset/regenerated.
    - Simplified chunk networking.
    - Made some attempts at Lua autorefresh support.
    [API]
    - Added yava.save(filename), which can be used to save the current map.
        The map will be saved as `data/yava/[config.saveDir]/[filename].yava.dat`.
        This save format is fairly basic and takes up a lot of space, but is guaranteed
        to work with future yava versions and even across different yava configurations to *some extent*.
        If no `config.saveDir` is provided, the map will be saved in `data/yava`, but this is not recommended.
    - The yava.init() function can now be used to load a map when provided with the `loadFile` config option.
        This should be set to the filename of the map to load, sans directories or extensions.
        This will override the generator when it is set.
    - Calling yava.init() after it has been called once on the *server* will reset/regenerate the world.
    - Calling yava.init() with no arguments will reuse the most recent config.
    - The most recent config can be accessed by yava.currentConfig.

A4: July 1, 2018
    [Testbed]
    - Fixed advanced gun attempting to set voxels clientside.
    - Switched default block type to rock.
    - Moved voxel guns into the last category, with the toolgun.
    - Changed map generator, map now has more flat space.
    [Internal]
    - Dramatically improved network compression.
    - Lowered fixed atlas size to 4096. All but a fraction of a percent of GPUs should now be supported.
    - Stopped chunk builder from explicitly writing the default block type.
    - The server will now mesh up to 1000 chunks per frame. This should prevent the player falling out of the map.

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