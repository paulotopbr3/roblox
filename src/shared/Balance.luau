local B = {}
function B.rebirthCost(count)
	return math.min(1e150, math.floor(25000 * 1.65 ^ math.min(count, 670)))
end
function B.rebirthMultiplier(count)
	return 1 + count * 0.5
end
function B.petSlots(data)
	return 3 + (data.Passes.ExtraPetSlots and 3 or 0) + (data.Upgrades and data.Upgrades.Slots or 0)
end
function B.level(crystals)
	return 1 + math.floor(math.sqrt(crystals / 8))
end
function B.compact(n)
	local units = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No" }
	if n < 1000 then
		return tostring(math.floor(n))
	end
	local tier = math.floor(math.log10(n) / 3)
	if tier >= #units then
		return string.format("%.2e", n)
	end
	return string.format("%.1f%s", n / 1000 ^ tier, units[tier + 1])
end
return B
