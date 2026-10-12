local Marketplace = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local C = require(game.ReplicatedStorage.UniverseMiner.Config)
local Economy = require(game.ReplicatedStorage.UniverseMiner.Economy)
local Data = require(script.Parent.Data)
local Game = require(script.Parent.Game)
local Commerce = {}
local products = {}
local passIds = {}
for key, product in pairs(C.Products) do
	if product.Id > 0 then
		assert(not products[product.Id], "Developer Product ID duplicado")
		products[product.Id] = product
	end
end
for key, id in pairs(C.Passes) do
	if id > 0 then
		assert(not passIds[id], "Gamepass ID duplicado")
		passIds[id] = key
	end
end
function Commerce.refresh(player)
	local s = Data.Sessions[player]
	if not s then
		return
	end
	for key, id in pairs(C.Passes) do
		if id > 0 then
			local ok, owned = pcall(function()
				return Marketplace:UserOwnsGamePassAsync(player.UserId, id)
			end)
			if ok and Data.Sessions[player] == s then
				s.Data.Passes[key] = owned
			else
				warn("Gamepass não verificado:", key)
			end
		end
	end
	if Data.Sessions[player] ~= s or s.Closing then
		return
	end
	if s.Data.Passes.ExclusivePets and not s.Data.ExclusiveGranted then
		Game.pet(s.Data, "vip")
		s.Data.ExclusiveGranted = true
	end
	Game.snapshot(player)
end
function Commerce.prompt(player, arg)
	if type(arg) ~= "table" or type(arg.Key) ~= "string" then
		return
	end
	if arg.Type == "Pass" then
		local id = C.Passes[arg.Key]
		if id and id > 0 then
			Marketplace:PromptGamePassPurchase(player, id)
		else
			Game.notice(player, "Gamepass ainda não configurado.")
		end
	elseif arg.Type == "Product" then
		local p = C.Products[arg.Key]
		if p and p.Id > 0 then
			Marketplace:PromptProductPurchase(player, p.Id)
		else
			Game.notice(player, "Produto ainda não configurado.")
		end
	end
end
function Commerce.init()
	Marketplace.PromptGamePassPurchaseFinished:Connect(function(player, _, purchased)
		if purchased then
			task.spawn(Commerce.refresh, player)
		end
	end)
	Marketplace.ProcessReceipt = function(receipt)
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		local s = player and Data.Sessions[player]
		if not s or not Data.writable(player) or s.Temporary then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local product = products[receipt.ProductId]
		if not product then
			warn("Recibo de produto sem configuração:", receipt.ProductId)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local d = s.Data
		local receiptKey = tostring(receipt.PurchaseId)
		-- Grant without yielding; record in the SAME durable profile. Retry always saves
		-- before acknowledgement, including an earlier in-memory grant whose save failed.
		local valid = Economy.receipt(d, receiptKey, product, os.time(), Game.pet, C.MaxNumber)
		if not valid then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if not Data.save(player, false) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		Game.snapshot(player)
		Game.notice(player, "Compra entregue e salva!")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end
return Commerce
