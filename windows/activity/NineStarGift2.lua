local SevenStarGift = import(".SevenStarGift")
local NineStarGift2 = class("NineStarGift2", SevenStarGift)

function NineStarGift2:ctor(parentGO, params, parent)
	SevenStarGift.ctor(self, parentGO, params, parent)
end

return NineStarGift2
