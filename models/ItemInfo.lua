local ItemInfo = class("ItemInfo")

function ItemInfo:ctor(info)
	self.item_id = tonumber(info.item_id)
	self.item_num = tonumber(info.item_num)
end

return ItemInfo
