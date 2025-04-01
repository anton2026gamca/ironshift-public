extends Node


var windows: Array[UIWindow] = []
var selected_window: UIWindow


func register_window(window: UIWindow):
	if window not in windows:
		windows.append(window)

func unregister_window(window: UIWindow):
	if window in windows:
		windows.erase(window)

func move_to_front(window: UIWindow):
	if window in windows:
		var max_z = 0
		for win in windows:
			max_z = max(max_z, win.z_index)
			win.z_index -= 1
			win.deselect()
		window.z_index = max_z
		window.select()
		selected_window = window

func move_to_back(window: UIWindow):
	if window in windows:
		window.deselect()
		var max_z_window: UIWindow
		var min_z: int = 10000000
		for win in windows:
			if win == window:
				continue
			if not max_z_window or win.z_index > max_z_window.z_index:
				max_z_window = win
			win.deselect()
			min_z = min(win.z_index, min_z)
			win.z_index += 1
		if min_z != 10000000:
			window.z_index = min_z
		if not max_z_window:
			max_z_window = window
		max_z_window.select()
		selected_window = max_z_window
