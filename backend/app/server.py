import sys
import json
import __builtin__
import hotshot
import uuid

from collections import defaultdict
from math import floor
from twisted.application import service, internet
from twisted.internet import threads
from twisted.web import server, resource
from twisted.internet import reactor
from twisted.python import log
from time import clock
from vendor.WebSocket import *
from shadowcraft import ShadowcraftComputation

engine = ShadowcraftComputation()
reactor.suggestThreadPoolSize(16)

class ShadowcraftSite(resource.Resource):
    isLeaf = True
    allowedMethods = ('POST','OPTIONS', 'GET')

    def render_OPTIONS(self, request):
        request.setHeader("Access-Control-Allow-Origin", "*")
        request.setHeader("Access-Control-Max-Age", "3600")
        request.setHeader("Access-Control-Allow-Headers", "x-requested-with, content-type")
        return ""

    def render_POST(self, request):
        request.setHeader("Access-Control-Allow-Origin", "*")
        try:
            input = json.loads(request.content.getvalue())
        except ValueError:
            return '{"error": "Invalid input"}'
        else:
            start = clock()
            log.msg("Request: %s" % input)
            try
                response = engine.get_all(input)
            except (KeyError) as e:
                response = {'error': "%s: %s" % (e.__class__, e.message)}
            log.msg("Request time: %s sec" % (clock() - start))
            log.msg("Response: %s" % response)
            return json.dumps(response)

    # Because IE is terrible.
    def render_GET(self, request):
        return self.render_POST(request)

    def gzip_response(self, request, content):
        encoding = request.getHeader("accept-encoding")
        if encoding and encoding.find("gzip")>=0:
            import cStringIO,gzip
            zbuf = cStringIO.StringIO()
            zfile = gzip.GzipFile(None, 'wb', 7, zbuf)
            zfile.write(content)
            zfile.close()
            request.setHeader("Content-encoding","gzip")
            return zbuf.getvalue()
        else:
            return content

class ShadowcraftSocket(WebSocketHandler):
    def frameReceived(self, frame):
        input = json.loads(frame)
        if input["type"] == "m":
            # prof = hotshot.Profile("stones.prof")
            # prof.runcall(engine.get_dps, input["data"])
            # prof.close()
            # stats = hotshot.stats.load("stones.prof")
            # stats.sort_stats('time', 'calls')
            # stats.print_stats(50)

            start = clock()
            response = engine.get_all(input["data"])
            response["calc_time"] = clock() - start
            self.transport.write(json.dumps({'type': 'response', 'data': response}))

if __name__ == "__main__":
    site = WebSocketSite(ShadowcraftSite())
    site.addHandler("/engine", ShadowcraftSocket)
    reactor.listenTCP(8880, site)
    reactor.run()
