import os
from PIL import Image, ImageOps

# Load the PNG logo
logo_path = 'logo.png'
logo = Image.open(logo_path).convert("RGBA")

# Separate alpha before inverting
r, g, b, a = logo.split()
rgb_image = Image.merge("RGB", (r, g, b))
inverted_rgb = ImageOps.invert(rgb_image)
inverted_logo = Image.merge("RGBA", (*inverted_rgb.split(), a))

# Output directory
output_dir = 'images'
os.makedirs(output_dir, exist_ok=True)

# Setup
num_frames = 30
angle_step = 360 / num_frames
canvas_size = (128, 128)

# Optional: scale logo down a bit to fit rotations within 64x64
inverted_logo.thumbnail((48, 48), Image.Resampling.LANCZOS)

for i in range(num_frames):
    angle = i * angle_step
    rotated = inverted_logo.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)

    # Create a transparent 64x64 canvas
    frame = Image.new("RGBA", canvas_size, (255, 255, 255, 0))

    # Center rotated image
    x = (canvas_size[0] - rotated.width) // 2
    y = (canvas_size[1] - rotated.height) // 2
    frame.paste(rotated, (x, y), rotated)

    # Save frame
    frame_number = i + 1
    frame_path = os.path.join(output_dir, f"throbber-{frame_number:04d}.png")
    frame.save(frame_path)

print(f"Saved {num_frames} inverted + rotated frames in '{output_dir}'")

