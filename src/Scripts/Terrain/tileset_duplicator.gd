extends Node
class_name TilesetDuplicator


var tileset: TileSet = preload("res://Tilesets/tiles.tres")

'''
func _ready() -> void:
	var num_threads: int = OS.get_processor_count()
	var num_tilesets: int = 100
	print("Duplicating ", num_tilesets, " tilesets with ", num_threads, " threads")
	var start_time = Time.get_ticks_msec()  # Start timing
	var duplicated_tilesets: Array = duplicate_tileset(tileset, num_tilesets, num_threads)
	var end_time = Time.get_ticks_msec()
	print("Finished duplicating tilesets (", (float(end_time) - float(start_time)) / 1000, " s)")
	# [num tilesets]	 - [num threads]	 = [tim in seconds]
	# 100			 - 1				 = 51.737 s
	# 100			 - 2				 = 34.792 s
	# 100			 - 4				 = 29.034 s
	# 100			 - 8				 = 25.97  s
	# 100			 - 16			 = 24.347 s
	# 100			 - 32			 = 28.217 s
'''

func duplicate_tileset(tileset: TileSet, num_duplicates: int, num_threads: int = 4) -> Array:
	var threads = []
	var mutex = Mutex.new()
	var results = []
	results.resize(num_duplicates)
	
	for i in range(num_threads):
		var thread = Thread.new()
		threads.append(thread)
		thread.start(duplicate_task.bind(i, tileset, num_duplicates, num_threads, results, mutex))
	
	for thread in threads:
		thread.wait_to_finish()
	
	return results

func duplicate_task(thread_id: int, tileset: TileSet, num_duplicates: int, num_threads: int, results: Array, mutex: Mutex):
	var chunk_size = ceil(float(num_duplicates) / num_threads)
	var start_index = thread_id * chunk_size
	var end_index = min(start_index + chunk_size, num_duplicates)
	
	for i in range(start_index, end_index):
		var new_tileset = tileset.duplicate(true)
		if new_tileset == null:
			print("Error: Duplicate failed at index ", i)
		mutex.lock()
		results[i] = new_tileset
		mutex.unlock()
