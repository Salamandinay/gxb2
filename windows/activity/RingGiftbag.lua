local ActivityContent = import(".ActivityContent")
local RingGiftbag = class("RingGiftbag", ActivityContent)

function RingGiftbag:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)

	self.skinName = "RingGiftbagSkin"
	self.giftbag_id_ = self.activityData.detail.charges[1].table_id
	self.currentState = xyd.Global.lang

	self:getUIComponent()
	self:initUIComponent()
	self:euiComplete()
end

function RingGiftbag:getPrefabPath()
	return "Prefabs/Windows/activity/ringGiftBag"
end

function RingGiftbag:getUIComponent()
	local go = self.go
	self.imgBg = go:ComponentByName("imgBg", typeof(UITexture))
	self.e_Group = go:NodeByName("e:Group").gameObject
	self.e_Image = self.e_Group:ComponentByName("e:Image", typeof(UITexture))
	self.textImg = self.e_Group:ComponentByName("textImg", typeof(UISprite))
	self.purchaseBtn = self.e_Group:NodeByName("purchaseBtn").gameObject
	self.button_label = self.purchaseBtn:ComponentByName("button_label", typeof(UILabel))
	self.itemGroup = self.e_Group:NodeByName("itemGroup").gameObject
	self.imageExplain = self.e_Group:ComponentByName("imageExplain", typeof(UITexture))
	self.itemIcon_ = self.e_Group:ComponentByName("itemIcon_", typeof(UITexture))
end

function RingGiftbag:initUIComponent()
	local res_prefix = "Textures/activity_web/ring_giftbag/"

	xyd.setUISpriteAsync(self.textImg, nil, "ring_giftbag_text01_" .. xyd.Global.lang, nil, , true)
	xyd.setUITextureAsync(self.e_Image, res_prefix .. "ring_giftbag_bg01")
	xyd.setUITextureAsync(self.imageExplain, res_prefix .. "ring_giftbag_text02")
	xyd.setUITextureAsync(self.itemIcon_, res_prefix .. "ring_giftbag_icon01")
end

function RingGiftbag:euiComplete()
	local giftbag_id = self.giftbag_id_
	local purchaseBtn = self.purchaseBtn
	self.button_label.text = tostring(xyd.tables.giftBagTextTable:getCurrency(giftbag_id)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(giftbag_id))

	xyd.setDarkenBtnBehavior(self.purchaseBtn, self, function ()
		xyd.SdkManager.get():showPayment(self.giftbag_id_)
	end)

	UIEventListener.Get(self.itemIcon_.gameObject).onClick = handler(self, function ()
		local params = {
			itemID = 45,
			itemNum = 1
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end)
end

function RingGiftbag:shader()
	local vertexSrc = "attribute vec2 aVertexPosition;\n" .. "attribute vec2 aTextureCoord;\n" .. "attribute vec2 aColor;\n" .. "uniform vec2 projectionVector;\n" .. "varying vec2 vTextureCoord;\n" .. "const vec2 center = vec2(-1.0, 1.0);\n" .. "void main(void) {\n" .. "   gl_Position = vec4( (aVertexPosition / projectionVector) + center , 0.0, 1.0);\n" .. "   vTextureCoord = aTextureCoord;\n" .. "}"
	local fragmentSrc = "precision mediump float;" .. "uniform vec2 blur;" .. "uniform sampler2D uSampler;" .. "varying vec2 vTextureCoord;" .. "uniform vec2 uTextureSize;\n" .. "void main()" .. "{" .. "    const float sampleRadius = 10.0;" .. "    const vec2 diff = vec2(1.0, 1.0);" .. "    vec2 blurUv = blur / uTextureSize;" .. "    vec4 color = vec4(0, 0, 0, 0);" .. "    vec2 uv = vec2(0.0, 0.0);" .. "    blurUv /= float(sampleRadius);" .. "    float total = 0.0;" .. "    for (float i = -sampleRadius; i <= sampleRadius; i++) {" .. "        float target = float(i);" .. "        if(i < 0.0)" .. "            target = - float(i);" .. "        total += 2.0;" .. "        uv.x = vTextureCoord.x + float(i) * blurUv.x;" .. "        color += texture2D(uSampler, uv);" .. "        uv.x = vTextureCoord.x;" .. "        uv.y = vTextureCoord.y + float(i) * blurUv.y;" .. "        color += texture2D(uSampler, uv);" .. "    }" .. "       color /= total;" .. "    gl_FragColor = color;" .. "    if(vTextureCoord.x > 0.9 && vTextureCoord.y > 0.9) {" .. "        gl_FragColor = vec4(1, 0, 0, 1);" .. "    }" .. "}"
	local filter = egret.CustomFilter.new(vertexSrc, fragmentSrc, {
		blur = 1
	})
	self.imgBg.filters = {
		filter
	}
end

function RingGiftbag:setIcon()
	local itemGroup = self.itemGroup
	local awards = xyd.giftTablegetAwards(xyd.giftBagTable:getGiftID(self.giftbag_id_))
	local i = 0
	local length = awards.length

	while i < length do
		local data = awards[i]

		if data[0] ~= xyd.ItemID.VIP_EXP then
			local item = {
				ItemID = data[0],
				num = data[1]
			}
			local icon = xyd:getItemIcon(item)
			icon.scaleX = 97 / icon.width
			icon.scaleY = 97 / icon.height

			itemGroup:addChild(icon)
		end

		i = i + 1
	end
end

function RingGiftbag:updateStatus()
	if self.activityData.detail.charges[0].buy_times <= self.limit_cnt_ then
		local purchaseBtn = self.purchaseBtn

		xyd:applyGrey(purchaseBtn)

		purchaseBtn.touchEnabled = false
	end
end

function RingGiftbag:returnCommonScreen()
	ActivityContent.returnCommonScreen(self)

	local ____TS_obj = self.textImg
	local ____TS_index = "y"
	____TS_obj[____TS_index] = ____TS_obj[____TS_index] - 122
end

return RingGiftbag
