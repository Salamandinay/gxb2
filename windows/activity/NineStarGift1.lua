local SevenStarGift = import(".SevenStarGift")
local NineStarGift1 = class("NineStarGift1", SevenStarGift)

function NineStarGift1:ctor(parentGO, params, parent)
	SevenStarGift.ctor(self, parentGO, params, parent)
end

return NineStarGift1
