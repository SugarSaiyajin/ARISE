extends RefCounted

static func normalized(stock: Dictionary, order: Array) -> Dictionary:
	var result := stock.duplicate()
	for id in order:
		result[id] = int(stock.get(id, 0))
	return result

static func valid(stock: Variant, order: Array, required: Array = [], limit: int = 100000000) -> bool:
	if not stock is Dictionary:
		return false
	for id in stock:
		if id not in order:
			return false
	for id in required:
		if not stock.has(id):
			return false
	for value in stock.values():
		if not (value is int or value is float) or not is_finite(float(value)) or value < 0 or value > limit or value != int(value):
			return false
	return true
