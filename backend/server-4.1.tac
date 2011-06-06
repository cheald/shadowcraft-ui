# You can run this .tac file directly with:
#    twistd -ny service.tac

import os, sys, __builtin__
__builtin__.shadowcraft_engine_version = 4.1
sys.path.append("vendor/engine")

from twisted.application import service, internet
from twisted.web import static, server
from app.server import *

def getWebService(port = 8880):
    site = WebSocketSite(ShadowcraftSite())
    site.addHandler("/engine", ShadowcraftSocket)
    return internet.TCPServer(port, site)

application = service.Application("Shadowcraft Backend")

service = getWebService()
service.setServiceParent(application)