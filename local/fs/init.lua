-- init.lua --

stemiID = 'STEMI-' .. node.chipid()
stemiData = {stemiID = stemiID, version = '1.0', isValid = true}
stemiJsonFormat = '{\n  "stemiID": "%s",\n  "version": "1.0",\n  "isValid": true\n}'
stemiJsonDefault = string.format(stemiJsonFormat, stemiID)


if file.open('stemiData.json', 'r') then
  parsedJson = cjson.decode(file.read())
  if parsedJson.stemiID then
    stemiData = parsedJson
  end
  file.close()
else
  file.open('stemiData.json', 'w')
  ok, json = pcall(cjson.encode, stemiData)
  if ok then
    file.write(json)
  else
    file.write(stemiJsonDefault)
  end
  file.close()
end

-- Setup serial (if default is not 115200)
uart.setup( 0, 115200, 8, 0, 1, 0 )

-- Configure Access Point
apcfg = { ssid = stemiData.stemiID
        , pwd  = '12345678'
        }

-- Configure Wireless Internet
-- wifi.sta.config('<ESSID>', '<PASSWORD>')
wifi.ap.config(apcfg)

wifi.setmode(wifi.SOFTAP)
-- wifi.setmode(wifi.STATION)

file.open('linearization.bin', 'r')
local linearization = file.read(22)
-- print(linearization:byte(1,-1))
file.close()

-- send saved linearization
if(linearization ~= nil) then
  uart.write(0, linearization)
  uart.write(0, linearization)
  uart.write(0, linearization)
end

-- Run the main file
-- print('Run main.lua')
dofile('main.lua')
