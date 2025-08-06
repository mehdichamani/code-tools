netsh interface portproxy add v4tov4 listenport=3057 listenaddress=0.0.0.0 connectport=3057 connectaddress=127.0.0.1
@pause
netsh interface portproxy delete v4tov4 listenport=3057 listenaddress=0.0.0.0
@pause