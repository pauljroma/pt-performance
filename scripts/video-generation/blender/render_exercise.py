"""
Blender Python script for rendering exercise demonstration videos.
Uses Mixamo character + animation with white studio background.

Usage:
    blender --background --python render_exercise.py -- --input animation.fbx --output bench-press-3d.mp4

Prerequisites:
    1. Download character from Mixamo (https://www.mixamo.com/)
    2. Install Blender (https://www.blender.org/download/)
    3. Run this script with Blender's Python

Example Mixamo search terms:
    - "bench press" (may not exist, use "weight lifting" variants)
    - "squat"
    - "deadlift"
    - "push up"
    - "lunge"
"""

import bpy
import sys
import os
import math
import argparse


def parse_args():
    """Parse command line arguments after '--'"""
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []

    parser = argparse.ArgumentParser(description="Render exercise video in Blender")
    parser.add_argument("--input", "-i", required=True, help="Input FBX file from Mixamo")
    parser.add_argument("--output", "-o", default="exercise.mp4", help="Output video file")
    parser.add_argument("--resolution", default="1080", help="Video resolution (default: 1080)")
    parser.add_argument("--fps", type=int, default=30, help="Frames per second (default: 30)")
    parser.add_argument("--duration", type=int, default=10, help="Duration in seconds (default: 10)")
    parser.add_argument("--loops", type=int, default=3, help="Number of animation loops (default: 3)")

    return parser.parse_args(argv)


def setup_scene():
    """Clear scene and set up studio lighting"""
    # Clear existing objects
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()

    # Set background to white
    world = bpy.data.worlds.get("World")
    if world is None:
        world = bpy.data.worlds.new("World")
    bpy.context.scene.world = world

    world.use_nodes = True
    bg_node = world.node_tree.nodes.get("Background")
    if bg_node:
        bg_node.inputs['Color'].default_value = (1, 1, 1, 1)  # White
        bg_node.inputs['Strength'].default_value = 1.0


def setup_lighting():
    """Create three-point studio lighting"""
    # Key light (main)
    bpy.ops.object.light_add(type='AREA', location=(3, -3, 4))
    key_light = bpy.context.object
    key_light.name = "Key Light"
    key_light.data.energy = 500
    key_light.data.size = 3
    key_light.rotation_euler = (math.radians(45), 0, math.radians(45))

    # Fill light (softer, opposite side)
    bpy.ops.object.light_add(type='AREA', location=(-3, -2, 3))
    fill_light = bpy.context.object
    fill_light.name = "Fill Light"
    fill_light.data.energy = 200
    fill_light.data.size = 4
    fill_light.rotation_euler = (math.radians(45), 0, math.radians(-45))

    # Rim light (behind, for separation)
    bpy.ops.object.light_add(type='AREA', location=(0, 3, 3))
    rim_light = bpy.context.object
    rim_light.name = "Rim Light"
    rim_light.data.energy = 300
    rim_light.data.size = 2
    rim_light.rotation_euler = (math.radians(-45), 0, 0)


def setup_camera():
    """Set up camera for side-angle view"""
    bpy.ops.object.camera_add(location=(4, -4, 2))
    camera = bpy.context.object
    camera.name = "ExerciseCamera"

    # Point camera at origin (where character will be)
    camera.rotation_euler = (math.radians(75), 0, math.radians(45))

    # Set as active camera
    bpy.context.scene.camera = camera

    return camera


def import_mixamo_fbx(filepath):
    """Import Mixamo FBX file with animation"""
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"FBX file not found: {filepath}")

    # Import FBX
    bpy.ops.import_scene.fbx(
        filepath=filepath,
        use_anim=True,
        ignore_leaf_bones=True,
        automatic_bone_orientation=True
    )

    # Find imported armature
    armature = None
    for obj in bpy.context.selected_objects:
        if obj.type == 'ARMATURE':
            armature = obj
            break

    if armature is None:
        raise ValueError("No armature found in FBX file")

    # Center and scale character
    armature.location = (0, 0, 0)
    armature.scale = (0.01, 0.01, 0.01)  # Mixamo exports are usually 100x too big

    return armature


def setup_animation(armature, duration_seconds, fps, loops):
    """Configure animation timeline"""
    # Get animation data
    if armature.animation_data and armature.animation_data.action:
        action = armature.animation_data.action
        original_length = action.frame_range[1] - action.frame_range[0]

        # Calculate total frames needed
        total_frames = duration_seconds * fps

        # Set scene frame range
        bpy.context.scene.frame_start = 1
        bpy.context.scene.frame_end = int(total_frames)

        # Loop animation by adjusting action
        # This creates seamless loops
        if loops > 1:
            # Use NLA for looping
            if not armature.animation_data.nla_tracks:
                track = armature.animation_data.nla_tracks.new()
                track.name = "ExerciseLoop"
            else:
                track = armature.animation_data.nla_tracks[0]

            # Add strips for each loop
            for i in range(loops):
                start_frame = int(i * original_length) + 1
                strip = track.strips.new(f"Loop{i+1}", start_frame, action)
                strip.repeat = 1


def setup_render_settings(resolution, fps, output_path):
    """Configure render output settings"""
    scene = bpy.context.scene

    # Resolution
    res = int(resolution)
    scene.render.resolution_x = res
    scene.render.resolution_y = res
    scene.render.resolution_percentage = 100

    # Frame rate
    scene.render.fps = fps

    # Output format
    scene.render.image_settings.file_format = 'FFMPEG'
    scene.render.ffmpeg.format = 'MPEG4'
    scene.render.ffmpeg.codec = 'H264'
    scene.render.ffmpeg.constant_rate_factor = 'HIGH'
    scene.render.ffmpeg.audio_codec = 'NONE'

    # Output path
    scene.render.filepath = output_path

    # Quality settings (balance speed vs quality)
    scene.render.engine = 'BLENDER_EEVEE'
    scene.eevee.taa_render_samples = 32


def add_ground_plane():
    """Add a simple ground plane for shadows"""
    bpy.ops.mesh.primitive_plane_add(size=10, location=(0, 0, 0))
    plane = bpy.context.object
    plane.name = "Ground"

    # Create white material
    mat = bpy.data.materials.new(name="GroundMaterial")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs['Base Color'].default_value = (0.95, 0.95, 0.95, 1)
        bsdf.inputs['Roughness'].default_value = 0.8

    plane.data.materials.append(mat)


def render_animation():
    """Render the animation to video"""
    print("Starting render...")
    bpy.ops.render.render(animation=True)
    print("Render complete!")


def main():
    args = parse_args()

    print(f"=== PT Performance Exercise Video Renderer ===")
    print(f"Input: {args.input}")
    print(f"Output: {args.output}")
    print(f"Resolution: {args.resolution}x{args.resolution}")
    print(f"FPS: {args.fps}")
    print(f"Duration: {args.duration}s ({args.loops} loops)")
    print()

    # Setup scene
    print("Setting up scene...")
    setup_scene()
    setup_lighting()
    camera = setup_camera()
    add_ground_plane()

    # Import character
    print(f"Importing Mixamo FBX: {args.input}")
    armature = import_mixamo_fbx(args.input)

    # Setup animation
    print("Configuring animation...")
    setup_animation(armature, args.duration, args.fps, args.loops)

    # Configure render
    print("Configuring render settings...")
    setup_render_settings(args.resolution, args.fps, args.output)

    # Render
    render_animation()

    print(f"\nVideo saved to: {args.output}")


if __name__ == "__main__":
    main()
