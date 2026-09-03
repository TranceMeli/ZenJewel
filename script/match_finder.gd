# match_finder.gd
class_name MatchFinder
extends RefCounted


static func find_matches(grid: Array, rows: int, cols: int, special_none) -> Dictionary:
	var matched: Dictionary = {}
	var h_runs: Array = []
	var v_runs: Array = []

	# Horizontal
	for row in range(rows):
		var run = []
		for col in range(cols):
			var j = grid[row][col]
			if j != null and j.special == special_none:
				if run.is_empty():
					run.append(j)
				elif run.back().type == j.type:
					run.append(j)
				else:
					if run.size() >= 3:
						h_runs.append(run.duplicate())
					run = [j]
			else:
				if run.size() >= 3:
					h_runs.append(run.duplicate())
				run = []
		if run.size() >= 3:
			h_runs.append(run.duplicate())

	# Vertikal
	for col in range(cols):
		var run = []
		for row in range(rows):
			var j = grid[row][col]
			if j != null and j.special == special_none:
				if run.is_empty():
					run.append(j)
				elif run.back().type == j.type:
					run.append(j)
				else:
					if run.size() >= 3:
						v_runs.append(run.duplicate())
					run = [j]
			else:
				if run.size() >= 3:
					v_runs.append(run.duplicate())
				run = []
		if run.size() >= 3:
			v_runs.append(run.duplicate())

	# Alle Matches sammeln
	for run in h_runs:
		for j in run:
			matched["%d,%d" % [j.row, j.col]] = true
	for run in v_runs:
		for j in run:
			matched["%d,%d" % [j.row, j.col]] = true


	var specials: Array = []

	for run in h_runs:
		if run.size() >= 4:
			var mid = run[run.size() / 2]
			specials.append({
				"row": mid.row, "col": mid.col,
				"count": run.size(), "horizontal": true
			})
			matched.erase("%d,%d" % [mid.row, mid.col])

	for run in v_runs:
		if run.size() >= 4:
			var mid = run[run.size() / 2]
			specials.append({
				"row": mid.row, "col": mid.col,
				"count": run.size(), "horizontal": false
			})
			matched.erase("%d,%d" % [mid.row, mid.col])

	return {
		"matched": matched.keys(),
		"specials": specials
	}
