-- main.lua --

http200 = 'HTTP/1.1 200 OK\r\n'
       .. 'Cache-control: max-age=120\r\n'
       .. 'Access-Control-Allow-Origin: *\r\n'
       .. 'Connection:close\r\n\r\n'

http200noCache = 'HTTP/1.1 200 OK\r\n'
       .. 'Cache-Control: no-cache, no-store, must-revalidate\r\n'
       .. 'Pragma: no-cache\r\n'
       .. 'Expires: 0\r\n'
       .. 'Access-Control-Allow-Origin: *\r\n'
       .. 'Connection:close\r\n\r\n'

http404 = function (f)
  return 'HTTP/1.1 404 Not Found\r\nConnection:close\r\n\r\n'
         .. '<html><body><h2>404</h2>\r\n<p>File <b>"'
         .. f ..
         '"</b> not found :(</p></body></html>'
end


-- Start a simple http server
srv=net.createServer(net.TCP)
srv:listen(80, function(conn)
  local DataToGet = -1
  local chunkSize = 1024
  local filename  = ''

  conn:on('receive',function(conn,payload)
    if (payload:find('^[PL][KI][TN]') ~= nil) then
      uart.write(0, payload)
      -- print(payload:byte(1,-1))

      if(payload:find('^LIN') ~= nil and payload:byte(22) == 1) then
        file.open('linearization.bin', 'w+')
        file.write(payload:sub(1,22))
        file.close()
        -- print('\nLIN PACKET WRITTEN TO FLASH\n')
      end

    elseif (payload:find('^GET') ~= nil) then
      -- print(payload)
      local url = payload:match('%S%s(%S*)')

      if url:find('^/send') then
        conn:send(http200noCache)

        local packetB64 = url:match('%S*raw=(%S*)')
        -- print('Received packet via GET /send?raw=' .. packetB64)
        -- print(decB64(packetB64):byte(1,-1))
        uart.write(0, encoder.fromBase64(packetB64))

      elseif url:find('^/connect') then
        local s,p = url:match('/connect%?ssid=(%S*)&password=(%S*)')
        local ssid = encoder.fromBase64(s)
        local pass = encoder.fromBase64(p)

        conn:close()

        wifi.setmode(wifi.STATION)
        wifi.sta.config(ssid, pass)

      elseif url:find('^/restart') then
        node.restart()

      elseif url:find('^/disconnect') then
        wifi.setmode(wifi.SOFTAP)

      else
        --send file
        if url == '/' then
          filename = 'index.html'
        else
          filename = string.sub(url, 2, -1)
        end

        if file.open(filename, 'r') then
          conn:send(http200)
          -- print(filename)

          DataToGet = 0
          return
        else
          conn:send(http404(filename))
        end

      end
    end
  end)

  conn:on('sent', function(conn)
    if DataToGet >= 0 then
      local chunk = ''

      file.open(filename, 'r')
      file.seek('set', DataToGet)
      chunk=file.read(chunkSize)
      file.close()

      if chunk then
        conn:send(chunk)
        DataToGet = DataToGet + chunkSize
      end

      if chunk and (string.len(chunk) == chunkSize) then
        return
      end
    end

    DataToGet = -1
    filename  = ''

    conn:close()
  end)

end)
