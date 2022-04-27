local BaseWindow = import(".BaseWindow")
local PartnerLabelSelectWindow = class("PartnerLabelSelectWindow", BaseWindow)
local PartnerDirectionLabelComponent = class("PartnerDirectionLabelComponent", import("app.components.BaseComponent"))
local PartnerLabelTable = xyd.tables.partnerLabelTable
local PartnerLabelTypeTable = xyd.tables.partnerLabelTypeTable
local PartnerDataStation = xyd.models.partnerDataStation

function PartnerDirectionLabelComponent:ctor(parentGo, params)
	PartnerDirectionLabelComponent.super.ctor(self, parentGo)

	self.id = params.id
	self.noClick = params.no_click
	self.ifChoose = false
	self.ifSelfLabel = params.if_self_label
	self.callback = params.callback

	self:setDragScrollView(params.scrollView)
	self:layout()
	self:registerEvent()
end

function PartnerDirectionLabelComponent:getPrefabPath()
	return "Prefabs/Components/partner_direction_label_component"
end

function PartnerDirectionLabelComponent:initUI()
	PartnerDirectionLabelComponent.super.initUI(self)

	local go = self.go
	self.imgBg = go:ComponentByName("imgBg", typeof(UISprite))
	self.labelTag = go:ComponentByName("labelTag", typeof(UILabel))
	self.imgSelect = go:ComponentByName("imgSelect", typeof(UISprite))
end

function PartnerDirectionLabelComponent:layout()
	local tables = PartnerLabelTable
	local src = PartnerLabelTypeTable:getLabelIcon(tables:getLabelType(self.id))
	local text = tables:getLabelText(self.id)

	if not text then
		return
	end

	print(self.id)

	if not self.ifSelfLabel and PartnerDataStation:checkIfEnough(self.id) then
		text = text .. "(" .. PartnerDataStation:getLabelNum(self.id) .. ")"
	end

	xyd.setUISpriteAsync(self.imgBg, nil, src)

	self.labelTag.text = text

	xyd.setUISpriteAsync(self.imgSelect, nil, "select")

	self.labelTag.effectColor = Color.New2(PartnerLabelTypeTable:getLabelTextColor(tables:getLabelType(self.id)))
	local width = self.labelTag:GetComponent(typeof(UIWidget)).width

	self.imgSelect:SetLocalPosition((width + 60) / 2 - 12, self.imgSelect.transform.localPosition.y, 0)

	self.imgBg:GetComponent(typeof(UIWidget)).width = width + 60
	self.go:GetComponent(typeof(UIWidget)).width = width + 60
end

function PartnerDirectionLabelComponent:registerEvent()
	if not self.noClick then
		UIEventListener.Get(self.go).onClick = function ()
			if self.callback then
				local result = self.callback(not self.ifChoose, self.id)

				if result then
					self.ifChoose = not self.ifChoose

					self.imgSelect:SetActive(self.ifChoose)
				end
			end
		end
	end
end

function PartnerLabelSelectWindow:ctor(name, params)
	PartnerLabelSelectWindow.super.ctor(self, name, params)

	self.labelsGroup = {}
	self.chooseIndices = {}
	self.table_id_ = params.table_id
end

function PartnerLabelSelectWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponents()
	self:layout()
	self:registerEvent()
end

function PartnerLabelSelectWindow:getUIComponents()
	local go = self.window_
	self.labelTitle = go:ComponentByName("labeTitle", typeof(UILabel))
	self.btnHelp = go:NodeByName("btnHelp").gameObject
	self.closeBtn = go:NodeByName("closeBtn").gameObject
	self.btnSure = go:NodeByName("btnSure").gameObject
	self.btnSureLabel = self.btnSure:ComponentByName("btnSureLabel", typeof(UILabel))
	self.scroller = go:ComponentByName("scroller", typeof(UIScrollView))
	self.groupContent = go:NodeByName("scroller/groupContent").gameObject
end

function PartnerLabelSelectWindow:layout()
	self:initLabels()

	self.labelTitle.text = __("LABEL_CUSTOMIZE_TITLE")
	self.btnSureLabel.text = __("SURE")
end

function PartnerLabelSelectWindow:initLabels()
	local ids = PartnerLabelTable:getIds()

	for _, id in ipairs(ids) do
		local comp = PartnerDirectionLabelComponent.new(self.groupContent, {
			id = id,
			callback = function (ifChoose, id)
				if ifChoose then
					if #self.chooseIndices >= 3 then
						xyd.showToast(__("LABEL_CUSTOMIZE_TIPS"))

						return false
					end

					table.insert(self.chooseIndices, id)
				else
					local index = xyd.arrayIndexOf(self.chooseIndices, id)
					self.chooseIndices = xyd.splice(self.chooseIndices, index, 1)
				end

				return true
			end,
			scrollView = self.scroller
		})
	end
end

function PartnerLabelSelectWindow:registerEvent()
	PartnerLabelSelectWindow.super.register(self)

	UIEventListener.Get(self.btnSure).onClick = function ()
		PartnerDataStation:reqLabel({
			table_id = self.table_id_,
			tags = self.chooseIndices
		})
		xyd.WindowManager.get():closeWindow("partner_label_select_window")
	end

	UIEventListener.Get(self.btnHelp).onClick = function ()
		xyd.WindowManager.get():openWindow("partner_data_station_help_window", {
			key = "PARTNER_LABEL_SELECT_WINDOW_HELP",
			title = __("SETTING_UP_HELP")
		})
	end
end

return PartnerLabelSelectWindow
