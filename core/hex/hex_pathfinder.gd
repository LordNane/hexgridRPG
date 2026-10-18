class_name HexPathfinder
## Shortest paths on a hex grid.
##
## Movement rules are passed in as a step-cost function, so overworld, location and battle
## movement all share this code:
## [codeblock]
## func step_cost(from: Vector2i, to: Vector2i) -> float  # INF = can't enter
## [/codeblock]
## Ties between equally cheap routes are broken the same way every time, so results are deterministic.


## The cheapest path from [param start] to [param goal], both ends included, or an empty array
## if the goal can't be reached. [param min_step_cost] must be the cheapest any single step can
## cost: it guides the A* search toward the goal while keeping the result optimal.
static func find_path(start: Vector2i, goal: Vector2i, step_cost: Callable, min_step_cost := 1.0) -> Array[Vector2i]:
	var frontier := PriorityQueue.new()
	frontier.push(start, 0.0)
	var came_from: Dictionary[Vector2i, Vector2i] = {start: start}
	var cost_so_far: Dictionary[Vector2i, float] = {start: 0.0}
	var expanded: Dictionary[Vector2i, bool] = {}
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop()
		if current == goal:
			return trace_path(came_from, goal)
		if expanded.has(current):
			continue
		expanded[current] = true
		for next: Vector2i in Hex.neighbors(current):
			var step: float = step_cost.call(current, next)
			if is_inf(step):
				continue
			var new_cost: float = cost_so_far[current] + step
			if new_cost < cost_so_far.get(next, INF):
				cost_so_far[next] = new_cost
				came_from[next] = current
				frontier.push(next, new_cost + Hex.distance(next, goal) * min_step_cost)
	return []


## Every hex reachable from [param start] for at most [param budget] total cost, with the
## cheapest way to each one (e.g. a unit's movement range).
static func reachable(start: Vector2i, budget: float, step_cost: Callable) -> ReachMap:
	var frontier := PriorityQueue.new()
	frontier.push(start, 0.0)
	var came_from: Dictionary[Vector2i, Vector2i] = {start: start}
	var cost_so_far: Dictionary[Vector2i, float] = {start: 0.0}
	var expanded: Dictionary[Vector2i, bool] = {}
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop()
		if expanded.has(current):
			continue
		expanded[current] = true
		for next: Vector2i in Hex.neighbors(current):
			var step: float = step_cost.call(current, next)
			if is_inf(step):
				continue
			var new_cost: float = cost_so_far[current] + step
			if new_cost <= budget and new_cost < cost_so_far.get(next, INF):
				cost_so_far[next] = new_cost
				came_from[next] = current
				frontier.push(next, new_cost)
	return ReachMap.new(start, cost_so_far, came_from)


## Follows [param came_from] links back from [param goal] to where the search started (the hex
## that links to itself). Returns the path start-first, or an empty array if the goal was never reached.
static func trace_path(came_from: Dictionary[Vector2i, Vector2i], goal: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if not came_from.has(goal):
		return path
	var hex := goal
	while true:
		path.append(hex)
		var previous: Vector2i = came_from[hex]
		if previous == hex:
			break
		hex = previous
	path.reverse()
	return path
