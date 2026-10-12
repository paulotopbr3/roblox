-- Pure operations used by the authoritative server and offline tests.
local E = {}
function E.rarity(weights, luck, roll)
	local sum = 0
	for i, w in ipairs(weights) do
		sum += w * (i >= 3 and luck or 1)
	end
	local cursor = 0
	for i, w in ipairs(weights) do
		cursor += w * (i >= 3 and luck or 1)
		if roll * sum < cursor then
			return i
		end
	end
	return #weights
end
function E.hatchPlan(cost, coins, credits, count, petCount, limit)
	if count ~= 1 and count ~= 3 then
		return nil, "Count"
	end
	if petCount + count > limit then
		return nil, "Capacity"
	end
	local used = math.min(count, credits)
	local price = cost * (count - used)
	if coins < price then
		return nil, "Coins"
	end
	return { Cost = price, Credits = used }
end
function E.receipt(d, receiptKey, product, now, petFactory, maxNumber)
	if d.Receipts[receiptKey] then
		return true, false
	end
	if product.Kind == "Gems" then
		d.Gems = math.min(maxNumber, d.Gems + product.Amount)
	elseif product.Kind == "Coins" or product.Kind == "Luck" then
		d.Boosts[product.Kind] = math.max(now, d.Boosts[product.Kind] or 0) + product.Amount
	elseif product.Kind == "Eggs" then
		d.EggCredits += product.Amount
	elseif product.Kind == "Pet" then
		petFactory(d, product.Pet)
	else
		return false, false
	end
	d.Receipts[receiptKey] = now
	return true, true
end
return E
