# picview

A lightweight image viewer built with V and gg, supporting multiple formats, zoom, slideshow, and keyboard shortcuts.

## Running

```fish
# Pass the image directory as the first argument
v run . images

# Or pass a single image file to browse its directory, starting at that file
v run . images/sample.jpeg

# Show help
v run . -h

# Or run in the current directory
v run .

# Include subdirectories
v run . -r images

# Optional fallback for compatibility
env PIC_DIR="images" v run .
```

## Supported Formats

- .jpg, .jpeg, .png, .gif, .bmp, .webp

## Keyboard Shortcuts

### Navigation

- `Left` / `A` - Previous image
- `Right` / `D` - Next image
- `Up` / `Down` - Pan view

### Zoom & Fit

- `+` / `=` - Zoom in
- `-` / `_` - Zoom out
- `0` - Fit to window
- `1` - 100% size
- `R` - Refit to window
- `Drag` - Move image with mouse

### Slideshow

- `S` - Toggle slideshow
- `[` / `]` - Decrease/increase slideshow interval (seconds)

### Display

- `F` - Toggle fullscreen (shows status)
- `H` - Show/hide help bar
- `Esc` - Exit

## Notes

- Images are sorted naturally by filename (e.g., img2.jpg before img10.jpg)
- Neighboring images are decoded in a background thread; recently viewed images are kept in a small GPU texture cache
- The image cannot be dragged fully out of the window; press `R` or `0` to refit anyway
- Shows: filename, resolution, index, zoom scale, fullscreen & slideshow status
- The first command-line argument points to the image directory; the bundled samples live in `images/`
- Mouse wheel also zooms the image, matching the `+` / `-` shortcuts
