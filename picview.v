// filepath: src/grok.v
module picview

import gg
import os
import time

enum ViewMode {
	fit     // 自动适配窗口
	manual  // 手动缩放/拖拽
}

struct App {
mut:
	gg              &gg.Context = unsafe { nil }
	img             gg.Image
	img_x           f32
	img_y           f32
	scale           f32 = 1.0
	view_mode       ViewMode = .fit
	is_dragging     bool
	last_mouse_x    f32
	last_mouse_y    f32
	min_scale       f32 = 0.1
	max_scale       f32 = 8.0
	img_paths       []string
	img_index       int
	slide_mode      bool
	last_slide_time i64
	slide_interval  int = 2
	show_help       bool
	need_initial_fit bool
}

fn (mut app App) fit_to_window() {
	win := app.gg.window_size()
	if app.img.width <= 0 || app.img.height <= 0 {
		return
	}

	win_width := f32(win.width)
	win_height := f32(win.height)
	img_width := f32(app.img.width)
	img_height := f32(app.img.height)
	scale_x := win_width / img_width
	scale_y := win_height / img_height
	app.scale = if scale_x < scale_y { scale_x * 0.9 } else { scale_y * 0.9 }
	app.center_image()
}

fn (mut app App) center_image() {
	win := app.gg.window_size()
	win_width := f32(win.width)
	win_height := f32(win.height)
	img_width := f32(app.img.width)
	img_height := f32(app.img.height)

	app.img_x = (win_width - img_width * app.scale) / 2
	app.img_y = (win_height - img_height * app.scale) / 2
}

fn (mut app App) clamp_scale(scale f32) f32 {
	return if scale < app.min_scale {
		app.min_scale
	} else if scale > app.max_scale {
		app.max_scale
	} else {
		scale
	}
}

fn (mut app App) apply_zoom(factor f32) {
	if app.img.width <= 0 || app.img.height <= 0 {
		return
	}

	// Decide zoom center before switching off fit mode
	win := app.gg.window_size()
	center_x := if app.view_mode == .fit {
		f32(win.width) * 0.5
	} else {
		app.img_x + f32(app.img.width) * app.scale * 0.5
	}
	center_y := if app.view_mode == .fit {
		f32(win.height) * 0.5
	} else {
		app.img_y + f32(app.img.height) * app.scale * 0.5
	}

	app.view_mode = .manual
	new_scale := app.clamp_scale(app.scale * factor)
	app.scale = new_scale
	new_w := f32(app.img.width) * app.scale
	new_h := f32(app.img.height) * app.scale
	app.img_x = center_x - new_w * 0.5
	app.img_y = center_y - new_h * 0.5
}

fn (mut app App) pan_image(dx f32, dy f32) {
	app.view_mode = .manual
	app.img_x += dx
	app.img_y += dy
}

fn usage() {
	println('picview [OPTIONS] [DIR]')
	println('  DIR      directory containing images (default: current directory)')
	println('  -h, --help        print this help and exit')
}

fn is_image_file(path string) bool {
	ext := os.file_ext(path).to_lower()
	return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].any(ext == it)
}

pub fn run() {
	mut app := &App{}
	args := os.args
	mut base_dir := ''
	for i, a in args {
		if i == 0 {
			continue
		}
		match a {
			'-h', '--help' {
				usage()
				return
			}
			else {
				if base_dir == '' {
					base_dir = a
				}
			}
		}
	}

	if base_dir == '' {
		base_dir = os.getenv('PIC_DIR')
		if base_dir.len == 0 {
			base_dir = '.'
		}
	}

	fs := os.ls(base_dir) or { panic('Failed to list files in ${base_dir}') }
	mut files := fs.filter(fn (f string) bool {
		return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].any(f.to_lower().ends_with(it))
	}).map(os.join_path(base_dir, it))
	files.sort()

	if files.len == 0 {
		panic('No supported images found in ${base_dir}')
	}
	app.img_paths = files
	app.img_index = 0

	app.gg = gg.new_context(
		bg_color:     gg.white
		width:        800
		height:       600
		window_title: 'Image Preview'
		frame_fn:     frame
		event_fn:     on_event
		scroll_fn:    on_scroll
		user_data:    app
		resizable:    true
	)

	if !app.select_first_loadable_image() {
		panic('No loadable images found in ${base_dir}')
	}
	app.view_mode = .fit
	app.need_initial_fit = true
	app.gg.run()
}

fn (mut app App) load_img(path string) bool {
	app.img = app.gg.create_image(path) or {
		eprintln('Skipping unreadable image ${path}: ${err}')
		return false
	}
	return true
}

fn (mut app App) load_img_at(index int) bool {
	if index < 0 || index >= app.img_paths.len {
		return false
	}
	if app.load_img(app.img_paths[index]) {
		app.img_index = index
		return true
	}
	return false
}

fn (mut app App) select_first_loadable_image() bool {
	for i in 0 .. app.img_paths.len {
		if app.load_img_at(i) {
			app.view_mode = .fit
			return true
		}
	}
	return false
}

fn (mut app App) load_relative_image(step int) {
	if app.img_paths.len == 0 {
		return
	}

	mut next_index := app.img_index
	for _ in 0 .. app.img_paths.len {
		next_index = (next_index + step + app.img_paths.len) % app.img_paths.len
		if app.load_img_at(next_index) {
			app.view_mode = .fit
			app.fit_to_window()
			return
		}
	}

	eprintln('No loadable image found.')
}

fn on_event(e &gg.Event, mut app App) {
	match e.typ {
		.resized {
			if app.view_mode == .fit {
				app.fit_to_window()
			} else {
				app.center_image()
			}
		}
		.key_down {
			match e.key_code {
				.escape {
					app.gg.quit()
				}
				.r {
					app.view_mode = .fit
					app.fit_to_window()
				}
				.equal {
					app.apply_zoom(1.1)
				}
				.minus {
					app.apply_zoom(1 / 1.1)
				}
				._0 {
					app.view_mode = .fit
					app.fit_to_window()
				}
				._1 {
					app.view_mode = .manual
					app.scale = 1.0
					app.center_image()
				}
				.f {
					gg.toggle_fullscreen()
				}
				.s {
					app.slide_mode = !app.slide_mode
					app.last_slide_time = time.now().unix()
				}
				.left_bracket {
					if app.slide_interval > 1 {
						app.slide_interval -= 1
					}
				}
				.right_bracket {
					if app.slide_interval < 3600 {
						app.slide_interval += 1
					}
				}
				.right, .d {
					app.load_relative_image(1)
				}
				.left, .a {
					app.load_relative_image(-1)
				}
				.up {
					app.pan_image(0, -10)
				}
				.down {
					app.pan_image(0, 10)
				}
				.h {
					app.show_help = !app.show_help
				}
				else {
				}
			}
		}
		.mouse_down {
			if e.mouse_button == .left {
				app.is_dragging = true
				app.last_mouse_x = e.mouse_x
				app.last_mouse_y = e.mouse_y
			}
		}
		.mouse_up {
			if e.mouse_button == .left {
				app.is_dragging = false
			}
		}
		.mouse_move {
			if app.is_dragging {
				dx := e.mouse_x - app.last_mouse_x
				dy := e.mouse_y - app.last_mouse_y
				app.pan_image(dx, dy)
				app.last_mouse_x = e.mouse_x
				app.last_mouse_y = e.mouse_y
			}
		}
		else {}
	}
}

fn (mut app App) status_text() string {
	view_mode_str := match app.view_mode {
		.fit { 'fit' }
		.manual { 'manual' }
	}
	is_fullscreen := gg.is_fullscreen()
	name := os.file_name(app.img_paths[app.img_index])
	return '${name}  ${app.img_index + 1}/${app.img_paths.len}  ${app.img.width}x${app.img.height}  zoom:${app.scale:.2f}  mode:${view_mode_str}  fs:${if is_fullscreen { "Y" } else { "N" }}  slide:${if app.slide_mode { "Y" } else { "N" }}(${app.slide_interval}s)'
}

fn on_scroll(event &gg.Event, mut app App) {
	if event.typ != .mouse_scroll {
		return
	}

	if event.scroll_y > 0 {
		app.apply_zoom(1.1)
	} else if event.scroll_y < 0 {
		app.apply_zoom(1 / 1.1)
	}
}

fn frame(mut app App) {
	if app.need_initial_fit {
		win := app.gg.window_size()
		if win.width > 0 && win.height > 0 {
			app.fit_to_window()
			app.need_initial_fit = false
		}
	}

	if app.slide_mode && app.img_paths.len > 1 {
		now := time.now().unix()
		if now - app.last_slide_time >= app.slide_interval {
			app.load_relative_image(1)
			app.last_slide_time = now
		}
	}

	app.gg.begin()

	display_width := f32(app.img.width) * app.scale
	display_height := f32(app.img.height) * app.scale

	app.gg.draw_image_with_config(
		img:      &app.img
		img_rect: gg.Rect{
			x:      app.img_x
			y:      app.img_y
			width:  display_width
			height: display_height
		}
		color:    gg.white
	)

	app.gg.draw_text(10, 10, app.status_text(), gg.TextCfg{
		color: gg.black
		size:  16
	})

	if app.show_help {
		app.gg.draw_text(10, 34, '[H] help  [←/→] prev/next  [+/-/wheel] zoom  [0] fit  [1] 100%  [R] refit  [S] slide  [[]/]] interval  [F] fullscreen  [Esc] quit  [drag] move', gg.TextCfg{
			color: gg.rgb(40, 40, 40)
			size:  14
		})
	}

	app.gg.end()
}
