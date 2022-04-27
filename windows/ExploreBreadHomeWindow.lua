local ExploreBreadHomeWindow = class("ExploreBreadHomeWindow", import(".ExploreBaseBuildingWindow"))
local HeroIcon = import("app.components.HeroIcon")
local exploreModel = xyd.models.exploreModel
local buildingMaxLevel = 50
local exploreTable = xyd.tables.exploreBreadHomeTable

function ExploreBreadHomeWindow:ctor(name, params)
	params.buildingType = xyd.exploreBuildings.BREAD_HOME

	ExploreBreadHomeWindow.super.ctor(self, name, params)

	self.exploreTable = exploreTable
end

function ExploreBreadHomeWindow:initWindow()
	ExploreBreadHomeWindow.super.initWindow(self)
end

function ExploreBreadHomeWindow:getUIComponent()
	ExploreBreadHomeWindow.super.getUIComponent(self)
end

function ExploreBreadHomeWindow:layout()
	ExploreBreadHomeWindow.super.layout(self)

	for i = 1, 2 do
		xyd.setUITextureByNameAsync(self["imgBuilding" .. i], "explore_bread_home")
	end

	self.groupLabelMiddle[1][2].text = __("TRAVEL_MAIN_TEXT14")
	self.groupLabelMiddle[1][4].text = __("TRAVEL_MAIN_TEXT17")

	if self.data.level < buildingMaxLevel then
		self.groupLabelMiddle[2][2].text = __("TRAVEL_MAIN_TEXT14")
		self.groupLabelMiddle[2][4].text = __("TRAVEL_MAIN_TEXT17")
	else
		self.groupLabelMiddle[2][2].text = "-- --"
		self.groupLabelMiddle[2][4].text = "-- --"
		self.groupLabelMiddle[2][2].color = Color.New2(2795939583.0)
		self.groupLabelMiddle[2][4].color = Color.New2(2795939583.0)
	end

	self.labelTitle.text = __("TRAVEL_BUILDING_NAME3")
end

function ExploreBreadHomeWindow:updateOutAndStay()
	if self.data.level < buildingMaxLevel then
		for i = 1, 2 do
			local lev = self.data.level + i - 1
			self.groupLabelMiddle[i][1].text = __("TRAVEL_MAIN_TEXT13", lev)
			self.groupLabelMiddle[i][3].text = math.floor(exploreTable:getOutput(lev)[2] * (1 + self.outFactor / 100))
			self.groupLabelMiddle[i][5].text = math.floor(exploreTable:getStayMax(lev) * (1 + self.stayFactor / 100))
		end
	else
		local lev = self.data.level
		self.groupLabelMiddle[1][1].text = __("TRAVEL_MAIN_TEXT13", lev)
		self.groupLabelMiddle[1][3].text = math.floor(exploreTable:getOutput(lev)[2] * (1 + self.outFactor / 100))
		self.groupLabelMiddle[1][5].text = math.floor(exploreTable:getStayMax(lev) * (1 + self.stayFactor / 100))
		self.groupLabelMiddle[2][1].text = __("TRAVEL_MAIN_TEXT44")
		self.groupLabelMiddle[2][3].text = "--"
		self.groupLabelMiddle[2][5].text = "--"
		self.groupLabelMiddle[2][1].color = Color.New2(2795939583.0)
		self.groupLabelMiddle[2][3].color = Color.New2(2795939583.0)
		self.groupLabelMiddle[2][5].color = Color.New2(2795939583.0)
	end
end

function ExploreBreadHomeWindow:registerEvent()
	ExploreBreadHomeWindow.super.registerEvent(self)

	local slotLimit = exploreModel:getBuildingSlotLimit()

	for i = 1, 4 do
		local limLev = slotLimit[i][1]
		local item = self.groupHero[i]

		UIEventListener.Get(item.lockImg).onClick = function ()
			xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

			if self.chooseGroup.activeSelf then
				self.chooseGroup:SetActive(false)
				self:setBuildingPartner()

				self.slotIndex = nil
			end

			if not xyd.GuideController.get():isPlayGuide() then
				xyd.showToast(__("TRAVEL_MAIN_TEXT40", limLev))
			end
		end
	end
end

return ExploreBreadHomeWindow
