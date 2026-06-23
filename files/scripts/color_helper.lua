---@alias material_colors {r:number, g:number, b:number, a:number}

---@class colors
local colors = {}

---Splits a packed 32-bit color into its four bytes, least-significant first.
---Which byte maps to R/G/B/A is the caller's concern (see abgr_to_rgb).
---@param packed integer
---@return number byte0 least significant byte
---@return number byte1
---@return number byte2
---@return number byte3 most significant byte
function colors.abgr_split(packed)
	local byte0 = bit.band(packed, 0xFF)
	local byte1 = bit.band(bit.rshift(packed, 8), 0xFF)
	local byte2 = bit.band(bit.rshift(packed, 16), 0xFF)
	local byte3 = bit.band(bit.rshift(packed, 24), 0xFF)

	return byte0, byte1, byte2, byte3
end

---Packs four bytes (least-significant first) back into a 32-bit integer.
---@param byte0 number least significant byte
---@param byte1 number
---@param byte2 number
---@param byte3 number most significant byte
---@return integer color
function colors.abgr_merge(byte0, byte1, byte2, byte3)
	return bit.bor(
		bit.band(byte0, 0xFF),
		bit.lshift(bit.band(byte1, 0xFF), 8),
		bit.lshift(bit.band(byte2, 0xFF), 16),
		bit.lshift(bit.band(byte3, 0xFF), 24)
	)
end

---Converts a packed ARGB hex string (AARRGGBB) to normalized rgba components.
---As a hex string the byte order low-to-high is B, G, R, A.
---@param color string
---@return material_colors
function colors.abgr_to_rgb(color)
	local blue, green, red, alpha = colors.abgr_split(tonumber(color, 16))
	return { r = red / 255, g = green / 255, b = blue / 255, a = alpha / 255 }
end

---Multiplies two packed colors component-wise (per byte), normalized to 0..255.
---@param color1 integer
---@param color2 integer
---@return integer
function colors.multiply(color1, color2)
	local s0, s1, s2, s3 = colors.abgr_split(color1)
	local d0, d1, d2, d3 = colors.abgr_split(color2)
	return colors.abgr_merge(s0 * d0 / 255, s1 * d1 / 255, s2 * d2 / 255, s3 * d3 / 255)
end

return colors
