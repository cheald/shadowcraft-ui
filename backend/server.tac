# You can run this .tac file directly with:
#    twistd -ny service.tac
import os

from twisted.application import service, internet
from twisted.web import static, server
from server import *

def getWebService():
    site = WebSocketSite(ShadowcraftSite())
    site.addHandler("/engine", ShadowcraftSocket)
    return internet.TCPServer(8880, site)

application = service.Application("Shadowcraft Backend")

service = getWebService()
service.setServiceParent(application)