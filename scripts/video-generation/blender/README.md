# 3D Exercise Video Generation with Blender + Mixamo

Generate professional 3D exercise demonstration videos using free tools.

## Prerequisites

1. **Blender** (free): https://www.blender.org/download/
2. **Adobe Account** (free): Required for Mixamo
3. **Mixamo** (free): https://www.mixamo.com/

## Workflow

### Step 1: Get Character from Mixamo

1. Go to https://www.mixamo.com/
2. Sign in with Adobe ID
3. Click "Characters" tab
4. Choose a character (recommended: "Y Bot" or "X Bot" for clean look)
5. Download as FBX (no animation needed yet)

### Step 2: Get Animation from Mixamo

1. Stay on Mixamo
2. Click "Animations" tab
3. Search for exercise (e.g., "weight lifting", "squat", "lunge")
4. Preview animations until you find a good match
5. Adjust parameters:
   - **Overdrive**: 0
   - **Character Arm-Space**: As needed
   - **Trim**: Adjust start/end for clean loop
6. Download as FBX with:
   - Format: FBX Binary
   - Skin: With Skin
   - Frames per Second: 30
   - Keyframe Reduction: None

### Step 3: Render Video

```bash
# Basic usage
blender --background --python render_exercise.py -- \
  --input squat-animation.fbx \
  --output squat-3d.mp4

# With all options
blender --background --python render_exercise.py -- \
  --input bench-press.fbx \
  --output bench-press-3d.mp4 \
  --resolution 1080 \
  --fps 30 \
  --duration 10 \
  --loops 3
```

### Step 4: Upload to PT Performance

```bash
cd ..
./upload-video.sh ../blender/bench-press-3d.mp4 "Barbell Bench Press"
```

## Finding Exercise Animations

Mixamo may not have exact exercise names. Try these search terms:

| Exercise | Mixamo Search |
|----------|---------------|
| Bench Press | "weight lifting", "chest fly" |
| Squat | "squat" |
| Deadlift | "lifting", "picking up" |
| Lunge | "lunge" |
| Push-up | "push up" |
| Pull-up | "pull up", "hanging" |
| Shoulder Press | "overhead press", "weight lifting" |
| Row | "rowing", "pulling" |

## Customization

### Camera Angles

Edit `render_exercise.py` to change camera position:

```python
# Side view (default)
camera.location = (4, -4, 2)

# Front view
camera.location = (0, -5, 2)

# 3/4 view
camera.location = (3, -4, 2)
```

### Lighting

The script uses three-point lighting:
- **Key Light**: Main light from front-right
- **Fill Light**: Softer light from front-left
- **Rim Light**: Behind subject for separation

Adjust in `setup_lighting()` function.

### Background Color

Change in `setup_scene()`:
```python
bg_node.inputs['Color'].default_value = (1, 1, 1, 1)  # White
# or
bg_node.inputs['Color'].default_value = (0.1, 0.1, 0.1, 1)  # Dark
```

## Batch Rendering

Create a shell script for multiple exercises:

```bash
#!/bin/bash
EXERCISES=("squat" "lunge" "deadlift")

for ex in "${EXERCISES[@]}"; do
    blender --background --python render_exercise.py -- \
        --input "animations/${ex}.fbx" \
        --output "output/${ex}-3d.mp4"
done
```

## Troubleshooting

### "No armature found"
- Ensure FBX export includes "With Skin" option
- Check Mixamo download settings

### Animation too fast/slow
- Adjust `--fps` parameter
- Re-export from Mixamo with different FPS

### Character too big/small
- Adjust scale in `import_mixamo_fbx()`:
  ```python
  armature.scale = (0.01, 0.01, 0.01)  # Adjust as needed
  ```

### Render is black
- Check lighting positions
- Increase light energy values
- Ensure camera is pointing at character

## Cost

**$0** - Both Blender and Mixamo are free to use.

## Time Estimate

- First setup: 2-4 hours (learning curve)
- Per exercise after setup: 15-30 minutes
- Render time: ~1-2 minutes per 10s video

## Quality Tips

1. Choose animations with clean loops
2. Trim animations in Mixamo for seamless looping
3. Use "Overdrive: 0" for realistic speed
4. Export at 30fps for smooth playback
5. Consider multiple camera angles for key exercises
