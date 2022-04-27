local BaseWindow = import(".BaseWindow")
local PetDataWindow = class("PetDataWindow", BaseWindow)

function PetDataWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.petId = params.petId
end

function PetDataWindow:initWindow()
	BaseWindow.initWindow()
	self:getUIComponent()
	self:registerEvent()
	self:layout()
end

function PetDataWindow:getUIComponent()
	local winTrans = self.window_.transform
	local groupAction = winTrans:NodeByName("groupAction").gameObject
	self.closeBtn = groupAction:NodeByName("closeBtn").gameObject
	self.groupItems = groupAction:ComponentByName("scroller/groupItems", typeof(UITable))

	for i = 0, 3 do
		self["labelTitle" .. i] = self.groupItems:ComponentByName("groupContent" .. i .. "/labelTitle" .. i, typeof(UILabel))
		self["labelText" .. i] = self.groupItems:ComponentByName("groupContent" .. i .. "/labelText" .. i, typeof(UILabel))
	end
end

function PetDataWindow:registerEvent()
	self:register()
end

function PetDataWindow:layout()
	if not self.petId then
		return
	end

	local storyDatas = xyd.models.petSlot:getStoryData(self.petId)
	local pet = xyd.models.petSlot:getPetByID(self.petId)
	local top_grade = pet:getTopGrade()

	table.sort(storyDatas, function (a, b)
		return a.id < b.id
	end)

	for i = 1, 4 do
		local data = storyDatas[i]
		local labelTitle = self["labelTitle" .. i - 1]
		local labelText = self["labelText" .. i - 1]

		if data.unLockValue <= top_grade then
			labelTitle.text = data.title
			labelText.text = data.text

			xyd.setLabel(labelText, {
				color = 1549556991,
				size = 20,
				textAlign = NGUIText.Alignment.Left
			})
		else
			labelText.text = __("PET_STORY_UNLOCK", data.unLockValue)
			labelTitle.text = data.title

			xyd.setLabel(labelText, {
				color = 2998055679.0,
				size = 24,
				textAlign = NGUIText.Alignment.Center
			})
		end
	end

	XYDCo.WaitForFrame(1, function ()
		if not tolua.isnull(self.window_) then
			self.groupItems:Reposition()
		end
	end, nil)
end

return PetDataWindow
