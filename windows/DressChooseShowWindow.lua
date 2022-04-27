local DressChooseShowWindow = class("DressChooseShowWindow", import(".BaseWindow"))
local ShowItem = class("ShowItem", import("app.components.CopyComponent"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")

function DressChooseShowWindow:ctor(name, params)
	DressChooseShowWindow.super.ctor(self, name, params)

	self.item_id = params.item_id
	self.is_common = params.is_common
	self.choice_yet_infos = {}

	if params.choice_yet_infos then
		for i in pairs(params.choice_yet_infos) do
			table.insert(self.choice_yet_infos, params.choice_yet_infos[i])
		end
	end

	self.all_num = params.all_num
end

return DressChooseShowWindow
