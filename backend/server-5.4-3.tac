# You can run this .tac file directly with:
#    twistd -ny service.tac

# I hate that we have to have a separate tac per server, but apparently 'tacs are config'
# http://twistedmatrix.com/pipermail/twisted-python/2006-June/013331.html

import os, sys, __builtin__
__builtin__.shadowcraft_engine_version = 5.4
sys.path.append("vendor/engine-5.4")

from twisted.application import service, internet
from twisted.web import static, server
from app.server import *

def getWebService(port = 8881):
    site = WebSocketSite(ShadowcraftSite())
    site.addHandler("/engine", ShadowcraftSocket)
    return internet.TCPServer(port, site)

application = service.Application("Shadowcraft Backend")

service = getWebService(8883)
service.setServiceParent(application)
