local BaseWindow = import(".BaseWindow")
local FurnitureZoomWindow = class("FurnitureZoomWindow", BaseWindow)

function FurnitureZoomWindow:ctor(name, params)
	FurnitureZoomWindow.super.ctor(self, name, params)

	self.itemId = params.itemId
end

function FurnitureZoomWindow:initWindow()
	FurnitureZoomWindow.super.initWindow(self)

	self.imgNode = self.window_.transform:NodeByName("imgNode").gameObject
	local sources = xyd.tables.houseFurnitureTable:getCollectionImg(self.itemId)
	local type = xyd.tables.houseFurnitureTable:type(self.itemId)
	local scale = xyd.tables.houseFurnitureTable:getImgScale(self.itemId)

	for i = 0, #sources do
		if sources[i] ~= nil then
			local img = NGUITools.AddChild(self.imgNode, "img" .. tostring(i))

			if type ~= xyd.FURNITURE_TYPE.BACKGROUND then
				local sprite = img:AddComponent(typeof(UISprite))

				xyd.setUISpriteAsync(sprite, nil, sources[i], function ()
					sprite:MakePixelPerfect()
				end)
			else
				local texture = img:AddComponent(typeof(UITexture))

				xyd.setUITextureByNameAsync(texture, sources[i], true, function ()
					texture:SetLocalScale(scale, scale, 0)
				end)
			end
		end
	end
end

return FurnitureZoomWindow
